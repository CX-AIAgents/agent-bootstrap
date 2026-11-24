@echo off
setlocal
if /I not "%USERNAME%"=="WDAGUtilityAccount" (
  echo Open this launcher inside Windows Sandbox.
  pause
  exit /b 2
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0Prepare.ps1"
if errorlevel 1 (
  echo See "%TEMP%\mise-sandbox-setup\setup.log" for details.
  pause
  exit /b 1
)
exit /b 0
