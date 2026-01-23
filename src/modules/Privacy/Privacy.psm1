<#
.SYNOPSIS
    Privacy optimization module for Win-Debloat7
    
.DESCRIPTION
    Manages Windows privacy settings, telemetry, and data collection.
    Uses PowerShell 7.5 best practices with proper error handling.
    
.NOTES
    Module: Win-Debloat7.Modules.Privacy
    Version: 1.1.0
    
.LINK
    https://learn.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-75
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force
Import-Module "$PSScriptRoot\..\..\core\Registry.psm1" -Force

<#
.SYNOPSIS
    Applies privacy settings based on configuration profile.
    
.DESCRIPTION
    Configures Windows privacy settings including telemetry levels,
    advertising ID, activity history, location tracking, Copilot, and Recall.
    
.PARAMETER Config
    The configuration object loaded from a YAML profile.
    
.OUTPUTS
    [void]
    
.EXAMPLE
    Set-WinDebloat7Privacy -Config $config
#>
function Set-WinDebloat7Privacy {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [psobject]$Config
    )
    
    # Validate config has privacy section
    if (-not $Config.privacy) {
        Write-Log -Message "No privacy configuration found in profile." -Level Warning
        return
    }
    
    $level = $Config.privacy.telemetry_level
    Write-Log -Message "Applying Privacy Settings (Level: $level)" -Level Info
    
    $successCount = 0
    $failCount = 0
    $totalSteps = 5
    $currentStep = 0
    
    # 1. Advertising ID
    if ($Config.privacy.disable_advertising_id) {
        $currentStep++
        Write-Progress -Activity "Applying Privacy Settings" -Status "Disabling Advertising ID" -PercentComplete (($currentStep / $totalSteps) * 100)
        Write-Log -Message "Disabling Advertising ID" -Level Info
        
        $results = @(
            (Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0),
            (Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Value 1),
            (Set-RegistryKey -Path "HKCU:\Control Panel\International\User Profile" -Name "HttpAcceptLanguageOptOut" -Value 1)
        )
        
        $successCount += ($results | Where-Object { $_ }).Count
        $failCount += ($results | Where-Object { -not $_ }).Count
    }
    
    # 2. Activity History
    if ($Config.privacy.disable_activity_history) {
        $currentStep++
        Write-Progress -Activity "Applying Privacy Settings" -Status "Disabling Activity History" -PercentComplete (($currentStep / $totalSteps) * 100)
        Write-Log -Message "Disabling Activity History" -Level Info
        
        $results = @(
            (Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0),
            (Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0)
        )
        
        $successCount += ($results | Where-Object { $_ }).Count
        $failCount += ($results | Where-Object { -not $_ }).Count
    }
    
    # 3. Telemetry
    if ($level -eq "Security" -or $level -eq "Basic") {
        $currentStep++
        Write-Progress -Activity "Applying Privacy Settings" -Status "Restricting Telemetry to $level" -PercentComplete (($currentStep / $totalSteps) * 100)
        Write-Log -Message "Restricting Telemetry to '$level'" -Level Info
        # AllowTelemetry: 0 = Security, 1 = Basic, 3 = Full
        [int]$telemetryVal = if ($level -eq "Security") { 0 } else { 1 }
        
        $results = @(
            (Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value $telemetryVal),
            (Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value $telemetryVal)
        )
        
        $successCount += ($results | Where-Object { $_ }).Count
        $failCount += ($results | Where-Object { -not $_ }).Count
        
        # Disable DiagTrack service with proper error handling
        try {
            if ($PSCmdlet.ShouldProcess("DiagTrack", "Disable and Stop Service")) {
                Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction Stop
                Stop-Service -Name "DiagTrack" -Force -ErrorAction Stop
                Write-Log -Message "DiagTrack service disabled and stopped" -Level Success
                $successCount++
            }
        }
        catch {
            Write-Log -Message "Failed to disable DiagTrack: $($_.Exception.Message)" -Level Error
            $failCount++
        }
        
        # Disable Telemetry Tasks (Added in v1.1.0)
        try {
            Write-Log -Message "Disabling Telemetry Scheduled Tasks (Safe Mode)" -Level Info
            Disable-WinDebloat7TelemetryTasks -Mode Safe
            $successCount++
        }
        catch {
            Write-Log -Message "Failed to disable telemetry tasks: $($_.Exception.Message)" -Level Warning
        }
    }
    
    # 4. Location Tracking
    if ($Config.privacy.disable_location_tracking) {
        Write-Log -Message "Disabling Location Tracking" -Level Info
        
        if (Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Type String) {
            $successCount++
        }
        else {
            $failCount++
        }
    }
    
    # 5. Copilot & Recall (25H2 Readiness)
    # 5. Copilot & Recall (25H2 Readiness)
    if ($Config.privacy.disable_copilot) {
        $currentStep++
        Write-Progress -Activity "Applying Privacy Settings" -Status "Disabling Windows Copilot (HKCU + HKLM)" -PercentComplete (($currentStep / $totalSteps) * 100)
        Write-Log -Message "Disabling Windows Copilot (HKCU + HKLM)" -Level Info
        
        $copilotKeys = @(
            "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
        )
        
        foreach ($key in $copilotKeys) {
            # Ensure key exists
            if (-not (Test-Path $key)) {
                New-Item -Path $key -Force -ErrorAction SilentlyContinue | Out-Null
            }
            if (Set-RegistryKey -Path $key -Name "TurnOffWindowsCopilot" -Value 1) {
                $successCount++
            }
            else {
                $failCount++
                Write-Log -Message "Failed to disable Copilot in $key" -Level Warning
            }
        }
    }
    
    if ($Config.privacy.disable_recall) {
        Write-Log -Message "Disabling Windows Recall (AI Analysis)" -Level Info
        
        if (Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1) {
            $successCount++
        }
        else {
            $failCount++
        }
    }
    
    Write-Progress -Activity "Applying Privacy Settings" -Completed
    
    # Summary
    Write-Log -Message "Privacy settings applied: $successCount succeeded, $failCount failed" -Level $(if ($failCount -eq 0) { "Success" } else { "Warning" })
}

Export-ModuleMember -Function Set-WinDebloat7Privacy
