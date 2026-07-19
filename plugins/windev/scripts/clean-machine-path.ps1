#Requires -RunAsAdministrator
# windev: Bereinigt den Machine-PATH (HKLM) kontrolliert:
# - sichert den Rohwert vorher in eine Datei (Pflicht-Rückweg)
# - entfernt exakt die übergebenen Einträge (exakter Stringvergleich, case-insensitiv)
# - dedupliziert (case-insensitiv, trailing \ ignoriert), Reihenfolge bleibt erhalten
# - erhält den Registry-Typ REG_EXPAND_SZ und broadcastet WM_SETTINGCHANGE
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]]$Remove,
    [string]$BackupPath = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) ("PowerShell\machine-path-backup-{0:yyyyMMdd-HHmmss}.txt" -f (Get-Date))),
    [switch]$NoDedupe,
    [string]$ResultFile
)
$ErrorActionPreference = 'Stop'
$reg = $null
try {
    $reg = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment', $true)
    if (-not $reg) { throw 'HKLM-Umgebungsschlüssel konnte nicht geöffnet werden.' }
    $old = $reg.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)

    $backupDir = Split-Path $BackupPath -Parent
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Force -Path $backupDir | Out-Null }
    Set-Content -Path $BackupPath -Value $old -Encoding utf8

    $parts = @($old -split ';' | Where-Object { $_ })
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $new = @(foreach ($p in $parts) {
        if ($Remove -contains $p) { continue }
        if (-not $NoDedupe -and -not $seen.Add($p.TrimEnd('\'))) { continue }
        $p
    })

    $reg.SetValue('Path', ($new -join ';'), [Microsoft.Win32.RegistryValueKind]::ExpandString)
    $reg.Close()
    $reg = $null

    # Laufende Prozesse (Explorer etc.) über die Änderung informieren
    $sig = '[DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);'
    $native = Add-Type -MemberDefinition $sig -Name Broadcast -Namespace WinDev -PassThru
    [UIntPtr]$out = [UIntPtr]::Zero
    $null = $native::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$out)

    $msg = "OK: {0} -> {1} Einträge. Backup: {2}" -f $parts.Count, $new.Count, $BackupPath
    $msg
    if ($ResultFile) { Set-Content -Path $ResultFile -Value ($msg + "`n" + ($new -join ';')) -Encoding utf8 }
} catch {
    if ($ResultFile) { Set-Content -Path $ResultFile -Value ("FEHLER: " + $_.Exception.Message) -Encoding utf8 }
    throw
} finally {
    if ($reg) { $reg.Close() }
}
