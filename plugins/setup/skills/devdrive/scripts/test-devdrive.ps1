# devdrive: Prueft den User-Scope eines Dev Drives ohne Adminrechte.
# Mount, Dateisystem, Cache-Variablen, Tool-Herkunft und Altlasten.
# Exitcode 0 = alles gruen, 1 = mindestens ein Befund.
param(
    [Parameter(Mandatory)][ValidatePattern('^[D-Z]$')][string]$DriveLetter,
    [string]$ExpectedEnv,
    [string]$ExpectedTools,
    [string]$ExpectedPnpmStore,
    [string]$ExpectedMavenRepository
)
$ErrorActionPreference = 'Continue'
$ok = $true
$root = "$DriveLetter`:\"

function Fail($m) { Write-Host "FEHLER  $m" -ForegroundColor Red; $script:ok = $false }
function Warn($m) { Write-Host "HINWEIS $m" -ForegroundColor Yellow }
function Pass($m) { Write-Host "OK      $m" -ForegroundColor Green }
function Split-Names([string]$Value) {
    return @($Value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}
function Get-NormalizedPath([string]$Path) {
    return [IO.Path]::GetFullPath($Path).TrimEnd('\')
}

if (-not (Test-Path -LiteralPath $root)) {
    Fail "$DriveLetter`: nicht gemountet"
} else {
    $v = Get-Volume -DriveLetter $DriveLetter
    if ($v.FileSystemType -ne 'ReFS') { Fail "$DriveLetter`: ist $($v.FileSystemType), kein ReFS" } else { Pass ("$DriveLetter`: ReFS, {0:N0} GB frei" -f ($v.SizeRemaining / 1GB)) }
}

foreach ($e in (Split-Names $ExpectedEnv)) {
    $val = [Environment]::GetEnvironmentVariable($e, 'User')
    if (-not $val) { Fail "$e nicht gesetzt" }
    elseif ($val -notlike "$DriveLetter`:\*") { Fail "$e = '$val' zeigt nicht auf $DriveLetter`:" }
    elseif (-not (Test-Path -LiteralPath $val)) { Warn "$e = '$val' existiert noch nicht (wird beim ersten Lauf angelegt)" }
    else { Pass "$e = $val" }
}

foreach ($t in (Split-Names $ExpectedTools)) {
    $c = Get-Command $t -ErrorAction SilentlyContinue
    if (-not $c) { Fail "$t nicht im PATH" }
    elseif ($c.Source -notlike "$DriveLetter`:\*") { Fail "$t kommt von '$($c.Source)'" }
    else { Pass "$t von $($c.Source)" }
}

if ($ExpectedPnpmStore) {
    if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
        Fail 'pnpm nicht im PATH'
    } else {
        $pnpmOutput = @(& pnpm store path 2>&1)
        $actualStore = if ($LASTEXITCODE -eq 0 -and $pnpmOutput) { [string]$pnpmOutput[-1] } else { '' }
        $expectedStore = Get-NormalizedPath $ExpectedPnpmStore
        $actualNormalized = if ($actualStore) { Get-NormalizedPath $actualStore } else { '' }
        if (-not $actualNormalized -or -not (
            $actualNormalized.Equals($expectedStore, [StringComparison]::OrdinalIgnoreCase) -or
            $actualNormalized.StartsWith($expectedStore + '\', [StringComparison]::OrdinalIgnoreCase)
        )) {
            Fail "pnpm store path = '$actualStore', erwartet unter '$ExpectedPnpmStore'"
        } else {
            Pass "pnpm-Store: $actualStore"
        }
    }
}

if ($ExpectedMavenRepository) {
    $mavenOptions = [Environment]::GetEnvironmentVariable('MAVEN_OPTS', 'User')
    $expectedMavenNormalized = Get-NormalizedPath $ExpectedMavenRepository
    $configured = $false
    if ($mavenOptions) {
        $optionMatches = [regex]::Matches($mavenOptions, '(?i)(?:^|\s)-Dmaven\.repo\.local=(?:"([^"]*)"|''([^'']*)''|(\S+))')
        foreach ($optionMatch in $optionMatches) {
            $candidate = @($optionMatch.Groups[1..3] | Where-Object Success | Select-Object -First 1).Value
            if ($candidate -and (Get-NormalizedPath $candidate).Equals($expectedMavenNormalized, [StringComparison]::OrdinalIgnoreCase)) {
                $configured = $true
                break
            }
        }
    }
    $settingsPath = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.m2\settings.xml'
    if (-not $configured -and (Test-Path -LiteralPath $settingsPath)) {
        try {
            [xml]$settings = Get-Content -LiteralPath $settingsPath -Raw
            $configured = @($settings.SelectNodes("//*[local-name()='localRepository']")) |
                Where-Object { (Get-NormalizedPath ([string]$_.InnerText).Trim()).Equals($expectedMavenNormalized, [StringComparison]::OrdinalIgnoreCase) }
        } catch {
            Warn "Maven-settings.xml konnte nicht gelesen werden: $($_.Exception.Message)"
        }
    }
    if ($configured) { Pass "Maven-Repository: $ExpectedMavenRepository" } else { Fail "Maven-Repository nicht auf $ExpectedMavenRepository konfiguriert" }
}

$home_ = [Environment]::GetFolderPath('UserProfile')
foreach ($d in '.bun', '.cargo', '.rustup', '.nuget\packages') {
    $p = Join-Path $home_ $d
    if ((Test-Path -LiteralPath $p) -and @(Get-ChildItem -LiteralPath $p -Force -ErrorAction SilentlyContinue).Count -gt 0) {
        $target = [Environment]::GetEnvironmentVariable(@{ '.bun' = 'BUN_INSTALL'; '.cargo' = 'CARGO_HOME'; '.rustup' = 'RUSTUP_HOME'; '.nuget\packages' = 'NUGET_PACKAGES' }[$d], 'User')
        if ($target -and $target -like "$DriveLetter`:\*") { Warn "Altlast: $p ist nicht leer, obwohl die Variable auf $DriveLetter`: zeigt" }
    }
}

if ($ok) { Write-Host "`nDev-Drive-User-Scope $DriveLetter`: OK" -ForegroundColor Green; exit 0 }
Write-Host "`nBefunde vorhanden" -ForegroundColor Red
exit 1
