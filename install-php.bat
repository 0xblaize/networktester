@echo off
REM Opens the PHP for Windows download page and shows the exact local install folder.

echo.
echo ============================================
echo  PHP setup for Network Tester
echo ============================================
echo.
echo This app needs PHP to run.
echo.
echo Easiest setup:
echo   1. Download the latest "VS16 x64 Thread Safe" ZIP from:
echo      https://windows.php.net/download/
echo.
echo   2. Create this folder:
echo      %~dp0php
echo.
echo   3. Extract the ZIP contents into that php folder.
echo      After extraction, this file should exist:
echo      %~dp0php\php.exe
echo.
echo   4. Run install-app.bat again.
echo.
echo Opening the PHP download page now...
start https://windows.php.net/download/
echo.
pause
