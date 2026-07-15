# Windows-Toast für notify.sh — BurntToast falls installiert, sonst natives WinRT-Toast.
# Darf nie fehlschlagen: alles in try/catch, immer exit 0.
param(
  [string]$Title = "Claude Code",
  [string]$Subtitle = "",
  [string]$Message = ""
)

try {
  if (Get-Module -ListAvailable -Name BurntToast -ErrorAction SilentlyContinue) {
    Import-Module BurntToast -ErrorAction Stop
    $lines = @($Title, $Subtitle, $Message) | Where-Object { $_ }
    New-BurntToastNotification -Text $lines | Out-Null
  } else {
    [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
    $t = [System.Security.SecurityElement]::Escape($Title)
    $s = [System.Security.SecurityElement]::Escape($Subtitle)
    $m = [System.Security.SecurityElement]::Escape($Message)
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml("<toast><visual><binding template=""ToastText04""><text id=""1"">$t</text><text id=""2"">$s</text><text id=""3"">$m</text></binding></visual></toast>")
    # PowerShell-AppId: funktioniert ohne App-Registrierung
    $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show(
      [Windows.UI.Notifications.ToastNotification]::new($xml))
  }
} catch {}
exit 0
