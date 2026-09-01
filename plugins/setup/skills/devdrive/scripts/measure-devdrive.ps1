# devdrive: Read-only-Inventur fuer die Dev-Drive-Einrichtung.
# Gibt einen Textbericht auf stdout aus; aendert nichts am System.
# Braucht keine Adminrechte; was ohne Admin nicht lesbar ist, wird als solches gemeldet.
param(
    [string]$RepoRootsFile
)
$ErrorActionPreference = 'Continue'
$fsutilPath = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)) 'System32\fsutil.exe'

$RepoRoots = @()
if ($RepoRootsFile) {
    $repoRootsPath = (Resolve-Path -LiteralPath $RepoRootsFile -ErrorAction Stop).Path
    $parsedRepoRoots = Get-Content -LiteralPath $repoRootsPath -Raw | ConvertFrom-Json -ErrorAction Stop
    foreach ($repoRoot in @($parsedRepoRoots)) {
        if ($repoRoot -isnot [string] -or -not $repoRoot) { throw 'RepoRootsFile muss ein JSON-Array aus nicht leeren Pfaden enthalten.' }
        $RepoRoots += $repoRoot
    }
}

function Section($t) { "`n=== $t ===" }

function Get-DevDriveTrustState([string]$QueryText) {
    if ($QueryText -match '(?i)\buntrusted\b|\bnot\b[^\r\n]{0,80}\btrusted\b|\b(?:nicht|kein\w*)\b[^\r\n]{0,80}\bvertrauensw') { return 'untrusted' }
    if ($QueryText -match '(?i)\btrusted\b|\bvertrauensw') { return 'trusted' }
    return 'unbekannt (lokalisierte fsutil-Ausgabe)'
}

function Get-ConfiguredPath([string]$Name, [string]$Fallback) {
    $value = [Environment]::GetEnvironmentVariable($Name, 'User')
    if (-not $value) { $value = [Environment]::GetEnvironmentVariable($Name, 'Process') }
    if (-not $value) { $value = $Fallback }
    if ($value) { return [Environment]::ExpandEnvironmentVariables($value) }
    return $null
}

function Get-DiskSupportStatus($Disk) {
    if ($Disk.BusType -in @('USB', 'SD', 'MMC')) { return 'nicht unterstuetzt: Wechselmedium' }
    try {
        $device = Get-CimInstance Win32_DiskDrive -Filter "Index = $($Disk.Number)" -ErrorAction Stop
        if (-not $device -or -not $device.PNPDeviceID) { return 'unklar: kein PnP-Geraet' }
        if ($device.MediaType -match '(?i)removable' -or @($device.Capabilities) -contains 7) { return 'nicht unterstuetzt: Wechselmedium' }
        $pnpProperty = Get-PnpDeviceProperty -InstanceId $device.PNPDeviceID -KeyName 'DEVPKEY_Device_RemovalPolicy' -ErrorAction Stop
        if ([int]$pnpProperty.Data -ne 1) { return 'nicht unterstuetzt: hot-plug-faehig' }
        return 'unterstuetzt: fest eingebaut'
    } catch {
        return "unklar: RemovalPolicy nicht lesbar ($($_.Exception.Message))"
    }
}

