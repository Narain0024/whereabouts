# Whereabouts local server — serves this folder on http://localhost:5179 (localhost only).
# Uses only what ships with Windows (PowerShell + .NET HttpListener). No installs, no admin rights.
param([int]$Port = 5179, [switch]$NoBrowser, [switch]$Minimized)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$url  = "http://localhost:$Port/"

function Open-App {
  if ($NoBrowser) { return }
  $edge   = Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'
  $edge64 = Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'
  $chrome = Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'
  $chrome86 = Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'
  foreach ($b in @($edge, $edge64, $chrome, $chrome86)) {
    if (Test-Path $b) {
      $style = if ($Minimized) { 'Minimized' } else { 'Normal' }
      Start-Process -FilePath $b -ArgumentList "--app=$url" -WindowStyle $style; return
    }
  }
  Start-Process $url   # fall back to the default browser
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
try { $listener.Start() }
catch {
  # Port already in use -> the server is probably already running. Just open the app.
  Open-App; exit 0
}

$mime = @{ '.html'='text/html; charset=utf-8'; '.js'='text/javascript; charset=utf-8'; '.css'='text/css; charset=utf-8'; '.json'='application/json'; '.webmanifest'='application/manifest+json';
           '.svg'='image/svg+xml'; '.png'='image/png'; '.ico'='image/x-icon'; '.woff2'='font/woff2'; '.txt'='text/plain; charset=utf-8' }

Open-App
$lastPing = Get-Date; $seenPing = $false
$task = $listener.GetContextAsync()
while ($listener.IsListening) {
  if ($task.Wait(5000)) {
    $ctx = $task.Result; $task = $listener.GetContextAsync()
    try {
      $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
      if ($path -eq '__ping') { $lastPing = Get-Date; $seenPing = $true; $ctx.Response.StatusCode = 204; $ctx.Response.Close(); continue }
      if ($path -eq '') { $path = 'index.html' }
      $file = [IO.Path]::GetFullPath((Join-Path $root $path))
      if (-not $file.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path $file -PathType Leaf) -or ($file -match '\.(ps1|bat|md)$')) {
        $ctx.Response.StatusCode = 404
      } else {
        $bytes = [IO.File]::ReadAllBytes($file)
        $ext = [IO.Path]::GetExtension($file).ToLower()
        $ctx.Response.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
        $ctx.Response.Headers.Add('Cache-Control', 'no-cache')
        $ctx.Response.ContentLength64 = $bytes.Length
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      }
    } catch { }
    finally { try { $ctx.Response.Close() } catch { } }
  }
  elseif ($seenPing -and ((Get-Date) - $lastPing).TotalMinutes -gt 10) { break }   # app window closed ~10 min ago -> quit quietly
}
$listener.Stop()
