<#
.SYNOPSIS
    Registry tweaks module for Win-Debloat7.
    
.DESCRIPTION
    Provides granular registry modification functions for AI features, privacy,
    telemetry, and UI customization. Designed for both interactive and Sysprep
    (Default User hive) scenarios.
    
.NOTES
    Module: Win-Debloat7.Modules.Tweaks
    Version: 1.3.1
#>

#region AI Feature Tweaks

function Disable-WinDebloat7AIRecall {
    <#
    .SYNOPSIS
        Disables Windows AI Recall feature (screenshot history).
    
    .PARAMETER ApplyToDefaultUser
        If specified, applies to Default User hive for Sysprep scenarios.
    #>
    [CmdletBinding()]
    param(
        [switch]$ApplyToDefaultUser
    )

    $tweaks = @(
        @{
            Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
            Name  = "DisableAIDataAnalysis"
            Type  = "DWord"
            Value = 1
        },
        @{
            Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
            Name  = "AllowRecallEnablement"
            Type  = "DWord"
            Value = 0
        }
    )

    foreach ($tweak in $tweaks) {
        Set-WinDebloat7RegistryValue @tweak
    }

    if ($ApplyToDefaultUser -and (Test-Path "Registry::HKLM\WinDebloat7_Default")) {
        Set-WinDebloat7RegistryValue -Path "HKLM:\WinDebloat7_Default\Software\Policies\Microsoft\Windows\WindowsAI" `
            -Name "DisableAIDataAnalysis" -Type "DWord" -Value 1
    }

    Write-Log -Message "AI Recall disabled" -Level Success
}

function Disable-WinDebloat7Copilot {
    <#
    .SYNOPSIS
        Disables Windows Copilot taskbar button and service.
    
    .PARAMETER ApplyToDefaultUser
        If specified, applies to Default User hive for Sysprep scenarios.
    #>
    [CmdletBinding()]
    param(
        [switch]$ApplyToDefaultUser
    )

    # Machine-level policy
    Set-WinDebloat7RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" `
        -Name "TurnOffWindowsCopilot" -Type "DWord" -Value 1

    # Current user
    Set-WinDebloat7RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name "ShowCopilotButton" -Type "DWord" -Value 0
    Set-WinDebloat7RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" `
        -Name "TurnOffWindowsCopilot" -Type "DWord" -Value 1

    if ($ApplyToDefaultUser -and (Test-Path "Registry::HKLM\WinDebloat7_Default")) {
        Set-WinDebloat7RegistryValue -Path "HKLM:\WinDebloat7_Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            -Name "ShowCopilotButton" -Type "DWord" -Value 0
        Set-WinDebloat7RegistryValue -Path "HKLM:\WinDebloat7_Default\Software\Policies\Microsoft\Windows\WindowsCopilot" `
            -Name "TurnOffWindowsCopilot" -Type "DWord" -Value 1
    }

    Write-Log -Message "Copilot disabled" -Level Success
}

function Disable-WinDebloat7ClickToDo {
    <#
    .SYNOPSIS
        Disables Windows Click-to-Do AI feature.
    #>
    [CmdletBinding()]
    param(
        [switch]$ApplyToDefaultUser
    )

    Set-WinDebloat7RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name "ClickToDoEnabled" -Type "DWord" -Value 0

    if ($ApplyToDefaultUser -and (Test-Path "Registry::HKLM\WinDebloat7_Default")) {
        Set-WinDebloat7RegistryValue -Path "HKLM:\WinDebloat7_Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            -Name "ClickToDoEnabled" -Type "DWord" -Value 0
    }

    Write-Log -Message "Click-to-Do disabled" -Level Success
}

function Disable-WinDebloat7NotepadAI {
    <#
    .SYNOPSIS
        Disables AI features in Notepad (Cowriter).
    #>
    [CmdletBinding()]
    param(
        [switch]$ApplyToDefaultUser
    )

    Set-WinDebloat7RegistryValue -Path "HKCU:\Software\Microsoft\Notepad" `
        -Name "EnableAI" -Type "DWord" -Value 0

    if ($ApplyToDefaultUser -and (Test-Path "Registry::HKLM\WinDebloat7_Default")) {
        Set-WinDebloat7RegistryValue -Path "HKLM:\WinDebloat7_Default\Software\Microsoft\Notepad" `
            -Name "EnableAI" -Type "DWord" -Value 0
    }

    Write-Log -Message "Notepad AI disabled" -Level Success
}

function Disable-WinDebloat7PaintAI {
    <#
    .SYNOPSIS
        Disables AI features in Paint (Cocreator, Image Creator).
    #>
    [CmdletBinding()]
    param(
        [switch]$ApplyToDefaultUser
    )

    $regPath = "HKCU:\Software\Microsoft\Paint"
    Set-WinDebloat7RegistryValue -Path $regPath -Name "CocreatorEnabled" -Type "DWord" -Value 0
    Set-WinDebloat7RegistryValue -Path $regPath -Name "ImageCreatorEnabled" -Type "DWord" -Value 0
    Set-WinDebloat7RegistryValue -Path $regPath -Name "GenerativeFillEnabled" -Type "DWord" -Value 0
    Set-WinDebloat7RegistryValue -Path $regPath -Name "GenerativeEraseEnabled" -Type "DWord" -Value 0

    if ($ApplyToDefaultUser -and (Test-Path "Registry::HKLM\WinDebloat7_Default")) {
        $defaultPath = "HKLM:\WinDebloat7_Default\Software\Microsoft\Paint"
        Set-WinDebloat7RegistryValue -Path $defaultPath -Name "CocreatorEnabled" -Type "DWord" -Value 0
        Set-WinDebloat7RegistryValue -Path $defaultPath -Name "ImageCreatorEnabled" -Type "DWord" -Value 0
        Set-WinDebloat7RegistryValue -Path $defaultPath -Name "GenerativeFillEnabled" -Type "DWord" -Value 0
        Set-WinDebloat7RegistryValue -Path $defaultPath -Name "GenerativeEraseEnabled" -Type "DWord" -Value 0
    }

    Write-Log -Message "Paint AI features disabled" -Level Success
}

function Disable-WinDebloat7EdgeAI {
    <#
    .SYNOPSIS
        Disables AI features in Microsoft Edge.
    #>
    [CmdletBinding()]
    param()

    $edgePolicies = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    Set-WinDebloat7RegistryValue -Path $edgePolicies -Name "CopilotCDPPageContext" -Type "DWord" -Value 0
    Set-WinDebloat7RegistryValue -Path $edgePolicies -Name "DiscoverPageContextEnabled" -Type "DWord" -Value 0
    Set-WinDebloat7RegistryValue -Path $edgePolicies -Name "HubsSidebarEnabled" -Type "DWord" -Value 0

    Write-Log -Message "Edge AI features disabled" -Level Success
}

#endregion

#region Privacy Tweaks

function Disable-WinDebloat7DesktopSpotlight {
    <#
    .SYNOPSIS
        Disables Desktop Spotlight (rotating background images with ads).
    #>
    [CmdletBinding()]
    param(
        [switch]$ApplyToDefaultUser
    )

    Set-WinDebloat7RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" `
        -Name "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" -Type "DWord" -Value 1
    Set-WinDebloat7RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
        -Name "EnableLightThemeForConnectedStandby" -Type "DWord" -Value 0

    if ($ApplyToDefaultUser -and (Test-Path "Registry::HKLM\WinDebloat7_Default")) {
        Set-WinDebloat7RegistryValue -Path "HKLM:\WinDebloat7_Default\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" `
            -Name "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" -Type "DWord" -Value 1
    }

    Write-Log -Message "Desktop Spotlight disabled" -Level Success
}

function Disable-WinDebloat7Settings365Ads {
    <#
    .SYNOPSIS
        Disables Microsoft 365 ads in Windows Settings.
    #>
    [CmdletBinding()]
    param(
        [switch]$ApplyToDefaultUser
    )

    Set-WinDebloat7RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name "ShowSyncProviderNotifications" -Type "DWord" -Value 0

    if ($ApplyToDefaultUser -and (Test-Path "Registry::HKLM\WinDebloat7_Default")) {
        Set-WinDebloat7RegistryValue -Path "HKLM:\WinDebloat7_Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            -Name "ShowSyncProviderNotifications" -Type "DWord" -Value 0
    }

    Write-Log -Message "Settings 365 ads disabled" -Level Success
}

#endregion

#region Power & Performance Tweaks

function Enable-WinDebloat7UltimatePower {
    <#
    .SYNOPSIS
        Enables and activates the Ultimate Performance power plan.
        
    .DESCRIPTION
        Duplicates the hidden Ultimate Performance power scheme and sets it as active.
        Source: winutil (ChrisTitusTech)
    #>
    [CmdletBinding()]
    param()

    try {
        $ultimateGUID = "e9a42b02-d5df-448d-aa00-03f14749eb61"
        
        # Check if already exists
        $existingPlan = powercfg -list | Select-String -Pattern "Win-Debloat7 Ultimate"
        if ($existingPlan) {
            Write-Log -Message "Ultimate Performance plan already installed" -Level Info
            return
        }

        # Duplicate the Ultimate Performance power plan
        $duplicateOutput = powercfg /duplicatescheme $ultimateGUID 2>&1

        $guid = $null
        foreach ($line in $duplicateOutput) {
            if ($line -match '\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b') {
                $guid = $matches[0]
                break
            }
        }

        if (-not $guid) {
            Write-Log -Message "Failed to create Ultimate Performance plan - GUID not found" -Level Error
            return
        }

        # Rename the plan
        Start-Process -FilePath "powercfg.exe" -ArgumentList "/changename", "$guid", "`"Win-Debloat7 Ultimate`"", "`"Ultimate Performance plan`"" -Wait -NoNewWindow

        # Set as active
        Start-Process -FilePath "powercfg.exe" -ArgumentList "/setactive", "$guid" -Wait -NoNewWindow

        Write-Log -Message "Ultimate Performance plan installed and activated" -Level Success
    }
    catch {
        Write-Log -Message "Error enabling Ultimate Power: $($_.Exception.Message)" -Level Error
    }
}

function Disable-WinDebloat7UltimatePower {
    <#
    .SYNOPSIS
        Removes the Ultimate Performance power plan and reverts to Balanced.
    #>
    [CmdletBinding()]
    param()

    try {
        $installedPlan = powercfg -list | Select-String -Pattern "Win-Debloat7 Ultimate"
        
        if ($installedPlan) {
            $ultimatePlanGUID = ($installedPlan -split '\s+')[3]
            
            # Revert to Balanced
            $balancedGUID = "381b4222-f694-41f0-9685-ff5bb260df2e"
            Start-Process -FilePath "powercfg.exe" -ArgumentList "/setactive", "$balancedGUID" -Wait -NoNewWindow
            
            # Delete Ultimate plan
            Start-Process -FilePath "powercfg.exe" -ArgumentList "/delete", "$ultimatePlanGUID" -Wait -NoNewWindow
            
            Write-Log -Message "Ultimate Performance plan uninstalled, Balanced active" -Level Success
        }
        else {
            Write-Log -Message "Ultimate Performance plan not found" -Level Info
        }
    }
    catch {
        Write-Log -Message "Error disabling Ultimate Power: $($_.Exception.Message)" -Level Error
    }
}

#endregion

#region Sysprep Batch Apply

function Invoke-WinDebloat7SysprepDefaults {
    <#
    .SYNOPSIS
        Applies all Sysprep-compatible tweaks to the Default User hive.
        
    .DESCRIPTION
        Mounts the Default User registry hive and applies all AI, privacy,
        and UI tweaks for OEM image deployment.
    #>
    [CmdletBinding()]
    param()

    # Verify we're in Sysprep/Audit mode or user confirmed
    if (-not (Test-WinDebloat7Sysprep)) {
        Write-Log -Message "Warning: Not in Audit Mode. Tweaks will apply to Default User anyway." -Level Warning
    }

    # Mount Default User hive
    if (-not (Mount-WinDebloat7DefaultHive)) {
        Write-Log -Message "Failed to mount Default User hive" -Level Error
        return
    }

    try {
        Write-Log -Message "Applying Sysprep defaults to Default User..." -Level Info
        
        # Apply all AI tweaks
        Disable-WinDebloat7AIRecall -ApplyToDefaultUser
        Disable-WinDebloat7Copilot -ApplyToDefaultUser
        Disable-WinDebloat7ClickToDo -ApplyToDefaultUser
        Disable-WinDebloat7NotepadAI -ApplyToDefaultUser
        Disable-WinDebloat7PaintAI -ApplyToDefaultUser
        
        # Apply privacy tweaks
        Disable-WinDebloat7DesktopSpotlight -ApplyToDefaultUser
        Disable-WinDebloat7Settings365Ads -ApplyToDefaultUser
        
        Write-Log -Message "Sysprep defaults applied successfully" -Level Success
    }
    finally {
        Dismount-WinDebloat7DefaultHive
    }
}

#endregion

#region Helper Functions

function Set-WinDebloat7RegistryValue {
    <#
    .SYNOPSIS
        Sets a registry value, creating the key path if it doesn't exist.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [string]$Type,
        
        [Parameter(Mandatory)]
        $Value
    )

    if (-not $PSCmdlet.ShouldProcess("$Path\$Name", "Set value to $Value")) {
        return
    }

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
        Write-Verbose "Set $Path\$Name = $Value"
    }
    catch {
        Write-Log -Message "Failed to set registry: $Path\$Name - $($_.Exception.Message)" -Level Warning
    }
}

#endregion

Export-ModuleMember -Function @(
    # AI Tweaks
    'Disable-WinDebloat7AIRecall',
    'Disable-WinDebloat7Copilot',
    'Disable-WinDebloat7ClickToDo',
    'Disable-WinDebloat7NotepadAI',
    'Disable-WinDebloat7PaintAI',
    'Disable-WinDebloat7EdgeAI',
    # Privacy Tweaks
    'Disable-WinDebloat7DesktopSpotlight',
    'Disable-WinDebloat7Settings365Ads',
    # Power Tweaks
    'Enable-WinDebloat7UltimatePower',
    'Disable-WinDebloat7UltimatePower',
    # Sysprep
    'Invoke-WinDebloat7SysprepDefaults',
    # Helper
    'Set-WinDebloat7RegistryValue'
)
