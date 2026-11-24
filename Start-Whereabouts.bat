@echo off
rem Double-click to open Whereabouts. The small background server stops itself ~10 minutes after you close the app.
cd /d "%~dp0"
start "" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0server.ps1"
