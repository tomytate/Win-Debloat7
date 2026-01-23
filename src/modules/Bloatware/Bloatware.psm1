<#
.SYNOPSIS
    Bloatware management module for Win-Debloat7
    
.DESCRIPTION
    Handles identification and removal of pre-installed Windows apps (UWP).
    Uses PowerShell 7.5 best practices with proper error handling.
    
.NOTES
    Module: Win-Debloat7.Modules.Bloatware
    Version: 1.1.0
    
.LINK
    https://learn.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-75
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

using namespace System.Management.Automation
using namespace System.Collections.Generic

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force

#region Bloatware Definitions
$Script:BloatwareApps = @(
    # Microsoft Core Bloat
    "Microsoft.3DBuilder", "Microsoft.BingFinance", "Microsoft.BingNews", "Microsoft.BingSports", 
    "Microsoft.BingWeather", "Microsoft.GetHelp", "Microsoft.Getstarted", "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub", "Microsoft.MicrosoftSolitaireCollection", "Microsoft.MixedReality.Portal",
    "Microsoft.OneConnect", "Microsoft.People", "Microsoft.PowerAutomateDesktop", "Microsoft.Print3D",
    "Microsoft.SkypeApp", "Microsoft.Todos", "Microsoft.WindowsAlarms", "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps", "Microsoft.WindowsSoundRecorder", "Microsoft.XboxApp", "Microsoft.YourPhone",
    "Microsoft.ZuneMusic", "Microsoft.ZuneVideo",
    
    # 25H2 / Newer Bloat
    "Microsoft.Copilot", "MicrosoftWindows.Client.CoPilot", "MicrosoftWindows.Client.WebExperience", 
    "Microsoft.OutlookForWindows", "Microsoft.Windows.DevHome", "Clipchamp.Clipchamp",
    
    # Third Party
    "Disney", "SpotifyAB.SpotifyMusic", "PandoraMedia", "AmazonVideo.PrimeVideo", "Netflix",
    "Facebook", "Instagram", "Twitter", "TikTok", "CandyCrush", "BubbleWitch", "FarmVille"
)
#endregion

<#
.SYNOPSIS
    Gets the list of bloatware apps that can be removed.
    
.OUTPUTS
    [string[]] Array of app package names.
#>
function Get-WinDebloat7BloatwareList {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()
    
    return $Script:BloatwareApps
}

<#
.SYNOPSIS
    Removes bloatware applications based on configuration.
    
.DESCRIPTION
    Removes UWP apps from the current user and all users,
    plus removes provisioned packages to prevent reinstallation.
    
.PARAMETER Config
    The configuration object loaded from a YAML profile.
    
.OUTPUTS
    [void]
    
.EXAMPLE
    Remove-WinDebloat7Bloatware -Config $config
#>
function Remove-WinDebloat7Bloatware {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [psobject]$Config
    )
    
    # Validate config has bloatware section
    if (-not $Config.bloatware) {
        Write-Log -Message "No bloatware configuration found in profile." -Level Warning
        return
    }
    
    $removalMode = $Config.bloatware.removal_mode
    $excludeList = $Config.bloatware.exclude_list ?? @()
    
    Write-Log -Message "Starting Bloatware Removal (Mode: $removalMode)" -Level Info
    
    if ($removalMode -eq "None") {
        Write-Log -Message "Removal Mode is None. Skipping." -Level Warning
        return
    }

    # Performance: Fetch all packages ONCE instead of loop-by-loop (already optimized)
    Write-Log -Message "Scanning installed packages (this may take a moment)..." -Level Info
    
    try {
        $currentPackages = Get-AppxPackage -AllUsers -ErrorAction Stop
        $provisionedPackages = Get-AppxProvisionedPackage -Online -ErrorAction Stop
    }
    catch {
        Write-Log -Message "Failed to enumerate packages: $($_.Exception.Message)" -Level Error
        return
    }
    
    # Track results
    $successCount = 0
    $failCount = 0
    $skippedCount = 0
    
    # Determine which apps to target (custom_list or built-in)
    $targetApps = if ($Config.bloatware.custom_list -and $Config.bloatware.custom_list.Count -gt 0) {
        Write-Log -Message "Using custom bloatware list from profile ($($Config.bloatware.custom_list.Count) apps)" -Level Info
        $Config.bloatware.custom_list
    }
    else {
        $Script:BloatwareApps
    }
    
    $total = $targetApps.Count
    $current = 0
    
    # Build regex pattern for matching (PERF-003 fix: Pre-build pattern)
    $excludePattern = if ($excludeList.Count -gt 0) {
        ($excludeList | ForEach-Object { [regex]::Escape($_) }) -join '|'
    }
    else { $null }
    
    # Process List
    foreach ($targetApp in $targetApps) {
        $current++
        $percentComplete = [math]::Round(($current / $total) * 100)
        Write-Progress -Activity "Removing Bloatware" -Status "Processing $targetApp" -PercentComplete $percentComplete
        
        # Check Exclusions
        if ($excludePattern -and $targetApp -match $excludePattern) {
            Write-Log -Message "Skipping preserved app: $targetApp" -Level Info
            $skippedCount++
            continue
        }
        
        # Alternative: Check array membership for exact matches
        if ($excludeList -contains $targetApp) {
            Write-Log -Message "Skipping preserved app: $targetApp" -Level Info
            $skippedCount++
            continue
        }
        
        # Check if installed (In-Memory Filter)
        $matchesInstalled = $currentPackages | Where-Object { $_.Name -like "*$targetApp*" }
        $matchesProvisioned = $provisionedPackages | Where-Object { $_.DisplayName -like "*$targetApp*" }
        
        if ($matchesInstalled -or $matchesProvisioned) {
            if ($PSCmdlet.ShouldProcess($targetApp, "Remove")) {
                Write-Log -Message "Removing: $targetApp" -Level Info
                
                # Remove Installed Package (SEC-003 fix: Proper error handling)
                if ($matchesInstalled) {
                    try {
                        $matchesInstalled | Remove-AppxPackage -AllUsers -ErrorAction Stop
                    }
                    catch {
                        Write-Log -Message "Failed to remove installed package '$targetApp': $($_.Exception.Message)" -Level Warning
                        $failCount++
                        continue
                    }
                }
                    
                # Remove Provisioned Package
                if ($matchesProvisioned) {
                    try {
                        $matchesProvisioned | Remove-AppxProvisionedPackage -Online -AllUsers -ErrorAction Stop
                    }
                    catch {
                        # Non-fatal for provisioned - may already be removed
                        Write-Log -Message "Could not remove provisioned '$targetApp': $($_.Exception.Message)" -Level Debug
                    }
                }
                    
                Write-Log -Message "Removed: $targetApp" -Level Success
                $successCount++
            }
        }
    }
    
    Write-Progress -Activity "Removing Bloatware" -Completed
    
    # Summary
    Write-Log -Message "Bloatware removal complete: $successCount removed, $skippedCount preserved, $failCount failed" -Level $(if ($failCount -eq 0) { "Success" } else { "Warning" })
}

Export-ModuleMember -Function Get-WinDebloat7BloatwareList, Remove-WinDebloat7Bloatware
