#Requires -Version 7.5

<#
.SYNOPSIS
    Builds Single-File Executable releases of Win-Debloat7.
    
.DESCRIPTION
    Creates two standalone executables (Standard/Extras) with embedded payloads.
#>

param(
    [Parameter(Mandatory)]
    [string]$Version,
    
    [string]$OutputDir = "$PSScriptRoot\..\dist"
)

$Root = Resolve-Path "$PSScriptRoot\.."
$DistPath = $OutputDir

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      Win-Debloat7 Single-File Builder v2.0                   ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Clean output directory
if (Test-Path $OutputDir) {
    Write-Host "`n🗑️  Cleaning old builds..." -ForegroundColor Gray
    Remove-Item -Path $OutputDir -Recurse -Force
}
New-Item -Path $DistPath -ItemType Directory -Force | Out-Null

$compilerScript = "$PSScriptRoot\Compile-Launcher.ps1"
$commonExclusions = @('.git*', '.vs*', '.vscode', 'dist', 'tests', '*.zip', '*.7z', '*.rar', 'build')

# --- PREPARE ICON ---
$iconDest = "$Root\assets\logo.ico"
if (-not (Test-Path $iconDest)) {
    Write-Warning "⚠️  Icon not found at $iconDest. EXEs will be built without custom icon."
}

# ═══════════════════════════════════════════════════════════════
# MAIN BUILD LOOP
# ═══════════════════════════════════════════════════════════════

foreach ($variant in @("Standard", "Extras")) {
    Write-Host "`n📦 Building $variant Single-File Edition..." -ForegroundColor Cyan
    
    # 1. Setup Staging Area
    $stageDir = Join-Path $DistPath "Stage_$variant"
    if (Test-Path $stageDir) { Remove-Item $stageDir -Recurse -Force }
    New-Item -Path $stageDir -ItemType Directory -Force | Out-Null
    
    # 2. Copy Files
    $exclusions = $commonExclusions
    if ($variant -eq "Standard") { $exclusions += "Extras" }
    
    Get-ChildItem -Path $Root -Exclude $exclusions | Copy-Item -Destination $stageDir -Recurse -Force
    
    # Standard Cleanup (Double Check)
    if ($variant -eq "Standard" -and (Test-Path "$stageDir\src\modules\Extras")) {
        Remove-Item "$stageDir\src\modules\Extras" -Recurse -Force
    }
    
    # 3. Create Payload.zip
    $payloadZip = "$DistPath\payload_$variant.zip"
    if (Test-Path $payloadZip) { Remove-Item $payloadZip -Force }

    # DEBUG: Verify Version in Staging (GUI)
    $stagingGUI = Join-Path $stageDir "src\ui\gui\MainWindow.xaml"
    if (Test-Path $stagingGUI) {
        $guiContent = Get-Content $stagingGUI -Raw
        if ($guiContent -notmatch "v$Version") {
            Write-Host "❌ FATAL: Staging Area has OLD VERSION for $variant! Expected v$Version" -ForegroundColor Red
            throw "Staging verification failed for $variant"
        }
        else {
            Write-Host "✅ Staging Verified: GUI contains v$Version" -ForegroundColor Green
        }
    }

    Write-Host "   Compressing payload..." -ForegroundColor DarkGray
    Compress-Archive -Path "$stageDir\*" -DestinationPath $payloadZip -Force -ErrorAction Stop
    
    # 4. Compile Single-File EXE
    $launcherSrc = "$Root\src\core\LauncherEmbed.cs"
    if ($variant -eq "Standard") { $exeName = "Win-Debloat7.exe" } else { $exeName = "Win-Debloat7-Extras.exe" }
    $exeOut = "$DistPath\$exeName"
    
    Write-Host "   🔨 Compiling $exeName with embedded payload..." -ForegroundColor Gray
    
    # Run compiler
    $p = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "`"$compilerScript`"", "-SourceFile", "`"$launcherSrc`"", "-OutputFile", "`"$exeOut`"", "-Resource", "`"$payloadZip`"", "-Icon", "`"$iconDest`"" -Wait -PassThru -NoNewWindow
    
    if ($p.ExitCode -eq 0 -and (Test-Path $exeOut)) {
        $size = [math]::Round((Get-Item $exeOut).Length / 1MB, 2)
        Write-Host "   ✅ $exeName created ($size MB)" -ForegroundColor Green
    }
    else {
        Write-Host "   ❌ Failed to create $exeName" -ForegroundColor Red
    }
    
    # Cleanup Staging
    Remove-Item $stageDir -Recurse -Force
    if (Test-Path $payloadZip) { Remove-Item $payloadZip -Force }
}

