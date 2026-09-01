#Requires -RunAsAdministrator
# devdrive: Legt ein Dev Drive an. Zwei Wege:
#   -ImagePath <vhdx> -SizeGB <n> [-Fixed]   VHDX erzeugen (falls nicht vorhanden), anhaengen, partitionieren
#   -DiskNumber <n> [-SizeGB <n>]            nicht zugeordneten Bereich einer vorhandenen Platte nutzen
# Danach: eine neue Partition, ReFS als Dev Drive, Laufwerksbuchstabe, Trust pruefen.
# Nutzt New-VHD, wenn vorhanden, sonst diskpart; Mount-DiskImage haengt die VHDX an.
# Formatiert nie ein Volume, das bereits ein Dateisystem traegt.
param(
    [string]$ImagePath,
    [int]$DiskNumber = -1,
    [int]$SizeGB,
    [switch]$Fixed,
    [Parameter(Mandatory)][ValidatePattern('^[D-Z]$')][string]$DriveLetter,
    [string]$Label = 'Dev'
)
$ErrorActionPreference = 'Stop'
$windowsRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
$system32 = Join-Path $windowsRoot 'System32'
$env:PATH = @($PSHOME, $system32, $windowsRoot, (Join-Path $system32 'WindowsPowerShell\v1.0')) -join ';'
$env:PSModulePath = @((Join-Path $PSHOME 'Modules'), (Join-Path $system32 'WindowsPowerShell\v1.0\Modules')) -join ';'
$diskpartPath = Join-Path $system32 'diskpart.exe'
$fsutilPath = Join-Path $system32 'fsutil.exe'
$fltmcPath = Join-Path $system32 'fltmc.exe'
foreach ($nativeTool in $diskpartPath, $fsutilPath, $fltmcPath) {
    if (-not (Test-Path -LiteralPath $nativeTool -PathType Leaf)) { throw "Windows-Systemtool fehlt: $nativeTool" }
}

function Get-DevDriveTrustState([string]$QueryText) {
    if ($QueryText -match '(?i)\buntrusted\b|\bnot\b[^\r\n]{0,80}\btrusted\b|\b(?:nicht|kein\w*)\b[^\r\n]{0,80}\bvertrauensw') { return 'Untrusted' }
    if ($QueryText -match '(?i)\btrusted\b|\bvertrauensw') { return 'Trusted' }
    return 'Unknown'
}

