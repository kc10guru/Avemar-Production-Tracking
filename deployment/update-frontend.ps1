# Glass Aero Production Tracker - Frontend Update Script (Windows)
# Run this on the VM after git pull to copy updated files to the deployment
#
# Usage:
#   cd C:\path\to\git\repo
#   git pull
#   powershell -File deployment\update-frontend.ps1 [-DeployDir C:\glass-aero-tracker]

param(
    [string]$DeployDir = "C:\glass-aero-tracker"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir   = Split-Path -Parent $ScriptDir

if (-not (Test-Path "$DeployDir\frontend")) {
    Write-Host "ERROR: $DeployDir\frontend not found. Is the app deployed?" -ForegroundColor Red
    exit 1
}

Write-Host "=== Glass Aero Frontend Update ===" -ForegroundColor Cyan
Write-Host "Source:  $RepoDir"
Write-Host "Target:  $DeployDir\frontend"
Write-Host ""

# Copy all HTML files
Write-Host "Copying HTML files..." -ForegroundColor Yellow
Copy-Item "$RepoDir\*.html" "$DeployDir\frontend\" -Force

# Copy all JS files
Write-Host "Copying JS files..." -ForegroundColor Yellow
Copy-Item "$RepoDir\js\*.js" "$DeployDir\frontend\js\" -Force

# Copy CSS if present
if (Test-Path "$RepoDir\css\*.css") {
    Write-Host "Copying CSS files..." -ForegroundColor Yellow
    if (-not (Test-Path "$DeployDir\frontend\css")) { mkdir "$DeployDir\frontend\css" -Force | Out-Null }
    Copy-Item "$RepoDir\css\*.css" "$DeployDir\frontend\css\" -Force
}

Write-Host ""
Write-Host "Done! Files updated. Nginx serves from the mounted volume," -ForegroundColor Green
Write-Host "so changes are live immediately - just hard-refresh the browser (Ctrl+Shift+R)." -ForegroundColor Green
Write-Host ""
Write-Host "If something looks wrong, restart nginx:" -ForegroundColor Gray
Write-Host "  cd $DeployDir; docker compose restart frontend" -ForegroundColor Gray
