# PHP Installation Script for Windows
# Run with: powershell -ExecutionPolicy Bypass -File "install-php.ps1"

Write-Host "================================" -ForegroundColor Green
Write-Host "PHP Installation for Windows" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# Check if PHP is already installed
try {
    $phpVersion = php --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PHP is already installed!" -ForegroundColor Green
        Write-Host $phpVersion
        exit
    }
}
catch {
    Write-Host "PHP not found. Installing..." -ForegroundColor Yellow
}

# Create PHP directory
$phpPath = "C:\PHP"
if (-not (Test-Path $phpPath)) {
    Write-Host "Creating $phpPath directory..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $phpPath -Force | Out-Null
}

Write-Host ""
Write-Host "OPTION 1: Download from Microsoft Store (Recommended)" -ForegroundColor Cyan
Write-Host "- Easiest method" -ForegroundColor Gray
Write-Host "- Search for 'PHP' in Microsoft Store" -ForegroundColor Gray
Write-Host "- Install 'PHP' by Microsoft" -ForegroundColor Gray
Write-Host ""

Write-Host "OPTION 2: Manual Download" -ForegroundColor Cyan
Write-Host "- Go to: https://windows.php.net/download/" -ForegroundColor Gray
Write-Host "- Download 'VC15 x64 Thread Safe' (Zip)" -ForegroundColor Gray
Write-Host "- Extract to: C:\PHP" -ForegroundColor Gray
Write-Host "- Then run this script again" -ForegroundColor Gray
Write-Host ""

Write-Host "After installing, restart PowerShell and test:" -ForegroundColor Yellow
Write-Host "  php --version" -ForegroundColor White
Write-Host ""

Write-Host "Then run your speed tester with:" -ForegroundColor Yellow
Write-Host "  cd 'C:\Users\USER\network tester'" -ForegroundColor White
Write-Host "  php -S localhost:8000" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to continue"
