param(
    [switch]$NoDesktopShortcut
)

$ErrorActionPreference = 'Stop'

$appName = 'Network Tester'
$appRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcher = Join-Path $appRoot 'NetworkTester.ps1'
$powershellPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

if (-not (Test-Path -LiteralPath $launcher)) {
    throw "Launcher not found: $launcher"
}

$startMenuDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Network Tester'
$desktopDir = [Environment]::GetFolderPath('Desktop')
$iconPath = Join-Path $appRoot 'public\icon.ico'

New-Item -ItemType Directory -Path $startMenuDir -Force | Out-Null

$shell = New-Object -ComObject WScript.Shell

function New-AppShortcut {
    param(
        [string]$ShortcutPath
    )

    $shortcut = $shell.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath = $powershellPath
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$launcher`""
    $shortcut.WorkingDirectory = $appRoot
    if (Test-Path -LiteralPath $iconPath) {
        $shortcut.IconLocation = $iconPath
    }
    $shortcut.Save()
}

New-AppShortcut -ShortcutPath (Join-Path $startMenuDir "$appName.lnk")

if (-not $NoDesktopShortcut) {
    New-AppShortcut -ShortcutPath (Join-Path $desktopDir "$appName.lnk")
}

Write-Host "$appName installed." -ForegroundColor Green
Write-Host 'Use the Start Menu or Desktop shortcut to launch it.'
Read-Host 'Press Enter to close'
