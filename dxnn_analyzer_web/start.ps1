# Quick start script for DXNN Analyzer Web Interface

Write-Host "Starting DXNN Analyzer Web Interface..." -ForegroundColor Cyan
Write-Host ""

# Check if dependencies are installed
if (-not (Test-Path "deps")) {
    Write-Host "Dependencies not found. Running setup..." -ForegroundColor Yellow
    .\setup.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Setup failed. Please check errors above." -ForegroundColor Red
        exit 1
    }
}

# Check if assets are compiled
if (-not (Test-Path "priv/static/assets/app.css")) {
    Write-Host "Assets not compiled. Compiling..." -ForegroundColor Yellow
    Push-Location assets
    npm run deploy
    Pop-Location
}

Write-Host ""
Write-Host "Starting Phoenix server..." -ForegroundColor Green
Write-Host "Access the interface at: http://localhost:4000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C twice to stop the server" -ForegroundColor Yellow
Write-Host ""

# Start the server
mix phx.server
