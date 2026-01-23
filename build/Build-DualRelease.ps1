#Requires -Version 7.5

<#
.SYNOPSIS
    Builds both Standard and Extras releases of Win-Debloat7.
    
.DESCRIPTION
    Creates two release packages:
    - Standard: Clean version (recommended for most users)
    - Extras: Includes MAS/Defender integration (advanced users)
    
.PARAMETER Version
    Version number (e.g., "1.1.0")
    
.PARAMETER OutputDir
    Output directory for release packages
    
.EXAMPLE
    .\Build-DualRelease.ps1 -Version "1.1.0"
#>

param(
    [Parameter(Mandatory)]
    [string]$Version,
    
    [string]$OutputDir = "$PSScriptRoot\..\dist"
)

$Root = Resolve-Path "$PSScriptRoot\.."
$DistPath = $OutputDir

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      Win-Debloat7 Dual-Release Builder v1.0                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Clean output directory
if (Test-Path $OutputDir) {
    Write-Host "`n🗑️  Cleaning old builds..." -ForegroundColor Gray
    Remove-Item -Path $OutputDir -Recurse -Force
}
New-Item -Path $DistPath -ItemType Directory -Force | Out-Null

# ═══════════════════════════════════════════════════════════════
# BUILD 1: STANDARD (CLEAN) RELEASE
# ═══════════════════════════════════════════════════════════════

Write-Host "`n📦 Building STANDARD release (clean, no extras)..." -ForegroundColor Green

# Store current branch
$currentBranch = git -C $Root rev-parse --abbrev-ref HEAD 2>$null
if (-not $currentBranch) { $currentBranch = "main" }

# Checkout main branch
Push-Location $Root
try {
    git checkout main -q 2>$null
}
catch {
    Write-Host "   Note: Could not switch to main branch (may already be on main or not committed)" -ForegroundColor Yellow
}
Pop-Location

$StandardPath = "$DistPath\Win-Debloat7-v$Version-Standard"
New-Item -Path $StandardPath -ItemType Directory -Force | Out-Null

# Copy files (exclude .git, build, dist, tests)
$Exclusions = @('.git*', '.vs*', '.vscode', 'dist', 'tests', '*.zip', '*.7z', '*.rar')

Write-Host "   Copying files..." -ForegroundColor Gray
Get-ChildItem -Path $Root -Exclude $Exclusions | Copy-Item -Destination $StandardPath -Recurse -Force

# Remove build folder from package (but keep essential scripts)
Remove-Item -Path "$StandardPath\build" -Recurse -Force -ErrorAction SilentlyContinue

# Create README for Standard
$StandardReadme = @"
# Win-Debloat7 v$Version - Standard Edition

## ✅ RECOMMENDED FOR MOST USERS

This is the **clean, safe version** of Win-Debloat7.

### What's included:
- ✅ Core debloating and optimization
- ✅ Privacy hardening
- ✅ Performance tweaks
- ✅ System snapshots and rollback
- ✅ GUI and CLI interfaces
- ✅ All YAML profiles

### What's NOT included:
- ❌ Microsoft Activation Scripts (MAS)
- ❌ Windows Defender Remover

### Why choose Standard?
- ✅ **No antivirus flags**
- ✅ **Fully supported**
- ✅ **Safe for enterprise use**
- ✅ **Winget/Chocolatey compatible**

## Installation

1. Extract the ZIP file
2. Open PowerShell 7.5+ as Administrator
3. Run: ``.\Win-Debloat7.ps1``

## Need Extras?
Advanced users who want MAS/Defender integration can download:
**Win-Debloat7-v$Version-Extras.zip** (separate download)

⚠️ **Warning:** Extras version includes risky tools and is NOT recommended.

## Documentation
https://github.com/tomytate/Win-Debloat7

---
**License:** MIT | **Author:** Tomy Tate | **Version:** $Version
"@

$StandardReadme | Set-Content "$StandardPath\README.md" -Encoding UTF8

