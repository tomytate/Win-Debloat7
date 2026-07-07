<#
.SYNOPSIS
    System behavior & QoL tweaks module for Win-Debloat7.

.DESCRIPTION
    Quality-of-life and system-behavior tweaks: Fast Startup, BitLocker
    auto-encryption, Delivery Optimization, Storage Sense, update behavior,
    Windows suggestion/ad surfaces, and more.
    Registry values adapted from the Win11Debloat project (MIT, Raphire) and
    verified against Windows 11 24H2/25H2.

.NOTES
    Module: Win-Debloat7.Modules.Tweaks.System
    Version: 1.3.1
#>

#Requires -Version 7.6
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force
Import-Module "$PSScriptRoot\..\..\core\Registry.psm1" -Force

#region Boot & Power

function Disable-WinDebloat7FastStartup {
    <#
    .SYNOPSIS
        Disables Fast Startup (hybrid boot). Ensures full shutdowns, which
        avoids stale driver state and dual-boot clock/filesystem issues.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Fast Startup", "Disable")) {
        if (Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord) {
            Write-Log -Message "Fast Startup disabled (full shutdowns restored)." -Level Success
        }
    }
}

function Disable-WinDebloat7ModernStandbyNetworking {
    <#
    .SYNOPSIS
        Disables network connectivity during Modern Standby (sleep), reducing
        battery drain and unexpected wake activity on supported devices.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Modern Standby networking", "Disable")) {
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9"
        $ok = (Set-RegistryKey -Path $path -Name "ACSettingIndex" -Value 0 -Type DWord) -and
              (Set-RegistryKey -Path $path -Name "DCSettingIndex" -Value 0 -Type DWord)
        if ($ok) { Write-Log -Message "Modern Standby networking disabled (AC + battery)." -Level Success }
    }
}

#endregion

#region Storage & Updates

function Disable-WinDebloat7AutoBitLocker {
    <#
    .SYNOPSIS
        Prevents automatic BitLocker device encryption (enabled by default on
        Windows 11 24H2+ clean installs). Does NOT decrypt already-encrypted drives.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("BitLocker automatic device encryption", "Prevent")) {
        if (Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Name "PreventDeviceEncryption" -Value 1 -Type DWord) {
            Write-Log -Message "Automatic BitLocker device encryption prevented (existing volumes untouched)." -Level Success
        }
    }
}

function Disable-WinDebloat7DeliveryOptimization {
    <#
    .SYNOPSIS
        Disables Delivery Optimization peer-to-peer update sharing
        (HTTP-only downloads via the machine-wide policy).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Delivery Optimization", "Disable P2P sharing")) {
        if (Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0 -Type DWord) {
            Write-Log -Message "Delivery Optimization P2P sharing disabled." -Level Success
        }
    }
}

function Disable-WinDebloat7StorageSense {
    <#
    .SYNOPSIS
        Disables Storage Sense automatic disk cleanup for the current user.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Storage Sense", "Disable")) {
        if (Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type DWord) {
            Write-Log -Message "Storage Sense disabled." -Level Success
        }
    }
}

function Set-WinDebloat7UpdateBehavior {
    <#
    .SYNOPSIS
        Tames Windows Update behavior.

    .PARAMETER NoAutoReboot
        Prevents automatic restarts after updates while users are signed in.

    .PARAMETER NoEarlyUpdates
        Turns off "Get the latest updates as soon as they're available"
        (avoids being an early adopter of freshly shipped updates).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$NoAutoReboot,
        [switch]$NoEarlyUpdates
    )

    if ($NoAutoReboot -and $PSCmdlet.ShouldProcess("Windows Update", "Prevent auto-reboot while signed in")) {
        if (Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord) {
            Write-Log -Message "Automatic post-update reboots prevented while users are signed in." -Level Success
        }
    }

    if ($NoEarlyUpdates -and $PSCmdlet.ShouldProcess("Windows Update", "Disable early update opt-in")) {
        if (Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "IsContinuousInnovationOptedIn" -Value 0 -Type DWord) {
            Write-Log -Message "'Get the latest updates as soon as they're available' turned off." -Level Success
        }
    }
}

#endregion

#region Suggestions & Ads

