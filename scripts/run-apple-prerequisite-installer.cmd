@echo off
setlocal

fltmc >nul 2>&1
if errorlevel 1 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "E:\iCloud\Installer\install-apple-prerequisites.ps1" -ITunesRoot "E:\iTunes" -ICloudRoot "E:\iCloud"
set "INSTALL_EXIT=%ERRORLEVEL%"

echo.
if "%INSTALL_EXIT%"=="0" (
    echo Apple prerequisites installation completed successfully.
) else (
    echo Apple prerequisites installation failed with exit code %INSTALL_EXIT%.
)
echo Press any key to close this window.
pause >nul
exit /b %INSTALL_EXIT%
