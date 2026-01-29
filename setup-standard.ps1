[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'

Write-Host "🚀 Win-Debloat7 Installer (Standard Edition)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Get Latest Release Info from GitHub API
$Repo = "tomytate/Win-Debloat7"
$ApiUrl = "https://api.github.com/repos/$Repo/releases/latest"

try {
    Write-Host " -> Fetching latest version info..." -NoNewline
    $Release = Invoke-RestMethod -Uri $ApiUrl
    Write-Host " [OK] ($($Release.tag_name))" -ForegroundColor Green
}
catch {
    Write-Host " [ERROR]" -ForegroundColor Red
    Write-Error "Failed to fetch release info. Check your internet connection."
}

# 2. Find the Standard Edition Asset (Single-File EXE)
$Asset = $Release.assets | Where-Object { $_.name -eq "Win-Debloat7.exe" } | Select-Object -First 1

if (-not $Asset) {
    Write-Error "Could not find a valid release asset for Standard Edition."
}

# 3. Download to Temp
$DownloadUrl = $Asset.browser_download_url
$TempDir = "$env:TEMP\Win-Debloat7-Install"
$ZipPath = "$TempDir\$($Asset.name)"

if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir | Out-Null

Write-Host " -> Downloading Standard Edition..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath

# 4. Verify (Optional: Add Hash Check Here in Future)

# 5. Extract or Run
if ($ZipPath.EndsWith(".exe")) {
    Write-Host " -> Launching Installer..." -ForegroundColor Green
    Start-Process -FilePath $ZipPath -Verb RunAs
}
else {
    Write-Host " -> Extracting..." -ForegroundColor Yellow
    Expand-Archive -Path $ZipPath -DestinationPath "$env:ProgramFiles\Win-Debloat7" -Force
    
    $Launcher = "$env:ProgramFiles\Win-Debloat7\Win-Debloat7.ps1"
    if (Test-Path $Launcher) {
        Write-Host " -> Installation Complete. Running..." -ForegroundColor Green
        Start-Process pwsh -ArgumentList "-ExecutionPolicy Bypass -File `"$Launcher`"" -Verb RunAs
    }
}
