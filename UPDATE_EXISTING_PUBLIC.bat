@echo off
setlocal
cd /d "%~dp0"
echo Creature War PUBLIC portfolio - clone and update existing GitHub repo
echo This script works from the extracted ZIP folder (no .git needed here).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0UPDATE_EXISTING_PUBLIC.ps1"
set "EC=%ERRORLEVEL%"
echo.
if not "%EC%"=="0" echo Update failed. See the message above. No private project is uploaded.
pause
exit /b %EC%
