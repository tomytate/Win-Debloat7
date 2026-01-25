<#
.SYNOPSIS
    Performance optimization module for Win-Debloat7
    
.DESCRIPTION
    Manages power plans, visual effects, and system responsiveness settings.
    Uses PowerShell 7.5 best practices with named constants and proper error handling.
    
.NOTES
    Module: Win-Debloat7.Modules.Performance
    Version: 1.2.0
    
.LINK
    https://learn.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-75
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force
Import-Module "$PSScriptRoot\..\..\core\Registry.psm1" -Force

#region Constants (CQ-006 fix: Named constants instead of magic GUIDs)
$Script:PowerPlanGUIDs = @{
    Balanced        = '381b4222-f694-41f0-9685-ff5bb260df2e'
    HighPerformance = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    Ultimate        = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
    PowerSaver      = 'a1841308-3541-4fab-bc81-f71556f20b4a'
}
#endregion

<#
.SYNOPSIS
    Applies performance settings based on configuration profile.
    
.DESCRIPTION
    Configures Windows performance settings including power plans,
    visual effects, Game Bar, and background apps.
    
.PARAMETER Config
    The configuration object loaded from a YAML profile.
    
.OUTPUTS
    [void]
    
.EXAMPLE
    Set-WinDebloat7Performance -Config $config
#>
function Set-WinDebloat7Performance {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [psobject]$Config
    )
    
    # Validate config has performance section
    if (-not $Config.performance) {
        Write-Log -Message "No performance configuration found in profile." -Level Warning
        return
    }
    
    $plan = $Config.performance.power_plan
    Write-Log -Message "Applying Performance Settings (Plan: $plan)" -Level Info
    
    $successCount = 0
    $failCount = 0
    $totalSteps = 5
    $currentStep = 0
    
    # 1. Power Plans (using named constants)
    $currentStep++
    Write-Progress -Activity "Applying Performance Settings" -Status "Configuring Power Plan: $plan" -PercentComplete (($currentStep / $totalSteps) * 100)
    try {
        switch ($plan) {
            "HighPerformance" {
                $guid = $Script:PowerPlanGUIDs.HighPerformance
                if ($PSCmdlet.ShouldProcess("Power Plan", "Set to High Performance")) {
                    $result = powercfg -SetActive $guid 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Log -Message "Power Plan set to High Performance" -Level Success
                        $successCount++
                    }
                    else {
                        Write-Log -Message "Failed to set power plan: $result" -Level Error
                        $failCount++
                    }
                }
            }
            "Ultimate" {
                $guid = $Script:PowerPlanGUIDs.Ultimate
                if ($PSCmdlet.ShouldProcess("Power Plan", "Set to Ultimate Performance")) {
                    # Duplicate Ultimate Performance scheme if not exists
                    $existingPlans = powercfg -list 2>&1
                    if ($existingPlans -notmatch $guid) {
                        powercfg -DuplicateScheme $guid 2>&1 | Out-Null
                    }
                    $result = powercfg -SetActive $guid 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Log -Message "Power Plan set to Ultimate Performance" -Level Success
                        $successCount++
                    }
                    else {
                        Write-Log -Message "Failed to set power plan: $result" -Level Error
                        $failCount++
                    }
                }
            }
            "Balanced" {
                $guid = $Script:PowerPlanGUIDs.Balanced
                if ($PSCmdlet.ShouldProcess("Power Plan", "Set to Balanced")) {
                    powercfg -SetActive $guid 2>&1 | Out-Null
                    Write-Log -Message "Power Plan set to Balanced" -Level Success
                    $successCount++
                }
            }
            default {
                Write-Log -Message "Unknown power plan: $plan" -Level Warning
            }
        }
    }
    catch {
        Write-Log -Message "Power plan configuration failed: $($_.Exception.Message)" -Level Error
        $failCount++
    }
    
    # 2. Visual Effects (Registry) & Responsiveness
    if ($Config.performance.visual_effects -eq "Performance") {
        $currentStep++
        Write-Progress -Activity "Applying Performance Settings" -Status "Optimizing Visual Effects & Responsiveness" -PercentComplete (($currentStep / $totalSteps) * 100)
        Write-Log -Message "Optimizing Visual Effects for Performance" -Level Info
        
        $results = @(
            # Reduce Menu Delay
            (Set-RegistryKey -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Type String),
            # Disable Animation
            (Set-RegistryKey -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Type String),
            # Reduce Mouse Hover Time
            (Set-RegistryKey -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -Value "10" -Type String),
            # Kill Hung Apps Faster
            (Set-RegistryKey -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Value "1000" -Type String),
            (Set-RegistryKey -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Value "2000" -Type String)
        )
        
        $successCount += ($results | Where-Object { $_ }).Count
        $failCount += ($results | Where-Object { -not $_ }).Count
    }
    
    # 3. RAM Optimization (Service Host Split)
    $ramGB = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    if ($ramGB -gt 4) {
        # Set Split Threshold to RAM size to reduce process overhead on modern systems
        $ramKB = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1KB
        if (Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Value $ramKB -Type DWord) {
            $successCount++
            Write-Log -Message "Optimized Service Host Split Threshold" -Level Success
        }
    }
    
    # 3. Game Mode & DVR
    if ($Config.performance.disable_game_bar) {
        $currentStep++
        Write-Progress -Activity "Applying Performance Settings" -Status "Disabling Game Bar" -PercentComplete (($currentStep / $totalSteps) * 100)
        Write-Log -Message "Disabling Game Bar" -Level Info
        
        $results = @(
            (Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0),
            (Set-RegistryKey -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0)
        )
        
        $successCount += ($results | Where-Object { $_ }).Count
        $failCount += ($results | Where-Object { -not $_ }).Count
    }
    
    # 4. Background Apps
    if ($Config.performance.disable_background_apps) {
        $currentStep++
        Write-Progress -Activity "Applying Performance Settings" -Status "Disabling Background Apps" -PercentComplete (($currentStep / $totalSteps) * 100)
        Write-Log -Message "Disabling Background Apps" -Level Info
        
        $results = @(
            (Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1),
            (Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsRunInBackground" -Value 2)
        )
        
        $successCount += ($results | Where-Object { $_ }).Count
        $failCount += ($results | Where-Object { -not $_ }).Count
    }
    
    # 5. Network Throttling
    $currentStep++
    Write-Progress -Activity "Applying Performance Settings" -Status "Disabling Network Throttling" -PercentComplete (($currentStep / $totalSteps) * 100)
    Write-Log -Message "Disabling Network Throttling" -Level Info
    if (Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff) {
        $successCount++
    }
    else {
        $failCount++
    }
    
    Write-Progress -Activity "Applying Performance Settings" -Completed
    
    # Summary
    Write-Log -Message "Performance settings applied: $successCount succeeded, $failCount failed" -Level $(if ($failCount -eq 0) { "Success" } else { "Warning" })
}

Export-ModuleMember -Function Set-WinDebloat7Performance
