@echo off
rem Fallback: opens index.html straight from the folder (no server needed).
rem NOTE: data saved this way is tied to this exact folder location. Don't move the folder afterwards, and keep JSON backups.
start "" "%~dp0index.html"