function Disable-WinDebloat7WindowsSuggestions {
    <#
    .SYNOPSIS
        Disables the full set of Windows suggestion/ad surfaces: Start
        suggestions, Settings suggestions + notifications, welcome/tips
        experiences, lock screen tips, "finish setting up" nags, silent
        promoted-app installs, suggested-app toasts, backup reminder toasts,
        and Phone Link suggestions.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (-not $PSCmdlet.ShouldProcess("Windows suggestion & ad surfaces", "Disable")) { return }

    $cdm = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    $advanced = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    $tweaks = @(
        # Welcome experience / tips / Start & Settings suggestions
        @{ Path = $cdm; Name = "SubscribedContent-310093Enabled"; Value = 0 }
        @{ Path = $cdm; Name = "SubscribedContent-338388Enabled"; Value = 0 }
        @{ Path = $cdm; Name = "SystemPaneSuggestionsEnabled"; Value = 0 }
        @{ Path = $cdm; Name = "SubscribedContent-338389Enabled"; Value = 0 }
        @{ Path = $cdm; Name = "SoftLandingEnabled"; Value = 0 }
        @{ Path = $cdm; Name = "SubscribedContent-338393Enabled"; Value = 0 }
        @{ Path = $cdm; Name = "SubscribedContent-353694Enabled"; Value = 0 }
        @{ Path = $cdm; Name = "SubscribedContent-353696Enabled"; Value = 0 }
        @{ Path = $cdm; Name = "SubscribedContent-353698Enabled"; Value = 0 }
        # Lock screen tips & spotlight overlay facts
        @{ Path = $cdm; Name = "SubscribedContent-338387Enabled"; Value = 0 }
        @{ Path = $cdm; Name = "RotatingLockScreenOverlayEnabled"; Value = 0 }
        # Silent installs of promoted apps
        @{ Path = $cdm; Name = "SilentInstalledAppsEnabled"; Value = 0 }
        # Start recommendations (Iris) & account notifications
        @{ Path = $advanced; Name = "Start_IrisRecommendations"; Value = 0 }
        @{ Path = $advanced; Name = "Start_AccountNotifications"; Value = 0 }
        @{ Path = $advanced; Name = "ShowSyncProviderNotifications"; Value = 0 }
        # Settings app account notifications
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications"; Name = "EnableAccountNotifications"; Value = 0 }
        # "Finish setting up your device" nag
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement"; Name = "ScoobeSystemSettingEnabled"; Value = 0 }
        # Suggested-app + backup reminder toast notifications
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested"; Name = "Enabled"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.BackupReminder"; Name = "Enabled"; Value = 0 }
        # Phone Link / mobile device suggestions
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Mobility"; Name = "OptedIn"; Value = 0 }
    )

    $ok = 0
    foreach ($t in $tweaks) {
        if (Set-RegistryKey -Path $t.Path -Name $t.Name -Value $t.Value -Type DWord) { $ok++ }
    }
    Write-Log -Message "Windows suggestions & ads disabled ($ok/$($tweaks.Count) values set)." -Level Success
}

function Disable-WinDebloat7SettingsHome {
    <#
    .SYNOPSIS
        Hides the promotional "Home" page in the Settings app.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Settings Home page", "Hide")) {
        if (Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "SettingsPageVisibility" -Value "hide:home" -Type String) {
            Write-Log -Message "Settings Home page hidden." -Level Success
        }
    }
}

function Disable-WinDebloat7ShareDragTray {
    <#
    .SYNOPSIS
        Disables the share tray that appears at the top of the screen when
        dragging files (Windows 11 24H2+).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Drag share tray", "Disable")) {
        if (Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP" -Name "DragTrayEnabled" -Value 0 -Type DWord) {
            Write-Log -Message "Drag-to-share tray disabled." -Level Success
        }
    }
}

function Disable-WinDebloat7PhoneLinkStart {
    <#
    .SYNOPSIS
        Hides the Phone Link mobile-device panel in the Start menu.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Phone Link in Start", "Disable")) {
        if (Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Start\Companions\Microsoft.YourPhone_8wekyb3d8bbwe" -Name "IsEnabled" -Value 0 -Type DWord) {
            Write-Log -Message "Phone Link panel removed from Start." -Level Success
        }
    }
}

#endregion

#region Input & Privacy

function Disable-WinDebloat7StickyKeysShortcut {
    <#
    .SYNOPSIS
        Disables the Sticky Keys pop-up triggered by pressing Shift 5 times
        (a common annoyance while gaming).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Sticky Keys shortcut", "Disable")) {
        if (Set-RegistryKey -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" -Type String) {
            Write-Log -Message "Sticky Keys shortcut (5x Shift) disabled." -Level Success
        }
    }
}