# Create ZIP
Write-Host "   Creating ZIP archive..." -ForegroundColor Gray
$StandardZip = "$DistPath\Win-Debloat7-v$Version-Standard.zip"
Compress-Archive -Path "$StandardPath\*" -DestinationPath $StandardZip -CompressionLevel Optimal -Force

$StandardSize = [math]::Round((Get-Item $StandardZip).Length / 1MB, 2)
Write-Host "   ✅ Standard release built: ${StandardSize}MB" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# BUILD 2: EXTRAS RELEASE
# ═══════════════════════════════════════════════════════════════

Write-Host "`n📦 Building EXTRAS release (includes MAS/Defender)..." -ForegroundColor Yellow

# Check if extras branch exists
$extrasExists = git -C $Root branch --list extras 2>$null
if ($extrasExists) {
    Push-Location $Root
    git checkout extras -q 2>$null
    Pop-Location
    
    $ExtrasPath = "$DistPath\Win-Debloat7-v$Version-Extras"
    New-Item -Path $ExtrasPath -ItemType Directory -Force | Out-Null
    
    Write-Host "   Copying files from extras branch..." -ForegroundColor Gray
    Get-ChildItem -Path $Root -Exclude $Exclusions | Copy-Item -Destination $ExtrasPath -Recurse -Force
    Remove-Item -Path "$ExtrasPath\build" -Recurse -Force -ErrorAction SilentlyContinue
}
else {
    Write-Host "   ⚠️  Extras branch not found - creating placeholder..." -ForegroundColor Yellow
    $ExtrasPath = "$DistPath\Win-Debloat7-v$Version-Extras"
    New-Item -Path $ExtrasPath -ItemType Directory -Force | Out-Null
    
    # Copy standard files as base
    Get-ChildItem -Path $StandardPath | Copy-Item -Destination $ExtrasPath -Recurse -Force
    
    Write-Host "   Note: Create 'extras' branch with MAS/Defender module for full Extras build" -ForegroundColor Yellow
}

# Create WARNING README for Extras
$ExtrasReadme = @"
# Win-Debloat7 v$Version - Extras Edition

## ⚠️  WARNING: ADVANCED USERS ONLY

This version includes **RISKY EXTERNAL TOOLS** that are **NOT RECOMMENDED** for most users.

### 🚨 WHAT'S DIFFERENT FROM STANDARD?

This Extras edition includes integrations for:

1. **Windows Defender Remover** (by ionuttbara)
   - ❌ **PERMANENTLY removes Windows Defender**
   - ❌ **Cannot be undone** without reinstalling Windows
   - ❌ Leaves your system **UNPROTECTED** from malware

2. **Microsoft Activation Scripts (MAS)** (by massgravel)
   - ⚠️  Modifies Windows activation status
   - ⚠️  **May violate Microsoft's Terms of Service**
   - ⚠️  **Flagged by antivirus** as "Hacktool"

### ❌ RISKS OF USING EXTRAS:

- **Security:** Removing Defender leaves you vulnerable to malware
- **Legal:** Activation tools may violate Microsoft ToS
- **Antivirus:** Your AV **WILL flag** this package
- **Enterprise:** **NOT suitable** for corporate environments

### 🎯 RECOMMENDED: Use Standard Edition Instead

Download Standard here: https://github.com/tomytate/Win-Debloat7/releases

---

## IF YOU PROCEED:

1. Extract the ZIP file
2. Open PowerShell 7.5+ as Administrator
3. **Disable your antivirus temporarily** (it will block MAS)
4. Run: ``.\Win-Debloat7.ps1``
5. Menu options 9 (Defender Remover) and 0 (MAS) are available

## Disclaimer

**USE AT YOUR OWN RISK.** Win-Debloat7 is NOT responsible for any damage.

---
**License:** MIT | **Version:** $Version (Extras) | **Recommended:** Use Standard instead
"@