function Get-DirSizeMB([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $bytes = (Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
    return [math]::Round(($bytes / 1MB), 0)
}

function Format-Candidate([string]$Name, [string]$Path) {
    $size = Get-DirSizeMB $Path
    if ($null -eq $size) { return "{0}: {1} (fehlt)" -f $Name, $Path }
    return "{0}: {1} ({2} MB)" -f $Name, $Path, $size
}

Section 'System'
$os = Get-CimInstance Win32_OperatingSystem
$currentVersion = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
$build = [int]$os.BuildNumber
$ubr = if ($null -ne $currentVersion.UBR) { [int]$currentVersion.UBR } else { 0 }
"Windows: $($os.Caption) Build $build.$ubr"
$devDriveCapable = $build -gt 22621 -or ($build -eq 22621 -and $ubr -ge 2338)
"Dev Drive faehig (Build >= 22621.2338): $devDriveCapable"
if (Test-Path -LiteralPath $fsutilPath -PathType Leaf) {
    $policy = @(& $fsutilPath devdrv query 2>&1)
    "Dev-Drive-Systemstatus: $(($policy -join ' | ').Trim())"
}
"PowerShell: $($PSVersionTable.PSVersion)"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
"Laeuft elevated: $isAdmin"
$hyperv = Get-Command Mount-VHD -ErrorAction SilentlyContinue
"Hyper-V-PowerShell-Modul: $(if ($hyperv) { 'vorhanden' } else { 'fehlt (Mount-DiskImage/diskpart werden verwendet)' })"

Section 'Datentraeger'
Get-Disk | Sort-Object Number | ForEach-Object {
    "Disk {0}: {1} | {2:N0} GB | {3} | {4} | {5} | groesster nicht zugeordneter Bereich {6:N0} GB | {7}" -f $_.Number, $_.FriendlyName, ($_.Size / 1GB), $_.PartitionStyle, $_.BusType, $_.OperationalStatus, ($_.LargestFreeExtent / 1GB), (Get-DiskSupportStatus $_)
}

Section 'Volumes'
Get-Volume | Where-Object { $_.DriveLetter } | Sort-Object DriveLetter | ForEach-Object {
    "{0}: {1,-12} {2,-5} {3,8:N0} GB gesamt {4,8:N0} GB frei  {5}" -f $_.DriveLetter, $_.FileSystemLabel, $_.FileSystemType, ($_.Size / 1GB), ($_.SizeRemaining / 1GB), $_.HealthStatus
}

Section 'Bestehende Dev Drives'
$refs = @(Get-Volume | Where-Object { $_.DriveLetter -and $_.FileSystemType -eq 'ReFS' })
if ($refs.Count -eq 0) {
    'kein ReFS-Volume vorhanden'
} else {
    foreach ($v in $refs) {
        $queryLines = @(& $fsutilPath devdrv query "$($v.DriveLetter):" 2>&1)
        $q = $queryLines -join "`n"
        $trusted = if ($LASTEXITCODE -eq 0) { Get-DevDriveTrustState $q } else { 'kein bestätigtes Dev Drive' }
        $filterLines = @($queryLines | Where-Object { $_ -match '(?i)filter' })
        $filters = if ($filterLines) { ($filterLines -join ' | ').Trim() } else { 'unbekannt' }
        "{0}: {1} | Filter: {2}" -f $v.DriveLetter, $trusted, $filters
    }
}

Section 'Angehaengte VHD/VHDX'
$images = @(Get-Disk | Where-Object { $_.FriendlyName -match 'Virtual Disk' })
if ($images.Count -eq 0) { 'keine' } else {
    foreach ($d in $images) {
        "Disk {0}: {1}" -f $d.Number, ($(if ($d.Location) { $d.Location } else { 'Pfad nicht ermittelbar' }))
    }
}

Section 'Geplante Aufgaben mit VHD-Bezug'
$tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.Description -like 'Managed by labi setup:devdrive:*' -or
    ($_.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -match 'vhd'
})
if ($tasks.Count -eq 0) { 'keine' } else {
    foreach ($t in $tasks) { "{0}{1} ({2}) | {3}" -f $t.TaskPath, $t.TaskName, $t.State, $t.Description }
}

Section 'Toolchains'
foreach ($tool in 'bun','node','npm','pnpm','yarn','cargo','rustup','python','pip','uv','dotnet','nuget','go','gradle','mvn','docker') {
    $c = Get-Command $tool -ErrorAction SilentlyContinue
    "{0}: {1}" -f $tool, ($(if ($c) { $c.Source } else { 'FEHLT' }))
}

Section 'Cache-Variablen (User-Scope)'
$vars = 'BUN_INSTALL','BUN_INSTALL_CACHE_DIR','CARGO_HOME','RUSTUP_HOME','CARGO_TARGET_DIR',
        'npm_config_cache','PNPM_HOME','YARN_CACHE_FOLDER','PIP_CACHE_DIR','UV_CACHE_DIR',
        'NUGET_PACKAGES','GOPATH','GOBIN','GOMODCACHE','GOCACHE','GRADLE_USER_HOME','MAVEN_OPTS','NVM_HOME','NVM_SYMLINK'
foreach ($v in $vars) {
    $val = [Environment]::GetEnvironmentVariable($v, 'User')
    "{0} = {1}" -f $v, ($(if ($val) { $val } else { '(nicht gesetzt)' }))
}

Section 'Umzugskandidaten (Ist-Pfade mit Groesse)'
$home_ = [Environment]::GetFolderPath('UserProfile')
$local = $env:LOCALAPPDATA
$go = Get-Command go -ErrorAction SilentlyContinue
$goPath = Get-ConfiguredPath 'GOPATH' (Join-Path $home_ 'go')
$goModCache = Get-ConfiguredPath 'GOMODCACHE' $null
$goBuildCache = Get-ConfiguredPath 'GOCACHE' $null
if ($go -and -not $goModCache) {
    $goModCacheOutput = @(& $go.Source env GOMODCACHE 2>$null)
    if ($LASTEXITCODE -eq 0 -and $goModCacheOutput) { $goModCache = $goModCacheOutput[-1] }
}
if ($go -and -not $goBuildCache) {
    $goBuildCacheOutput = @(& $go.Source env GOCACHE 2>$null)
    if ($LASTEXITCODE -eq 0 -and $goBuildCacheOutput) { $goBuildCache = $goBuildCacheOutput[-1] }
}
$cands = [ordered]@{
    'Bun-Cache'                = Get-ConfiguredPath 'BUN_INSTALL_CACHE_DIR' (Join-Path $home_ '.bun\install\cache')
    'Cargo (CARGO_HOME)'       = Get-ConfiguredPath 'CARGO_HOME' (Join-Path $home_ '.cargo')
    'Rustup (RUSTUP_HOME)'     = Get-ConfiguredPath 'RUSTUP_HOME' (Join-Path $home_ '.rustup')
    'npm-Cache'                = Get-ConfiguredPath 'npm_config_cache' (Join-Path $local 'npm-cache')
    'pip-Cache'                = Get-ConfiguredPath 'PIP_CACHE_DIR' (Join-Path $local 'pip\cache')
    'uv-Cache'                 = Get-ConfiguredPath 'UV_CACHE_DIR' (Join-Path $local 'uv\cache')
    'NuGet-Pakete'             = Get-ConfiguredPath 'NUGET_PACKAGES' (Join-Path $home_ '.nuget\packages')
    'Gradle'                   = Get-ConfiguredPath 'GRADLE_USER_HOME' (Join-Path $home_ '.gradle')
    'Maven-Repository'         = Join-Path $home_ '.m2\repository'
}
if ($goModCache) { $cands['Go-Modulcache'] = $goModCache }
if ($goBuildCache) { $cands['Go-Buildcache'] = $goBuildCache }
$pnpm = Get-Command pnpm -ErrorAction SilentlyContinue
if ($pnpm) {
    $pnpmStoreOutput = @(& $pnpm.Source store path 2>$null)
    if ($LASTEXITCODE -eq 0 -and $pnpmStoreOutput) { $cands['pnpm-Store'] = $pnpmStoreOutput[-1] }
}
foreach ($k in $cands.Keys) { Format-Candidate $k $cands[$k] }
if (-not $cands.Contains('pnpm-Store')) { 'pnpm-Store: nicht ermittelbar (pnpm store path fehlgeschlagen oder pnpm fehlt)' }

Section 'Bewusst nicht umziehen (nur zur Info)'
foreach ($p in @(
    @{ n = 'Bun-Installation und globale Binaerdateien'; p = (Get-ConfiguredPath 'BUN_INSTALL' (Join-Path $home_ '.bun')) },
    @{ n = 'nvm4w (Node-Installationen)'; p = $env:NVM_HOME },
    @{ n = 'Python-Installation'; p = (Get-Command python -ErrorAction SilentlyContinue).Source },
    @{ n = 'Go-GOPATH (src und bin bleiben, Caches werden getrennt behandelt)'; p = $goPath },
    @{ n = 'Docker-Datenordner'; p = (Join-Path $local 'Docker') }
)) {
    if ($p.p) { "{0}: {1}" -f $p.n, $p.p }
}

Section 'Repo-Ordner (.git bis Tiefe 3)'
$roots = @()
if ($RepoRoots) { $roots += $RepoRoots }
$roots += @(
    (Join-Path $home_ 'source'), (Join-Path $home_ 'Source'), (Join-Path $home_ 'repos'),
    (Join-Path $home_ 'Projects'), (Join-Path $home_ 'Coding'), (Join-Path $home_ 'dev'),
    (Join-Path $home_ 'Desktop'), (Join-Path $home_ 'Documents'), (Join-Path $goPath 'src')
)
foreach ($drive in (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' })) {
    $roots += @(Get-ChildItem -LiteralPath $drive.Root -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '^(Windows|Program Files|Program Files \(x86\)|ProgramData|Users|\$Recycle\.Bin|System Volume Information|Recovery|PerfLogs|Intel)$' } |
        Select-Object -ExpandProperty FullName)
}
$roots = $roots | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique
$found = @()
foreach ($r in $roots) {
    $found += @(Get-ChildItem -LiteralPath $r -Filter '.git' -Force -Recurse -Depth 3 -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Parent.FullName })
}
$found = $found | Select-Object -Unique | Sort-Object
if ($found.Count -eq 0) { 'keine Repos gefunden (Suchpfade per -RepoRootsFile erweitern)' } else {
    foreach ($f in $found) {
        $gitMarker = Join-Path $f '.git'
        $repoKind = if (Test-Path -LiteralPath $gitMarker -PathType Leaf) {
            'Repo (verknuepfter Worktree, nicht automatisch umziehen)'
        } elseif (Test-Path -LiteralPath (Join-Path $gitMarker 'worktrees') -PathType Container) {
            'Repo (hat verknuepfte Worktrees, nicht automatisch umziehen)'
        } else {
            'Repo'
        }
        Format-Candidate $repoKind $f
    }
}

Section 'Hinweise'
if (-not $devDriveCapable) { 'Dev Drive braucht Windows 11 Build 22621.2338 oder neuer.' }
if (-not $isAdmin) { 'VHDX anlegen, formatieren und Task registrieren brauchen einen erhoehten Prozess (invoke-elevated.ps1).' }
'Filtertreiber-Liste (fltmc) braucht Admin und wird im elevated Schritt gezeigt.'
