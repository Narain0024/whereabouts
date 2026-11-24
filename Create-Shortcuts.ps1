# Creates a "Whereabouts" shortcut on your Desktop (and optionally in Windows Startup).
param([switch]$Startup)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ws = New-Object -ComObject WScript.Shell
function New-Link($dir, $args) {
  $lnk = $ws.CreateShortcut((Join-Path $dir 'Whereabouts.lnk'))
  $lnk.TargetPath = 'powershell.exe'
  $lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$root\server.ps1`" $args"
  $lnk.WorkingDirectory = $root
  $lnk.IconLocation = "$root\icons\whereabouts.ico"
  $lnk.WindowStyle = 7
  $lnk.Description = 'Whereabouts — home inventory'
  $lnk.Save()
}
New-Link ([Environment]::GetFolderPath('Desktop')) ''
Write-Host 'Desktop shortcut created.'
if ($Startup) { New-Link ([Environment]::GetFolderPath('Startup')) '-Minimized'; Write-Host 'Added to Windows Startup (opens minimised at sign-in so expiry reminders can fire).' }
