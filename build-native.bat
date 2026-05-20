@echo off
setlocal
set "NO_PAUSE="
if /I "%~1"=="/nopause" set "NO_PAUSE=1"

pushd "%~dp0"

set CSC=%SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\csc.exe
if not exist "%CSC%" set CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe

if not exist "%CSC%" (
    echo C# compiler not found.
    if not defined NO_PAUSE pause
    popd
    exit /b 1
)

if not exist "dist" mkdir "dist"

"%CSC%" /nologo /target:winexe /out:"dist\NetworkTester.exe" /reference:System.dll /reference:System.Core.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll "src\native\NetworkTester.cs"

if errorlevel 1 (
    echo Build failed.
    if not defined NO_PAUSE pause
    popd
    exit /b 1
)

echo.
echo Built native app:
echo %CD%\dist\NetworkTester.exe
echo.
if not defined NO_PAUSE pause
popd