function Complete-DevDrive([string]$Letter, [switch]$NewVolume) {
    $queryLines = @(& $fsutilPath devdrv query "$Letter`:" 2>&1)
    $queryText = $queryLines -join "`n"
    if ($LASTEXITCODE -ne 0) {
        throw "Dev-Drive-Abfrage fuer $Letter`: fehlgeschlagen: $queryText"
    }
    $trustState = Get-DevDriveTrustState $queryText
    $remountRequired = $false
    $trustCommandSucceeded = $false
    if ($trustState -eq 'Untrusted') {
        $trustArgs = @('devdrv', 'trust', "$Letter`:")
        if ($NewVolume) { $trustArgs += '/f' }
        $trustOutput = @(& $fsutilPath @trustArgs 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Trust konnte nicht gesetzt werden: $($trustOutput -join ' ')" }
        $trustCommandSucceeded = $true
        $remountRequired = -not $NewVolume
        $queryLines = @(& $fsutilPath devdrv query "$Letter`:" 2>&1)
        $queryText = $queryLines -join "`n"
        if ($LASTEXITCODE -ne 0) { throw "Dev-Drive-Abfrage nach Trust fehlgeschlagen: $queryText" }
        $trustState = Get-DevDriveTrustState $queryText
        if ($NewVolume -and $trustState -eq 'Untrusted') { throw 'Volume ist nach dem erzwungenen Remount weiterhin untrusted.' }
    }
    return [pscustomobject]@{
        QueryLines = $queryLines
        TrustState = $trustState
        TrustCommandSucceeded = $trustCommandSucceeded
        RemountRequired = $remountRequired
    }
}

function Write-TrustStatus($Result) {
    if ($Result.TrustState -eq 'Trusted') { 'Trust: trusted'; return }
    if ($Result.TrustState -eq 'Untrusted' -and $Result.RemountRequired) {
        'Trust: gesetzt; erst nach Remount oder Neustart aktiv'
        return
    }
    if ($Result.TrustCommandSucceeded) {
        'Trust: Befehl erfolgreich; lokalisierte fsutil-Ausgabe nicht maschinell auswertbar'
        return
    }
    'Trust: unbekannt; lokalisierte fsutil-Ausgabe manuell prüfen'
}

function Assert-FixedDisk($Disk, [string]$Context) {
    if ($Disk.BusType -in @('USB', 'SD', 'MMC')) { throw "$Context nutzt den nicht unterstuetzten BusType $($Disk.BusType)." }
    $device = Get-CimInstance Win32_DiskDrive -Filter "Index = $($Disk.Number)" -ErrorAction Stop
    if (-not $device -or -not $device.PNPDeviceID) { throw "$Context konnte nicht sicher als fest eingebaut erkannt werden." }
    if ($device.MediaType -match '(?i)removable' -or @($device.Capabilities) -contains 7) {
        throw "$Context ist als Wechselmedium markiert und wird von Dev Drive nicht unterstuetzt."
    }
    $pnpProperty = Get-PnpDeviceProperty -InstanceId $device.PNPDeviceID -KeyName 'DEVPKEY_Device_RemovalPolicy' -ErrorAction Stop
    if ([int]$pnpProperty.Data -ne 1) {
        throw "$Context ist laut RemovalPolicy hot-plug-faehig und wird von Dev Drive nicht unterstuetzt."
    }
}

$os = Get-CimInstance Win32_OperatingSystem
$currentVersion = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
$build = [int]$os.BuildNumber
$ubr = if ($null -ne $currentVersion.UBR) { [int]$currentVersion.UBR } else { 0 }
if ($build -lt 22621 -or ($build -eq 22621 -and $ubr -lt 2338)) {
    throw "Dev Drive braucht Windows 11 Build 22621.2338 oder neuer; installiert ist $build.$ubr."
}

if ($ImagePath -and $DiskNumber -ge 0) { throw 'Entweder -ImagePath oder -DiskNumber, nicht beides.' }
if (-not $ImagePath -and $DiskNumber -lt 0) { throw '-ImagePath oder -DiskNumber angeben.' }
if ($SizeGB -and $SizeGB -lt 50) { throw 'Dev Drive braucht mindestens 50 GB.' }
$occupiedVolume = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue

if ($ImagePath) {
    if ($ImagePath -match '[\r\n"*?<>|]') { throw '-ImagePath enthaelt ungueltige oder fuer diskpart unsichere Zeichen.' }
    if (-not [IO.Path]::IsPathRooted($ImagePath) -or [IO.Path]::GetPathRoot($ImagePath) -notmatch '^[A-Za-z]:\\$') {
        throw '-ImagePath muss ein absoluter Pfad auf einem lokalen Laufwerk sein.'
    }
    $ImagePath = [IO.Path]::GetFullPath($ImagePath)
    if ([IO.Path]::GetExtension($ImagePath) -ne '.vhdx') { throw '-ImagePath muss auf .vhdx enden.' }
    if ($occupiedVolume -and -not (Test-Path -LiteralPath $ImagePath)) { throw "Laufwerksbuchstabe $DriveLetter ist belegt." }
    if ($occupiedVolume -and (Test-Path -LiteralPath $ImagePath)) {
        $existingImage = Get-DiskImage -ImagePath $ImagePath -ErrorAction Stop
        if (-not $existingImage.Attached) { throw "Laufwerksbuchstabe $DriveLetter ist belegt und die angegebene VHDX ist nicht angehaengt." }
    }
    $hostDriveLetter = [IO.Path]::GetPathRoot($ImagePath).Substring(0, 1)
    $hostPartition = Get-Partition -DriveLetter $hostDriveLetter -ErrorAction Stop
    $hostDisk = Get-Disk -Number $hostPartition.DiskNumber -ErrorAction Stop
    $hostVolume = Get-Volume -DriveLetter $hostDriveLetter -ErrorAction Stop
    Assert-FixedDisk $hostDisk "Host-Laufwerk $hostDriveLetter`:"
    if (-not $SizeGB -and -not (Test-Path -LiteralPath $ImagePath)) { throw '-SizeGB fehlt fuer eine neue VHDX.' }
    if (-not (Test-Path -LiteralPath $ImagePath) -and $hostVolume.SizeRemaining -lt (($SizeGB + 20) * 1GB)) {
        throw "Host-Laufwerk $hostDriveLetter`: braucht fuer $SizeGB GB VHDX mindestens 20 GB zusaetzliche Reserve."
    }
    $dir = Split-Path $ImagePath -Parent
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

    if (Test-Path -LiteralPath $ImagePath) {
        "VHDX vorhanden, wird angehaengt: $ImagePath"
    } else {
        $type = if ($Fixed) { 'fixed' } else { 'expandable' }
        $newVhd = Get-Command New-VHD -ErrorAction SilentlyContinue
        if ($newVhd) {
            $newVhdParams = @{ Path = $ImagePath; SizeBytes = [int64]$SizeGB * 1GB }
            if ($Fixed) { $newVhdParams.Fixed = $true } else { $newVhdParams.Dynamic = $true }
            New-VHD @newVhdParams | Out-Null
        } else {
            if ($ImagePath -notmatch '^[\x20-\x7E]+$') {
                throw 'Ohne Hyper-V-Modul unterstuetzt der diskpart-Fallback nur ASCII-Pfade fuer die VHDX.'
            }
            $script = "create vdisk file=`"$ImagePath`" maximum=$($SizeGB * 1024) type=$type`nexit"
            $tmp = Join-Path ([IO.Path]::GetTempPath()) ('devdrive-diskpart-{0}.txt' -f [guid]::NewGuid().ToString('N'))
            Set-Content -LiteralPath $tmp -Value $script -Encoding ascii
            try {
                $dp = & $diskpartPath /s $tmp 2>&1
                if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $ImagePath)) {
                    throw "diskpart konnte die VHDX nicht anlegen: $($dp -join ' ')"
                }
            } finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
        }
        "VHDX angelegt: $ImagePath ($SizeGB GB, $type)"
    }

    $img = Get-DiskImage -ImagePath $ImagePath
    if (-not $img.Attached) { Mount-DiskImage -ImagePath $ImagePath | Out-Null; $img = Get-DiskImage -ImagePath $ImagePath }
    $disk = $img | Get-Disk
    $DiskNumber = $disk.Number
    "Angehaengt als Disk $DiskNumber"
} else {
    $disk = Get-Disk -Number $DiskNumber
    Assert-FixedDisk $disk "Disk $DiskNumber"
}