function Disable-WinDebloat7FindMyDevice {
    <#
    .SYNOPSIS
        Disables the Find My Device location-tracking feature.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Find My Device", "Disable")) {
        if (Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice" -Name "AllowFindMyDevice" -Value 0 -Type DWord) {
            Write-Log -Message "Find My Device disabled." -Level Success
        }
    }
}

#endregion

#region Appearance & Shell

function Disable-WinDebloat7Transparency {
    <#
    .SYNOPSIS
        Disables transparency (acrylic/Mica) effects for a flatter, faster shell.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Transparency effects", "Disable")) {
        if (Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord) {
            Write-Log -Message "Transparency effects disabled." -Level Success
        }
    }
}

function Disable-WinDebloat7SnapAssist {
    <#
    .SYNOPSIS
        Disables Snap Assist window suggestions, the snap-layout flyout, and
        (optionally) window snapping entirely.

    .PARAMETER DisableWindowSnapping
        Also turns off window snapping completely (not just the suggestions).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$DisableWindowSnapping
    )

    if (-not $PSCmdlet.ShouldProcess("Snap Assist", "Disable")) { return }

    $advanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $ok = (Set-RegistryKey -Path $advanced -Name "SnapAssist" -Value 0 -Type DWord) -and
          (Set-RegistryKey -Path $advanced -Name "EnableSnapBar" -Value 0 -Type DWord) -and
          (Set-RegistryKey -Path $advanced -Name "EnableSnapAssistFlyout" -Value 0 -Type DWord)
    if ($ok) { Write-Log -Message "Snap Assist and snap-layout flyout disabled." -Level Success }

    if ($DisableWindowSnapping) {
        if (Set-RegistryKey -Path "HKCU:\Control Panel\Desktop" -Name "WindowArrangementActive" -Value "0" -Type String) {
            Write-Log -Message "Window snapping disabled entirely." -Level Success
        }
    }
}

function Disable-WinDebloat7Widgets {
    <#
    .SYNOPSIS
        Disables the taskbar Widgets board via machine policy. To also remove
        the underlying packages, use Aggressive bloatware removal
        (Microsoft.WidgetsPlatformRuntime, WebExperience).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (-not $PSCmdlet.ShouldProcess("Taskbar Widgets", "Disable")) { return }

    $ok = (Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -Type DWord)
    # Best-effort user-level toggle (may be blocked by the UCPD driver on some builds)
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord | Out-Null
    if ($ok) { Write-Log -Message "Taskbar Widgets disabled via policy." -Level Success }
}

function Disable-WinDebloat7ChatTaskbar {
    <#
    .SYNOPSIS
        Hides the Chat / Meet Now icon from the taskbar.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (-not $PSCmdlet.ShouldProcess("Chat / Meet Now taskbar icon", "Hide")) { return }

    $ok = (Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0 -Type DWord) -and
          (Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow" -Value 1 -Type DWord)
    if ($ok) { Write-Log -Message "Chat / Meet Now icon hidden from taskbar." -Level Success }
}

function Disable-WinDebloat7StartAllApps {
    <#
    .SYNOPSIS
        Hides the "All Apps" list in the Start menu.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Start menu 'All Apps'", "Hide")) {
        if (Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoStartMenuMorePrograms" -Value 1 -Type DWord) {
            Write-Log -Message "'All Apps' hidden from Start menu." -Level Success
        }
    }
}

#endregion

Export-ModuleMember -Function @(
    'Disable-WinDebloat7FastStartup',
    'Disable-WinDebloat7ModernStandbyNetworking',
    'Disable-WinDebloat7AutoBitLocker',
    'Disable-WinDebloat7DeliveryOptimization',
    'Disable-WinDebloat7StorageSense',
    'Set-WinDebloat7UpdateBehavior',
    'Disable-WinDebloat7WindowsSuggestions',
    'Disable-WinDebloat7SettingsHome',
    'Disable-WinDebloat7ShareDragTray',
    'Disable-WinDebloat7PhoneLinkStart',
    'Disable-WinDebloat7StickyKeysShortcut',
    'Disable-WinDebloat7FindMyDevice',
    'Disable-WinDebloat7Transparency',
    'Disable-WinDebloat7SnapAssist',
    'Disable-WinDebloat7Widgets',
    'Disable-WinDebloat7ChatTaskbar',
    'Disable-WinDebloat7StartAllApps'
)
