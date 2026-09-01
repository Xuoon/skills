#Requires -RunAsAdministrator
# devdrive: Registriert eine geplante Aufgabe, die die VHDX beim Systemstart anhaengt.
# Windows haengt VHDX-Dateien nach einem Neustart nicht selbst wieder an.
# Laeuft als SYSTEM, damit sie vor der Anmeldung greift. Idempotent: eine
# vorhandene Aufgabe gleichen Namens wird ersetzt.
param(
    [Parameter(Mandatory)][string]$ImagePath,
    [string]$TaskName = 'Mount DevDrive'
)
$ErrorActionPreference = 'Stop'
$windowsRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
$system32 = Join-Path $windowsRoot 'System32'
$env:PATH = @($PSHOME, $system32, $windowsRoot, (Join-Path $system32 'WindowsPowerShell\v1.0')) -join ';'
$env:PSModulePath = @((Join-Path $PSHOME 'Modules'), (Join-Path $system32 'WindowsPowerShell\v1.0\Modules')) -join ';'

if (-not (Test-Path -LiteralPath $ImagePath)) { throw "VHDX nicht gefunden: $ImagePath" }
if ($ImagePath -match '[\x00-\x1F]') { throw '-ImagePath enthaelt ungueltige Steuerzeichen.' }
if ([IO.Path]::GetExtension($ImagePath) -ne '.vhdx') { throw '-ImagePath muss auf .vhdx enden.' }
if ($TaskName -match '[*?\[\]]') { throw '-TaskName darf keine Platzhalter enthalten.' }

$resolvedImagePath = (Resolve-Path -LiteralPath $ImagePath).Path
$systemPowerShell = Join-Path $system32 'WindowsPowerShell\v1.0\powershell.exe'
if (-not (Test-Path -LiteralPath $systemPowerShell -PathType Leaf)) { throw "System-PowerShell fehlt: $systemPowerShell" }
$escapedImagePath = $resolvedImagePath.Replace("'", "''")
$command = "`$imagePath = '$escapedImagePath'; if (-not (Get-DiskImage -ImagePath `$imagePath).Attached) { Mount-DiskImage -ImagePath `$imagePath }"
$encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
$action = New-ScheduledTaskAction -Execute $systemPowerShell -Argument "-NoProfile -NonInteractive -EncodedCommand $encodedCommand"
$trigger = New-ScheduledTaskTrigger -AtStartup -RandomDelay (New-TimeSpan -Seconds 30)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$descriptionPrefix = 'Managed by labi setup:devdrive: '
$description = $descriptionPrefix + $resolvedImagePath

$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing -and -not ([string]$existing.Description).Equals($description, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Aufgabe '$TaskName' existiert bereits fuer einen anderen Zweck oder eine andere VHDX."
}
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description $description -Force | Out-Null
$t = Get-ScheduledTask -TaskName $TaskName
"Aufgabe '$TaskName' $(if ($existing) { 'aktualisiert' } else { 'registriert' }) ($($t.State)), Trigger: Systemstart + bis zu 30 s Verzoegerung, Konto: SYSTEM"
"VHDX: $resolvedImagePath"