$occupiedVolume = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
if ($occupiedVolume) {
    $occupiedPartition = Get-Partition -DriveLetter $DriveLetter -ErrorAction Stop
    if ($occupiedPartition.DiskNumber -ne $DiskNumber) { throw "Laufwerksbuchstabe $DriveLetter ist auf einer anderen Disk belegt." }
    $completion = Complete-DevDrive $DriveLetter
    "Vorhandenes ReFS-Volume geprüft: $DriveLetter`: $($occupiedVolume.FileSystemType) '$($occupiedVolume.FileSystemLabel)'"
    Write-TrustStatus $completion
    $filterLines = @($completion.QueryLines | Where-Object { $_ -match '(?i)filter' })
    if ($filterLines) { "Filterstatus: $(($filterLines -join ' | ').Trim())" }
    "`nFiltertreiber im System (fltmc):"
    & $fltmcPath filters 2>&1 | Select-Object -Skip 2 | ForEach-Object { "  $_" }
    return
}

if (-not $ImagePath) {
    if ($disk.LargestFreeExtent -lt 50GB) {
        throw "Disk $DiskNumber hat weniger als 50 GB zusammenhaengenden freien Bereich."
    }
    if ($SizeGB -and $disk.LargestFreeExtent -lt ($SizeGB * 1GB)) {
        throw "Disk $DiskNumber hat nur $([math]::Floor($disk.LargestFreeExtent / 1GB)) GB zusammenhaengenden freien Bereich."
    }
}

if ($disk.PartitionStyle -eq 'RAW') {
    Initialize-Disk -Number $DiskNumber -PartitionStyle GPT | Out-Null
    "Disk $DiskNumber als GPT initialisiert"
}

$existing = @(Get-Partition -DiskNumber $DiskNumber -ErrorAction SilentlyContinue | Where-Object { $_.Type -ne 'Reserved' })
if ($ImagePath -and $existing.Count -gt 0) {
    throw 'VHDX enthaelt bereits eine Partition. Nichts partitioniert oder formatiert.'
}

$partParams = @{ DiskNumber = $DiskNumber; DriveLetter = $DriveLetter }
if ($ImagePath -or -not $SizeGB) { $partParams.UseMaximumSize = $true } else { $partParams.Size = $SizeGB * 1GB }
$part = New-Partition @partParams
"Partition $($part.PartitionNumber) angelegt ({0:N0} GB)" -f ($part.Size / 1GB)

try {
    Format-Volume -DriveLetter $DriveLetter -DevDrive -NewFileSystemLabel $Label -Confirm:$false | Out-Null
} catch {
    Remove-Partition -InputObject $part -Confirm:$false -ErrorAction SilentlyContinue
    throw
}
$v = Get-Volume -DriveLetter $DriveLetter
"Formatiert: $DriveLetter`: $($v.FileSystemType) '$($v.FileSystemLabel)' {0:N0} GB frei" -f ($v.SizeRemaining / 1GB)

$completion = Complete-DevDrive $DriveLetter -NewVolume
Write-TrustStatus $completion
$filterLines = @($completion.QueryLines | Where-Object { $_ -match '(?i)filter' })
if ($filterLines) { "Filterstatus: $(($filterLines -join ' | ').Trim())" }

"`nFiltertreiber im System (fltmc):"
& $fltmcPath filters 2>&1 | Select-Object -Skip 2 | ForEach-Object { "  $_" }
