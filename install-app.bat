@echo off
REM Installs Network Tester shortcuts for the current Windows user.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-NetworkTester.ps1"
