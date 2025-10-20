# Flutter Installation Script for Windows
# Run this script as Administrator in PowerShell

param(
    [string]$InstallPath = "C:\flutter",
    [switch]$SkipPathUpdate = $false
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Flutter SDK Installation Script" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "Some operations may fail without admin privileges" -ForegroundColor Yellow
    Write-Host "`n"
}

# Check if Flutter already exists
if (Test-Path "$InstallPath\bin\flutter.bat") {
    Write-Host "Flutter already installed at: $InstallPath" -ForegroundColor Yellow
    $response = Read-Host "Do you want to reinstall? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "Installation cancelled" -ForegroundColor Yellow
        exit 0
    }
    Write-Host "Removing existing installation..." -ForegroundColor Yellow
    Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Create installation directory
Write-Host "[1/6] Creating installation directory..." -ForegroundColor Green
if (-not (Test-Path (Split-Path $InstallPath))) {
    New-Item -ItemType Directory -Path (Split-Path $InstallPath) -Force | Out-Null
}

# Download Flutter SDK
$downloadUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_stable.zip"
$zipFile = "$env:TEMP\flutter_windows_stable.zip"

Write-Host "[2/6] Downloading Flutter SDK..." -ForegroundColor Green
Write-Host "      This may take several minutes (approximately 800 MB)" -ForegroundColor Gray

try {
    # Use WebClient for progress bar
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($downloadUrl, $zipFile)
    Write-Host "      Download complete!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to download Flutter SDK" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Verify download
if (-not (Test-Path $zipFile)) {
    Write-Host "ERROR: Downloaded file not found" -ForegroundColor Red
    exit 1
}

$fileSize = (Get-Item $zipFile).Length / 1MB
Write-Host "      Downloaded: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray

# Extract Flutter
Write-Host "[3/6] Extracting Flutter SDK to $InstallPath..." -ForegroundColor Green
Write-Host "      This may take a few minutes..." -ForegroundColor Gray

try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, (Split-Path $InstallPath))
    Write-Host "      Extraction complete!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to extract Flutter SDK" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Cleanup download
Write-Host "[4/6] Cleaning up..." -ForegroundColor Green
Remove-Item $zipFile -ErrorAction SilentlyContinue

# Add to PATH
if (-not $SkipPathUpdate) {
    Write-Host "[5/6] Adding Flutter to PATH..." -ForegroundColor Green

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $flutterBinPath = "$InstallPath\bin"

    if ($userPath -notlike "*$flutterBinPath*") {
        try {
            [Environment]::SetEnvironmentVariable(
                "Path",
                "$userPath;$flutterBinPath",
                "User"
            )
            Write-Host "      Flutter added to PATH" -ForegroundColor Green

            # Update current session
            $env:Path += ";$flutterBinPath"
        } catch {
            Write-Host "WARNING: Failed to add Flutter to PATH" -ForegroundColor Yellow
            Write-Host "You'll need to add it manually: $flutterBinPath" -ForegroundColor Yellow
        }
    } else {
        Write-Host "      Flutter already in PATH" -ForegroundColor Yellow
    }
} else {
    Write-Host "[5/6] Skipping PATH update (use -SkipPathUpdate to control)" -ForegroundColor Yellow
}

# Verify installation
Write-Host "[6/6] Verifying installation..." -ForegroundColor Green

if (Test-Path "$InstallPath\bin\flutter.bat") {
    Write-Host "      Flutter SDK installed successfully!" -ForegroundColor Green

    # Update current session PATH
    $env:Path += ";$InstallPath\bin"

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Installation Complete!" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "Installation Path: $InstallPath" -ForegroundColor White
    Write-Host "`nNext Steps:" -ForegroundColor Cyan
    Write-Host "  1. Close and reopen your terminal" -ForegroundColor White
    Write-Host "  2. Run: flutter doctor" -ForegroundColor Yellow
    Write-Host "  3. Navigate to your project:" -ForegroundColor White
    Write-Host "     cd C:\Users\207ds\Desktop\Apps\MLO-CALC" -ForegroundColor Yellow
    Write-Host "  4. Install dependencies:" -ForegroundColor White
    Write-Host "     flutter pub get" -ForegroundColor Yellow
    Write-Host "  5. Run your app:" -ForegroundColor White
    Write-Host "     flutter run -d chrome" -ForegroundColor Yellow

    Write-Host "`n========================================`n" -ForegroundColor Cyan

    # Try to run flutter doctor
    Write-Host "Running flutter doctor to check your environment...`n" -ForegroundColor Gray
    try {
        & "$InstallPath\bin\flutter.bat" doctor
    } catch {
        Write-Host "`nNote: Please close and reopen your terminal to use Flutter commands" -ForegroundColor Yellow
    }

} else {
    Write-Host "ERROR: Installation verification failed" -ForegroundColor Red
    Write-Host "Flutter executable not found at: $InstallPath\bin\flutter.bat" -ForegroundColor Red
    exit 1
}

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
