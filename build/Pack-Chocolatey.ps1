#Requires -Version 7.5

$ErrorActionPreference = "Stop"

$Root = Resolve-Path "$PSScriptRoot\.."
$ChocoBuildDir = Join-Path $PSScriptRoot "chocolatey"
$NuspecPath = Join-Path $ChocoBuildDir "Win-Debloat7.nuspec"
$DistDir = Join-Path $Root "dist"

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Error "Chocolatey (choco.exe) is not found in PATH. Please install it first: https://chocolatey.org/install"
}

Write-Host "📦 Packaging Win-Debloat7 for Chocolatey..." -ForegroundColor Cyan

# Ensure dist exists
if (-not (Test-Path $DistDir)) { New-Item -Path $DistDir -ItemType Directory | Out-Null }

# Run choco pack
# We change location to the nuspec dir so relative paths in nuspec work correctly
Push-Location $ChocoBuildDir
try {
    choco pack "Win-Debloat7.nuspec" --output-directory "$DistDir"
    if ($LASTEXITCODE -ne 0) {
        throw "Chocolatey pack failed with exit code $LASTEXITCODE"
    }
    Write-Host "`n✅ Successfully created .nupkg in dist/" -ForegroundColor Green
    Get-ChildItem -Path $DistDir -Filter "*.nupkg" | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
}
finally {
    Pop-Location
}
