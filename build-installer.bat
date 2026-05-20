@echo off
setlocal
pushd "%~dp0"

set "NO_PAUSE="
if /I "%~1"=="/nopause" set "NO_PAUSE=1"

call "build-native.bat" /nopause
if errorlevel 1 (
    if not defined NO_PAUSE pause
    popd
    exit /b 1
)

if not exist "dist\NetworkTester.exe" (
    echo Missing dist\NetworkTester.exe
    if not defined NO_PAUSE pause
    popd
    exit /b 1
)

set "CSC=%SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe"

if not exist "%CSC%" (
    echo C# compiler not found.
    if not defined NO_PAUSE pause
    popd
    exit /b 1
)

if exist "dist\NetworkTesterSetup.exe" del /f /q "dist\NetworkTesterSetup.exe"

"%CSC%" /nologo /target:winexe /out:"dist\NetworkTesterSetup.exe" /resource:"dist\NetworkTester.exe",NetworkTester.exe /reference:System.dll /reference:System.Core.dll /reference:System.Windows.Forms.dll "src\native\Installer.cs"

if errorlevel 1 (
    echo Installer build failed.
    if not defined NO_PAUSE pause
    popd
    exit /b 1
)

echo.
echo Built installer:
echo %CD%\dist\NetworkTesterSetup.exe
echo.
if not defined NO_PAUSE pause
popd
