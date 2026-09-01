#Requires -RunAsAdministrator
# devdrive: Prueft nur den privilegierten Volume-, Trust- und Task-Zustand.
param(
    [Parameter(Mandatory)][ValidatePattern('^[D-Z]$')][string]$DriveLetter,
    [string]$ExpectedImagePath,
    [string]$TaskName = 'Mount DevDrive'
)
$ErrorActionPreference = 'Continue'
$ok = $true
$root = "$DriveLetter`:\"
$fsutilPath = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)) 'System32\fsutil.exe'

function Fail($m) { Write-Host "FEHLER  $m" -ForegroundColor Red; $script:ok = $false }
function Warn($m) { Write-Host "HINWEIS $m" -ForegroundColor Yellow }
function Pass($m) { Write-Host "OK      $m" -ForegroundColor Green }
function Get-DevDriveTrustState([string]$QueryText) {
    if ($QueryText -match '(?i)\buntrusted\b|\bnot\b[^\r\n]{0,80}\btrusted\b|\b(?:nicht|kein\w*)\b[^\r\n]{0,80}\bvertrauensw') { return 'Untrusted' }
    if ($QueryText -match '(?i)\btrusted\b|\bvertrauensw') { return 'Trusted' }
    return 'Unknown'
}
function Get-NormalizedPath([string]$Path) {
    return [IO.Path]::GetFullPath($Path).TrimEnd('\')
}

if (-not (Test-Path -LiteralPath $root)) {
    Fail "$DriveLetter`: nicht gemountet"
} else {
    $v = Get-Volume -DriveLetter $DriveLetter
    if ($v.FileSystemType -ne 'ReFS') { Fail "$DriveLetter`: ist $($v.FileSystemType), kein ReFS" } else { Pass ("$DriveLetter`: ReFS, {0:N0} GB frei" -f ($v.SizeRemaining / 1GB)) }
    $queryLines = @(& $fsutilPath devdrv query "$DriveLetter`:" 2>&1)
    $q = $queryLines -join "`n"
    if ($LASTEXITCODE -ne 0) { Fail "fsutil devdrv query fehlgeschlagen: $q" }
    else {
        $trustState = Get-DevDriveTrustState $q
        if ($trustState -eq 'Trusted') { Pass 'Dev Drive trusted' }
        elseif ($trustState -eq 'Untrusted') { Fail 'Dev Drive nicht trusted (fsutil devdrv trust)' }
        else { Fail 'Trust-Status aus der lokalisierten fsutil-Ausgabe nicht maschinell verifizierbar' }
    }
    $filterLines = @($queryLines | Where-Object { $_ -match '(?i)filter' })
    if ($filterLines) {
        $f = ($filterLines -join ' | ').Trim()
        if ($f -match ',') { Warn "Mehrere Filterregeln oder -treiber: $f" } else { Pass "Filterstatus: $f" }
    }
}

if ($ExpectedImagePath) {
    $expectedImageFull = Get-NormalizedPath $ExpectedImagePath
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $task) {
        Fail "Mount-Task '$TaskName' fehlt"
    } elseif (-not ([string]$task.Description).Contains($expectedImageFull, [StringComparison]::OrdinalIgnoreCase)) {
        Fail "Mount-Task '$TaskName' zeigt nicht auf $expectedImageFull"
    } else {
        Pass "Mount-Task '$TaskName' ($($task.State))"
    }
}

if ($ok) { Write-Host "`nDev-Drive-Admin-Scope $DriveLetter`: OK" -ForegroundColor Green; return }
Write-Host "`nBefunde vorhanden" -ForegroundColor Red
throw 'Privilegierte Dev-Drive-Verifikation fehlgeschlagen.'
