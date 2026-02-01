<#
.SYNOPSIS
    Privacy optimization module for Win-Debloat7
    
.DESCRIPTION
    Manages Windows privacy settings, telemetry, and data collection.
    Uses PowerShell 7.5 best practices with proper error handling.
    
.NOTES
    Module: Win-Debloat7.Modules.Privacy
    Version: 1.2.5
    
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
    if ($Config.privacy.disable_copilot) {
        $currentStep++
        Write-Progress -Activity "Applying Privacy Settings" -Status "Disabling AI & Copilot" -PercentComplete (($currentStep / $totalSteps) * 100)
        Write-Log -Message "Disabling AI & Copilot features" -Level Info
        
        $copilotKeys = @(
            @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"; Name = "TurnOffWindowsCopilot"; Value = 1 }
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"; Name = "TurnOffWindowsCopilot"; Value = 1 }
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowCopilotButton"; Value = 0 }
            # Edge AI
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "HubsSidebarEnabled"; Value = 0 }
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "CopilotCDPPageContext"; Value = 0 }
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "ComposeInlineEnabled"; Value = 0 }
        )
        
        foreach ($item in $copilotKeys) {
            if (Set-RegistryKey -Path $item.Path -Name $item.Name -Value $item.Value) {
                $successCount++
            }
            else {
                $failCount++
                Write-Log -Message "Failed to set AI key: $($item.Path)" -Level Warning
            }
        }
    }
    
    if ($Config.privacy.disable_recall) {
        Write-Log -Message "Disabling Windows Recall (AI Analysis)" -Level Info
        
        $aiKeys = @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "DisableAIDataAnalysis"; Value = 1 }
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "AllowRecallEnablement"; Value = 0 }
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "TurnOffSavingSnapshots"; Value = 1 }
        )
        foreach ($item in $aiKeys) {
            if (Set-RegistryKey -Path $item.Path -Name $item.Name -Value $item.Value) {
                $successCount++
            }
        }
    }
    
    Write-Progress -Activity "Applying Privacy Settings" -Completed
    
    # Summary
    Write-Log -Message "Privacy settings applied: $successCount succeeded, $failCount failed" -Level $(if ($failCount -eq 0) { "Success" } else { "Warning" })
}

<#
.SYNOPSIS
    Disables Windows 11 AI features (Copilot, Recall) and Ads.
    (Moved from Bloatware module for cohesion)
#>
function Disable-WinDebloat7AIandAds {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-Log -Message "Disabling Windows 11 AI & Ads..." -Level Info
    
    if ($PSCmdlet.ShouldProcess("Windows AI", "Disable Copilot, Recall, Ads")) {
        
        # We leverage the logic we just centralized, or repeat specific keys?
        # Repeating specific keys for standalone execution is safer to avoid Config dependency.
        
        $keys = @(
            # Copilot
            @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"; Name = "TurnOffWindowsCopilot"; Value = 1; Type = "DWord" }
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"; Name = "TurnOffWindowsCopilot"; Value = 1; Type = "DWord" }
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowCopilotButton"; Value = 0; Type = "DWord" }
            
            # Recall
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "DisableAIDataAnalysis"; Value = 1; Type = "DWord" }
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "AllowRecallEnablement"; Value = 0; Type = "DWord" }
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "TurnOffSavingSnapshots"; Value = 1; Type = "DWord" }
            
            # Edge AI
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "HubsSidebarEnabled"; Value = 0; Type = "DWord" }
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "CopilotCDPPageContext"; Value = 0; Type = "DWord" }
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "ComposeInlineEnabled"; Value = 0; Type = "DWord" }
            
            # Start Menu Ads
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableWindowsConsumerFeatures"; Value = 1; Type = "DWord" }
        )
        
        foreach ($k in $keys) {
            Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Type $k.Type
        }
        
        
        # 5. Disable AI Services (25H2+)
        if (Get-Service "AIFabric*" -ErrorAction SilentlyContinue) {
            try {
                Stop-Service -Name "AIFabric*" -Force -ErrorAction Stop
                Set-Service -Name "AIFabric*" -StartupType Disabled -ErrorAction Stop
                Write-Log -Message "AI Fabric Service disabled." -Level Success
            }
            catch {
                Write-Log -Message "Could not disable AI Fabric: $($_.Exception.Message)" -Level Warning
            }
        }

        Write-Log -Message "AI and Ads features disabled." -Level Success
    }
}

Export-ModuleMember -Function Set-WinDebloat7Privacy, Disable-WinDebloat7AIandAds
