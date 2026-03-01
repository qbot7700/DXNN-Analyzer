# DXNN Analyzer Web - Setup Script for Windows
# Run this script to set up the Phoenix LiveView interface

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "DXNN Analyzer Web - Setup Script" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check Elixir installation
Write-Host "Checking Elixir installation..." -ForegroundColor Yellow
try {
    $elixirVersion = elixir --version 2>&1
    Write-Host "✓ Elixir is installed" -ForegroundColor Green
    Write-Host $elixirVersion
} catch {
    Write-Host "✗ Elixir is not installed" -ForegroundColor Red
    Write-Host "Please install Elixir from: https://elixir-lang.org/install.html" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check Node.js installation
Write-Host "Checking Node.js installation..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>&1
    Write-Host "✓ Node.js is installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js is not installed" -ForegroundColor Red
    Write-Host "Please install Node.js from: https://nodejs.org/" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Install Hex
Write-Host "Installing Hex package manager..." -ForegroundColor Yellow
mix local.hex --force
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Hex installed successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to install Hex" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Install Phoenix
Write-Host "Installing Phoenix..." -ForegroundColor Yellow
mix archive.install hex phx_new --force
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Phoenix installed successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to install Phoenix" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Install Elixir dependencies
Write-Host "Installing Elixir dependencies..." -ForegroundColor Yellow
mix deps.get
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Elixir dependencies installed" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to install Elixir dependencies" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Install Node.js dependencies
Write-Host "Installing Node.js dependencies..." -ForegroundColor Yellow
Push-Location assets
npm install
$npmResult = $LASTEXITCODE
Pop-Location

if ($npmResult -eq 0) {
    Write-Host "✓ Node.js dependencies installed" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to install Node.js dependencies" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check if DXNN Analyzer is compiled
Write-Host "Checking DXNN Analyzer compilation..." -ForegroundColor Yellow
$analyzerPath = "..\dxnn_analyzer\ebin"
if (Test-Path $analyzerPath) {
    $beamFiles = Get-ChildItem -Path $analyzerPath -Filter "*.beam"
    if ($beamFiles.Count -gt 0) {
        Write-Host "✓ DXNN Analyzer is compiled ($($beamFiles.Count) beam files found)" -ForegroundColor Green
    } else {
        Write-Host "⚠ DXNN Analyzer ebin directory exists but no beam files found" -ForegroundColor Yellow
        Write-Host "  Attempting to compile..." -ForegroundColor Yellow
        Push-Location ..\dxnn_analyzer
        rebar3 compile
        Pop-Location
    }
} else {
    Write-Host "⚠ DXNN Analyzer not found at $analyzerPath" -ForegroundColor Yellow
    Write-Host "  Attempting to compile..." -ForegroundColor Yellow
    if (Test-Path "..\dxnn_analyzer") {
        Push-Location ..\dxnn_analyzer
        rebar3 compile
        Pop-Location
    } else {
        Write-Host "✗ DXNN Analyzer directory not found" -ForegroundColor Red
        Write-Host "  Please ensure the analyzer is in ../dxnn_analyzer" -ForegroundColor Red
    }
}

Write-Host ""

# Compile assets
Write-Host "Compiling assets..." -ForegroundColor Yellow
Push-Location assets
npm run deploy
$deployResult = $LASTEXITCODE
Pop-Location

if ($deployResult -eq 0) {
    Write-Host "✓ Assets compiled successfully" -ForegroundColor Green
} else {
    Write-Host "⚠ Asset compilation had issues (this may be normal)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To start the server, run:" -ForegroundColor Yellow
Write-Host "  mix phx.server" -ForegroundColor White
Write-Host ""
Write-Host "Or with IEx:" -ForegroundColor Yellow
Write-Host "  iex -S mix phx.server" -ForegroundColor White
Write-Host ""
Write-Host "Then open your browser to:" -ForegroundColor Yellow
Write-Host "  http://localhost:4000" -ForegroundColor White
Write-Host ""