$ExtrasReadme | Set-Content "$ExtrasPath\README-EXTRAS.md" -Encoding UTF8

# Create ZIP
Write-Host "   Creating ZIP archive..." -ForegroundColor Gray
$ExtrasZip = "$DistPath\Win-Debloat7-v$Version-Extras.zip"
Compress-Archive -Path "$ExtrasPath\*" -DestinationPath $ExtrasZip -CompressionLevel Optimal -Force

$ExtrasSize = [math]::Round((Get-Item $ExtrasZip).Length / 1MB, 2)
Write-Host "   ✅ Extras release built: ${ExtrasSize}MB" -ForegroundColor Yellow

# ═══════════════════════════════════════════════════════════════
# GENERATE CHECKSUMS
# ═══════════════════════════════════════════════════════════════

Write-Host "`n🔐 Generating checksums..." -ForegroundColor Cyan

$checksums = @()
Get-ChildItem -Path $DistPath -Filter "*.zip" | ForEach-Object {
    $hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash
    $checksums += "$hash  $($_.Name)"
    Write-Host "   $($_.Name): $hash" -ForegroundColor Gray
}
$checksums | Set-Content "$DistPath\checksums.txt" -Encoding UTF8

# ═══════════════════════════════════════════════════════════════
# CREATE RELEASE NOTES
# ═══════════════════════════════════════════════════════════════

Write-Host "`n📝 Generating release notes..." -ForegroundColor Cyan

$ReleaseNotes = @"
# Win-Debloat7 v$Version

## 📦 Download Options

### ✅ STANDARD EDITION (RECOMMENDED)
**File:** ``Win-Debloat7-v$Version-Standard.zip`` (${StandardSize}MB)

- Full debloating and optimization
- Privacy hardening & performance tweaks
- GUI and CLI interfaces
- **No antivirus flags** | **Fully supported**

---

### ⚠️  EXTRAS EDITION (ADVANCED USERS ONLY)
**File:** ``Win-Debloat7-v$Version-Extras.zip`` (${ExtrasSize}MB)

- Includes Windows Defender Remover + MAS
- ❌ Will be flagged by antivirus
- ❌ May violate Microsoft ToS
- **Use at your own risk**

---

## 📋 Requirements

- Windows 10 22H2 or Windows 11
- PowerShell 7.5 or higher
- Administrator privileges

## 🔐 SHA256 Checksums
``````
$($checksums -join "`n")
``````
"@

$ReleaseNotes | Set-Content "$DistPath\RELEASE_NOTES.md" -Encoding UTF8

# ═══════════════════════════════════════════════════════════════
# SWITCH BACK TO ORIGINAL BRANCH
# ═══════════════════════════════════════════════════════════════

Push-Location $Root
try {
    git checkout $currentBranch -q 2>$null
}
catch {}
Pop-Location

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                      BUILD COMPLETE                          ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📦 Release Artifacts:" -ForegroundColor Cyan
Write-Host "   Standard: $StandardZip" -ForegroundColor White
Write-Host "   Size: ${StandardSize}MB" -ForegroundColor Gray
Write-Host "`n   Extras: $ExtrasZip" -ForegroundColor Yellow
Write-Host "   Size: ${ExtrasSize}MB" -ForegroundColor Gray

Write-Host "`n📝 Generated Files:" -ForegroundColor Cyan
Write-Host "   $DistPath\RELEASE_NOTES.md" -ForegroundColor Gray
Write-Host "   $DistPath\checksums.txt" -ForegroundColor Gray

Write-Host "`n🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Test both packages on a clean VM" -ForegroundColor Gray
Write-Host "   2. Create GitHub release" -ForegroundColor Gray
Write-Host "   3. Upload both ZIP files + checksums.txt" -ForegroundColor Gray
Write-Host "   4. Mark Standard as 'recommended' in release" -ForegroundColor Gray

Write-Host "`n✅ Build successful!" -ForegroundColor Green
