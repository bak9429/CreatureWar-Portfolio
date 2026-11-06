@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0PUBLISH_PUBLIC.ps1"
if errorlevel 1 echo Publish failed. Check the error above.
pause
