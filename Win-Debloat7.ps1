#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Win-Debloat7 - The Power User's Windows Optimization Platform
    
.DESCRIPTION
    Entry point for the Win-Debloat7 framework.
    Loads core modules and launches the interactive TUI or applies profiles in CLI mode.
    
.PARAMETER ProfileFile
    Path to a YAML profile to apply. When specified, skips the interactive menu.
    
.PARAMETER Unattended
    Suppresses confirmation prompts. Use with -ProfileFile for automation.
    
.PARAMETER Verbose
    Enables verbose output for debugging.
    
.EXAMPLE
    ./Win-Debloat7.ps1
    Launches the interactive menu.
    
.EXAMPLE
    ./Win-Debloat7.ps1 -ProfileFile profiles/gaming.yaml
    Applies the gaming profile with confirmation prompts.
    
.EXAMPLE
    ./Win-Debloat7.ps1 -ProfileFile profiles/moderate.yaml -Unattended
    Applies the moderate profile without prompts (for automation).
    
.NOTES
    Version: 1.1.0
    Author: Tomy Tolledo
    License: MIT
    Requires: PowerShell 7.5+, Administrator privileges
    
.LINK
    https://github.com/tomytate/Win-Debloat7
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$ProfileFile,
    
    [switch]$Unattended,
    
    [switch]$NoGui
)

$scriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent

# Load Core Framework
try {
    Write-Host "Initializing Win-Debloat7 Premium Framework..." -ForegroundColor Cyan
    
    # Load the manifest which defines all nested modules and exports
    $manifestPath = Join-Path $scriptPath "Win-Debloat7.psd1"
    
    if (-not (Test-Path $manifestPath)) {
        throw "Module manifest not found at $manifestPath"
    }
    
    Import-Module $manifestPath -Force -ErrorAction Stop
    
    Start-WD7Logging
    Write-Log -Message "Win-Debloat7 initialized successfully." -Level Success
}
catch {
    Write-Host "CRITICAL ERROR: Failed to load framework." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# The manifest already loads UI modules, but we keep this block for safety if needed
# or we can remove it since Menu.psm1 is loaded by the manifest
Write-Host "Framework loaded." -ForegroundColor Gray

# Launch Application
if ($ProfileFile) {
    # CLI Mode
    # Modules are already loaded by the manifest
    Write-Log -Message "CLI Mode: Processing profile $ProfileFile" -Level Info
    
    $config = Import-WinDebloat7Config -Path $ProfileFile
    
    # Safety confirmation (unless -Unattended)
    if (-not $Unattended) {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║  WARNING: This will modify your system configuration.    ║" -ForegroundColor Yellow
        Write-Host "║  Profile: $($config.metadata.name.PadRight(43))║" -ForegroundColor Yellow
        Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
        
        $confirm = Read-Host "Continue? [Y/N]"
        if ($confirm -notmatch '^[Yy]') {
            Write-Log -Message "Operation cancelled by user." -Level Warning
            exit 0
        }
        
        # Create snapshot before changes
        Write-Log -Message "Creating pre-optimization snapshot..." -Level Info
        New-WinDebloat7Snapshot -Name "Pre-$($config.metadata.name)" -Description "Auto-created before $($config.metadata.name) profile"
    }
    else {
        Write-Log -Message "Unattended mode - skipping confirmation" -Level Info
    }
    
    # Apply modules
    Remove-WinDebloat7Bloatware -Config $config -Confirm:$false
    Set-WinDebloat7Privacy -Config $config -Confirm:$false
    Set-WinDebloat7Performance -Config $config -Confirm:$false
    
    Write-Log -Message "Profile '$($config.metadata.name)' applied successfully." -Level Success
    exit 0
}
else {
    # Interactive Mode (TUI Menu by default)
    # User can press 2 to launch Premium GUI
    Show-MainMenu
}

