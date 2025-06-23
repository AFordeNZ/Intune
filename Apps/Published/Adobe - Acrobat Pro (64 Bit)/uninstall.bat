@echo off
SET "PS7=%ProgramFiles%\PowerShell\7\pwsh.exe"
IF EXIST "%PS7%" (
    "%PS7%" -NoProfile -ExecutionPolicy ByPass -File "%~dp0AppInstall.ps1" -Mode Uninstall
) ELSE (
    powershell.exe -NoProfile -ExecutionPolicy ByPass -File "%~dp0AppInstall.ps1" -Mode Uninstall
)
exit /b %errorlevel%
