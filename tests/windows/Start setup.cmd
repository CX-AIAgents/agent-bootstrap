@echo off
setlocal
if /I not "%USERNAME%"=="WDAGUtilityAccount" (
  echo Open this launcher inside Windows Sandbox.
  pause
  exit /b 2
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0Prepare.ps1"
if errorlevel 1 (
  echo See "%TEMP%\mise-sandbox-setup\Setup status.txt" and "Setup details.txt" in the same folder.
  pause
  exit /b 1
)
exit /b 0
