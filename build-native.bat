@echo off
setlocal

set CSC=%SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\csc.exe
if not exist "%CSC%" set CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe

if not exist "%CSC%" (
    echo C# compiler not found.
    pause
    exit /b 1
)

if not exist "%~dp0dist" mkdir "%~dp0dist"

"%CSC%" /nologo /target:winexe /out:"%~dp0dist\NetworkTester.exe" /reference:System.dll /reference:System.Core.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll "%~dp0src\native\NetworkTester.cs"

if errorlevel 1 (
    echo Build failed.
    pause
    exit /b 1
)

echo.
echo Built native app:
echo %~dp0dist\NetworkTester.exe
echo.
pause