# ═══════════════════════════════════════════════════════════════
# GENERATE CHECKSUMS
# ═══════════════════════════════════════════════════════════════

Write-Host "`n🔐 Generating checksums..." -ForegroundColor Cyan

$checksums = @{}
$distFiles = Get-ChildItem $DistPath -Filter "*.exe"
$checksumFile = Join-Path $DistPath "SHA256SUMS.txt"
$sb = [System.Text.StringBuilder]::new()

foreach ($file in $distFiles) {
    if ($file.Name -like "Win-Debloat7*.exe") {
        $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
        $line = "$hash  $($file.Name)"
        $sb.AppendLine($line) | Out-Null
        Write-Host "   $($file.Name): $hash" -ForegroundColor Gray
        
        if ($file.Name -eq "Win-Debloat7.exe") {
            $checksums["Standard"] = $hash
        }
    }
}
[System.IO.File]::WriteAllText($checksumFile, $sb.ToString())

# ═══════════════════════════════════════════════════════════════
# CREATE RELEASE NOTES
# ═══════════════════════════════════════════════════════════════

Write-Host "`n📝 Generating release notes..." -ForegroundColor Cyan

$ReleaseNotes = @"
# Win-Debloat7 v$Version

## 🚀 Single-File Distributions

### ✅ STANDARD (Win-Debloat7.exe)
Run this file directly. It self-extracts and runs the Standard edition (Safe, No Extras).

### ⚠️ EXTRAS (Win-Debloat7-Extras.exe)
Includes Defender Remover and MAS. Contains tools flagged by Antivirus.

## 📋 Requirements
- Windows 10/11
- PowerShell 7.5+ (Installer will prompt if missing)

## 🔐 SHA256 Checksums
``````
$($sb.ToString().Trim())
``````
"@

$ReleaseNotes | Set-Content "$DistPath\RELEASE_NOTES.md" -Encoding UTF8

Write-Host "`n✅ Build Complete." -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# UPDATE MANIFESTS (CHOCOLATEY & WINGET)
# ═══════════════════════════════════════════════════════════════

Write-Host "`n📝 Updating distribution manifests..." -ForegroundColor Cyan

# 1. Update Chocolatey NuSpec
$nuspecPath = Join-Path $Root "build\chocolatey\Win-Debloat7.nuspec"
if (Test-Path $nuspecPath) {
    (Get-Content $nuspecPath) -replace "<version>.*</version>", "<version>$Version</version>" | Set-Content $nuspecPath
    Write-Host "   Updated NuSpec version to $Version" -ForegroundColor Gray
}

# 2. Update Chocolatey Install Script
$chocoInstallPath = Join-Path $Root "build\chocolatey\tools\chocolateyinstall.ps1"
if (Test-Path $chocoInstallPath) {
    $content = Get-Content $chocoInstallPath
    $content = $content -replace "\`$version\s*=\s*'.*'", "`$version     = '$Version'"
    if ($checksums["Standard"]) {
        $content = $content -replace "\`$checksum\s*=\s*`".*`"", "`$checksum    = `"$($checksums["Standard"])`""
    }
    Set-Content -Path $chocoInstallPath -Value $content
    Write-Host "   Updated Chocolatey install script" -ForegroundColor Gray
}



Write-Host "`n🚀 Manifests Ready for Publication!" -ForegroundColor Green
