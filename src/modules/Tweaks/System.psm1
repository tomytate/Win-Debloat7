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
    Version: 1.4.0
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

function Enable-WinDebloat7FastStartup {
    <#
    .SYNOPSIS
        Re-enables Fast Startup (hybrid boot) - the Windows out-of-box default.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Fast Startup", "Enable")) {
        if (Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 1 -Type DWord) {
            Write-Log -Message "Fast Startup re-enabled." -Level Success
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

function Enable-WinDebloat7ModernStandbyNetworking {
    <#
    .SYNOPSIS
        Removes the Modern Standby networking policy override, restoring the
        Windows default (connectivity allowed during standby).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Modern Standby networking", "Restore default")) {
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9"
        $ok = (Remove-RegistryKey -Path $path -Name "ACSettingIndex") -and
              (Remove-RegistryKey -Path $path -Name "DCSettingIndex")
        if ($ok) { Write-Log -Message "Modern Standby networking policy override removed." -Level Success }
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

function Enable-WinDebloat7AutoBitLocker {
    <#
    .SYNOPSIS
        Removes the policy blocking automatic BitLocker device encryption,
        restoring the Windows default (encryption allowed).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("BitLocker automatic device encryption", "Allow")) {
        if (Remove-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Name "PreventDeviceEncryption") {
            Write-Log -Message "Automatic BitLocker device encryption policy override removed." -Level Success
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

function Enable-WinDebloat7DeliveryOptimization {
    <#
    .SYNOPSIS
        Removes the Delivery Optimization policy override, restoring the
        Windows default P2P update-sharing behavior.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Delivery Optimization", "Restore default")) {
        if (Remove-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode") {
            Write-Log -Message "Delivery Optimization policy override removed." -Level Success
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

function Enable-WinDebloat7StorageSense {
    <#
    .SYNOPSIS
        Re-enables Storage Sense automatic disk cleanup for the current user.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Storage Sense", "Enable")) {
        if (Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 1 -Type DWord) {
            Write-Log -Message "Storage Sense re-enabled." -Level Success
        }
    }
}

function Set-WinDebloat7UpdateBehavior {
    <#
    .SYNOPSIS
        Tames (or restores) Windows Update behavior.

    .PARAMETER NoAutoReboot
        Prevents automatic restarts after updates while users are signed in.

    .PARAMETER NoEarlyUpdates
        Turns off "Get the latest updates as soon as they're available"
        (avoids being an early adopter of freshly shipped updates).

    .PARAMETER AllowAutoReboot
        Reverts NoAutoReboot: removes the policy so Windows Update may again
        restart automatically after installing updates.

    .PARAMETER AllowEarlyUpdates
        Reverts NoEarlyUpdates: removes the override so the user's own
        "get updates as soon as available" preference applies again.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$NoAutoReboot,
        [switch]$NoEarlyUpdates,
        [switch]$AllowAutoReboot,
        [switch]$AllowEarlyUpdates
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

    if ($AllowAutoReboot -and $PSCmdlet.ShouldProcess("Windows Update", "Restore default auto-reboot behavior")) {
        if (Remove-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers") {
            Write-Log -Message "Auto-reboot-prevention policy removed." -Level Success
        }
    }

    if ($AllowEarlyUpdates -and $PSCmdlet.ShouldProcess("Windows Update", "Restore default early-update setting")) {
        if (Remove-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "IsContinuousInnovationOptedIn") {
            Write-Log -Message "Early-update override removed." -Level Success
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

function Enable-WinDebloat7WindowsSuggestions {
    <#
    .SYNOPSIS
        Re-enables the full set of Windows suggestion/ad surfaces disabled by
        Disable-WinDebloat7WindowsSuggestions (sets every value back to 1,
        the Windows default/enabled state for each).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (-not $PSCmdlet.ShouldProcess("Windows suggestion & ad surfaces", "Enable")) { return }

    $cdm = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    $advanced = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    $tweaks = @(
        @{ Path = $cdm; Name = "SubscribedContent-310093Enabled"; Value = 1 }
        @{ Path = $cdm; Name = "SubscribedContent-338388Enabled"; Value = 1 }
        @{ Path = $cdm; Name = "SystemPaneSuggestionsEnabled"; Value = 1 }
        @{ Path = $cdm; Name = "SubscribedContent-338389Enabled"; Value = 1 }
        @{ Path = $cdm; Name = "SoftLandingEnabled"; Value = 1 }
        @{ Path = $cdm; Name = "SubscribedContent-338393Enabled"; Value = 1 }
        @{ Path = $cdm; Name = "SubscribedContent-353694Enabled"; Value = 1 }
        @{ Path = $cdm; Name = "SubscribedContent-353696Enabled"; Value = 1 }
        @{ Path = $cdm; Name = "SubscribedContent-353698Enabled"; Value = 1 }
        @{ Path = $cdm; Name = "SubscribedContent-338387Enabled"; Value = 1 }
        @{ Path = $cdm; Name = "RotatingLockScreenOverlayEnabled"; Value = 1 }
        @{ Path = $cdm; Name = "SilentInstalledAppsEnabled"; Value = 1 }
        @{ Path = $advanced; Name = "Start_IrisRecommendations"; Value = 1 }
        @{ Path = $advanced; Name = "Start_AccountNotifications"; Value = 1 }
        @{ Path = $advanced; Name = "ShowSyncProviderNotifications"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications"; Name = "EnableAccountNotifications"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement"; Name = "ScoobeSystemSettingEnabled"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested"; Name = "Enabled"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.BackupReminder"; Name = "Enabled"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Mobility"; Name = "OptedIn"; Value = 1 }
    )

    $ok = 0
    foreach ($t in $tweaks) {
        if (Set-RegistryKey -Path $t.Path -Name $t.Name -Value $t.Value -Type DWord) { $ok++ }
    }
    Write-Log -Message "Windows suggestions & ads re-enabled ($ok/$($tweaks.Count) values set)." -Level Success
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

function Enable-WinDebloat7SettingsHome {
    <#
    .SYNOPSIS
        Removes the override hiding the Settings app's "Home" page.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Settings Home page", "Show")) {
        if (Remove-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "SettingsPageVisibility") {
            Write-Log -Message "Settings Home page override removed." -Level Success
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

function Enable-WinDebloat7ShareDragTray {
    <#
    .SYNOPSIS
        Re-enables the drag-to-share tray (Windows 11 24H2+).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Drag share tray", "Enable")) {
        if (Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP" -Name "DragTrayEnabled" -Value 1 -Type DWord) {
            Write-Log -Message "Drag-to-share tray re-enabled." -Level Success
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

function Enable-WinDebloat7PhoneLinkStart {
    <#
    .SYNOPSIS
        Restores the Phone Link mobile-device panel in the Start menu.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Phone Link in Start", "Enable")) {
        if (Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Start\Companions\Microsoft.YourPhone_8wekyb3d8bbwe" -Name "IsEnabled" -Value 1 -Type DWord) {
            Write-Log -Message "Phone Link panel restored in Start." -Level Success
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

function Enable-WinDebloat7StickyKeysShortcut {
    <#
    .SYNOPSIS
        Re-enables the Sticky Keys pop-up shortcut (5x Shift), restoring the
        standard Windows default Flags value (510 = shortcut active + the
        confirmation/indicator defaults) used across mainstream debloat tools.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Sticky Keys shortcut", "Enable")) {
        if (Set-RegistryKey -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "510" -Type String) {
            Write-Log -Message "Sticky Keys shortcut (5x Shift) re-enabled." -Level Success
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

function Enable-WinDebloat7FindMyDevice {
    <#
    .SYNOPSIS
        Removes the policy forcing Find My Device off, restoring the user's
        own Settings > Privacy choice for this feature.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Find My Device", "Restore default")) {
        if (Remove-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice" -Name "AllowFindMyDevice") {
            Write-Log -Message "Find My Device policy override removed." -Level Success
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

function Enable-WinDebloat7Transparency {
    <#
    .SYNOPSIS
        Re-enables transparency (acrylic/Mica) effects - the Windows default.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Transparency effects", "Enable")) {
        if (Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 1 -Type DWord) {
            Write-Log -Message "Transparency effects re-enabled." -Level Success
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

function Enable-WinDebloat7SnapAssist {
    <#
    .SYNOPSIS
        Re-enables Snap Assist window suggestions and the snap-layout flyout,
        and (optionally) window snapping itself.

    .PARAMETER EnableWindowSnapping
        Also restores window snapping if it was previously disabled entirely.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$EnableWindowSnapping
    )

    if (-not $PSCmdlet.ShouldProcess("Snap Assist", "Enable")) { return }

    $advanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $ok = (Set-RegistryKey -Path $advanced -Name "SnapAssist" -Value 1 -Type DWord) -and
          (Set-RegistryKey -Path $advanced -Name "EnableSnapBar" -Value 1 -Type DWord) -and
          (Set-RegistryKey -Path $advanced -Name "EnableSnapAssistFlyout" -Value 1 -Type DWord)
    if ($ok) { Write-Log -Message "Snap Assist and snap-layout flyout re-enabled." -Level Success }

    if ($EnableWindowSnapping) {
        if (Set-RegistryKey -Path "HKCU:\Control Panel\Desktop" -Name "WindowArrangementActive" -Value "1" -Type String) {
            Write-Log -Message "Window snapping re-enabled." -Level Success
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

function Enable-WinDebloat7Widgets {
    <#
    .SYNOPSIS
        Removes the policy blocking taskbar Widgets and restores the taskbar
        icon, reverting to the Windows default (Widgets available).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (-not $PSCmdlet.ShouldProcess("Taskbar Widgets", "Enable")) { return }

    $ok = (Remove-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests")
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 1 -Type DWord | Out-Null
    if ($ok) { Write-Log -Message "Taskbar Widgets policy override removed." -Level Success }
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

function Enable-WinDebloat7ChatTaskbar {
    <#
    .SYNOPSIS
        Restores the Chat / Meet Now icon on the taskbar.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (-not $PSCmdlet.ShouldProcess("Chat / Meet Now taskbar icon", "Show")) { return }

    $ok = (Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 1 -Type DWord) -and
          (Remove-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow")
    if ($ok) { Write-Log -Message "Chat / Meet Now icon restored on taskbar." -Level Success }
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

function Enable-WinDebloat7StartAllApps {
    <#
    .SYNOPSIS
        Removes the policy hiding the "All Apps" list in the Start menu.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Start menu 'All Apps'", "Show")) {
        if (Remove-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoStartMenuMorePrograms") {
            Write-Log -Message "'All Apps' restored in Start menu." -Level Success
        }
    }
}

#endregion

#region Profile Integration

<#
.SYNOPSIS
    Applies System & QoL tweaks from a YAML profile's "system" section.

.DESCRIPTION
    Profile consumer for the system: block (see profiles/schema.yaml). Every
    key is an opt-in boolean; absent or false keys are skipped, so existing
    pre-1.4 profiles work unchanged.

.PARAMETER Config
    The configuration object loaded from a YAML profile.

.EXAMPLE
    Set-WinDebloat7SystemTweaks -Config $config
#>
function Set-WinDebloat7SystemTweaks {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [psobject]$Config
    )

    if (-not $Config.system) {
        Write-Log -Message "No system configuration found in profile." -Level Info
        return
    }

    $sys = $Config.system
    Write-Log -Message "Applying System & QoL tweaks from profile..." -Level Info

    if ($sys.disable_fast_startup) { Disable-WinDebloat7FastStartup }
    if ($sys.prevent_auto_bitlocker) { Disable-WinDebloat7AutoBitLocker }
    if ($sys.disable_delivery_optimization) { Disable-WinDebloat7DeliveryOptimization }
    if ($sys.disable_storage_sense) { Disable-WinDebloat7StorageSense }
    if ($sys.no_auto_reboot_updates) { Set-WinDebloat7UpdateBehavior -NoAutoReboot }
    if ($sys.no_early_updates) { Set-WinDebloat7UpdateBehavior -NoEarlyUpdates }
    if ($sys.disable_sticky_keys_shortcut) { Disable-WinDebloat7StickyKeysShortcut }
    if ($sys.disable_share_drag_tray) { Disable-WinDebloat7ShareDragTray }
    if ($sys.disable_find_my_device) { Disable-WinDebloat7FindMyDevice }
    if ($sys.disable_modern_standby_networking) { Disable-WinDebloat7ModernStandbyNetworking }
    if ($sys.disable_widgets) { Disable-WinDebloat7Widgets }
    if ($sys.hide_chat_taskbar) { Disable-WinDebloat7ChatTaskbar }
    if ($sys.disable_transparency) { Disable-WinDebloat7Transparency }
    if ($sys.disable_snap_assist) { Disable-WinDebloat7SnapAssist }
    if ($sys.hide_start_all_apps) { Disable-WinDebloat7StartAllApps }
    if ($sys.disable_suggestions) { Disable-WinDebloat7WindowsSuggestions }
    if ($sys.hide_settings_home) { Disable-WinDebloat7SettingsHome }
    if ($sys.hide_phone_link_start) { Disable-WinDebloat7PhoneLinkStart }

    if ($sys.debloat_search) {
        # Set-WinDebloat7Search lives in the UI tweaks module; resolve it at run
        # time so this module stays importable standalone.
        $searchCmd = Get-Command Set-WinDebloat7Search -ErrorAction SilentlyContinue
        if ($searchCmd) {
            & $searchCmd -DisableBingSearch -DisableSearchHighlights -DisableSearchHistory
        }
        else {
            Write-Log -Message "Set-WinDebloat7Search not available - skipping debloat_search (load the full Win-Debloat7 module)." -Level Warning
        }
    }

    Write-Log -Message "System & QoL profile tweaks applied." -Level Success
}

#endregion

Export-ModuleMember -Function @(
    'Set-WinDebloat7SystemTweaks',
    'Disable-WinDebloat7FastStartup',
    'Enable-WinDebloat7FastStartup',
    'Disable-WinDebloat7ModernStandbyNetworking',
    'Enable-WinDebloat7ModernStandbyNetworking',
    'Disable-WinDebloat7AutoBitLocker',
    'Enable-WinDebloat7AutoBitLocker',
    'Disable-WinDebloat7DeliveryOptimization',
    'Enable-WinDebloat7DeliveryOptimization',
    'Disable-WinDebloat7StorageSense',
    'Enable-WinDebloat7StorageSense',
    'Set-WinDebloat7UpdateBehavior',
    'Disable-WinDebloat7WindowsSuggestions',
    'Enable-WinDebloat7WindowsSuggestions',
    'Disable-WinDebloat7SettingsHome',
    'Enable-WinDebloat7SettingsHome',
    'Disable-WinDebloat7ShareDragTray',
    'Enable-WinDebloat7ShareDragTray',
    'Disable-WinDebloat7PhoneLinkStart',
    'Enable-WinDebloat7PhoneLinkStart',
    'Disable-WinDebloat7StickyKeysShortcut',
    'Enable-WinDebloat7StickyKeysShortcut',
    'Disable-WinDebloat7FindMyDevice',
    'Enable-WinDebloat7FindMyDevice',
    'Disable-WinDebloat7Transparency',
    'Enable-WinDebloat7Transparency',
    'Disable-WinDebloat7SnapAssist',
    'Enable-WinDebloat7SnapAssist',
    'Disable-WinDebloat7Widgets',
    'Enable-WinDebloat7Widgets',
    'Disable-WinDebloat7ChatTaskbar',
    'Enable-WinDebloat7ChatTaskbar',
    'Disable-WinDebloat7StartAllApps',
    'Enable-WinDebloat7StartAllApps'
)
