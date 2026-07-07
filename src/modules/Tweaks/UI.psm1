<#
.SYNOPSIS
    UI Customization module for Win-Debloat7
    
.DESCRIPTION
    Manages Visual UI tweaks for Windows 11/10.
    Includes Taskbar alignment, Context Menu style, and Explorer visibility options.
    
.NOTES
    Module: Win-Debloat7.Modules.Tweaks.UI
    Version: 1.3.1
#>

#Requires -Version 7.6
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force
Import-Module "$PSScriptRoot\..\..\core\Registry.psm1" -Force

#region Taskbar

<#
.SYNOPSIS
    Sets the Windows 11 Taskbar alignment.
    
.PARAMETER Alignment
    Left or Center.
#>
function Set-WinDebloat7TaskbarAlignment {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [ValidateSet("Left", "Center")]
        [string]$Alignment
    )
    
    Write-Log -Message "Setting Taskbar alignment to $Alignment..." -Level Info
    
    $value = if ($Alignment -eq "Left") { 0 } else { 1 }
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    
    if ($PSCmdlet.ShouldProcess("Taskbar", "Set Alignment to $Alignment")) {
        if (Set-RegistryKey -Path $path -Name "TaskbarAl" -Value $value -Type DWord) {
            Write-Log -Message "Taskbar alignment set to $Alignment." -Level Success
        }
        else {
            Write-Log -Message "Failed to set taskbar alignment." -Level Error
        }
    }
}

#endregion

#region Context Menu

<#
.SYNOPSIS
    Configures the File Explorer Context Menu style.
    
.PARAMETER Style
    Classic (Windows 10 style) or Modern (Windows 11 style).
#>
function Set-WinDebloat7ContextMenu {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [ValidateSet("Classic", "Modern")]
        [string]$Style
    )
    
    Write-Log -Message "Setting Context Menu style to $Style..." -Level Info
    
    $keyPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    
    if ($PSCmdlet.ShouldProcess("Context Menu", "Set style to $Style")) {
        try {
            if ($Style -eq "Classic") {
                # To enable classic, we need to create this key with an empty default value
                if (-not (Test-Path $keyPath)) {
                    New-Item -Path $keyPath -Force -ErrorAction Stop | Out-Null
                }
                # Set default value to empty string
                Set-Item -Path $keyPath -Value "" -ErrorAction Stop
                Write-Log -Message "Classic Context Menu enabled." -Level Success
            }
            else {
                # To enable Modern (default), we delete the key override
                if (Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}") {
                    Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction Stop
                }
                Write-Log -Message "Modern Context Menu restored." -Level Success
            }
        }
        catch {
            Write-Log -Message "Failed to set context menu style: $($_.Exception.Message)" -Level Error
        }
    }
}

#endregion

#region Explorer

<#
.SYNOPSIS
    Configures File Explorer visibility and behavior options.

.PARAMETER HideGallery
    Hides the "Gallery" item from Explorer navigation.

.PARAMETER HideHome
    Hides "Home" from Explorer.

.PARAMETER ShowFileExtensions
    Shows extensions for known file types (a security best practice -
    prevents "invoice.pdf.exe"-style disguises).

.PARAMETER ShowHiddenFiles
    Shows hidden files and folders.

.PARAMETER LaunchTo
    Sets the default File Explorer landing page: ThisPC, Home, Downloads, or OneDrive.

.PARAMETER HideOneDrive
    Hides the "OneDrive" entry from the Explorer navigation pane.

.PARAMETER Hide3DObjects
    Hides the "3D Objects" folder under "This PC".

.PARAMETER HideMusic
    Hides the "Music" folder under "This PC".
#>
function Set-WinDebloat7Explorer {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [switch]$HideGallery,
        [switch]$HideHome,
        [switch]$ShowFileExtensions,
        [switch]$ShowHiddenFiles,
        [ValidateSet("ThisPC", "Home", "Downloads", "OneDrive")]
        [string]$LaunchTo,
        [switch]$HideOneDrive,
        [switch]$Hide3DObjects,
        [switch]$HideMusic
    )
    
    Write-Log -Message "Applying File Explorer tweaks..." -Level Info
    
    # Hide Gallery
    if ($HideGallery) {
        $galleryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace_41040327\{e88865ea-0e1c-4e20-9aa6-ed25316e9424}"
        if ($PSCmdlet.ShouldProcess("Explorer", "Hide Gallery")) {
            if (Test-Path $galleryKey) {
                # We can't easily delete HKLM keys without trustedinstaller usually, but let's try or set property
                # Legacy key handling. 
                # Alternative: Set System.IsPinnedToNameSpaceTree to 0 in HKCR CLSID if possible.
                # For safety/portability, we'll try to detach via CLSID user override if possible, or HKLM delete.
                
                # Using the HKCU CLSID method is safer if available, but for Gallery it's often HKLM.
                # Let's try to set the property "System.IsPinnedToNameSpaceTree" to 0 in absolute CLSID path
                $clsid = "{e88865ea-0e1c-4e20-9aa6-ed25316e9424}"
                $paths = @(
                    "HKCU:\Software\Classes\CLSID\$clsid",
                    "HKLM:\SOFTWARE\Classes\CLSID\$clsid"
                )
                
                foreach ($p in $paths) {
                    if (-not (Test-Path $p)) {
                        New-Item -Path $p -Force -ErrorAction SilentlyContinue | Out-Null
                    }
                    Set-RegistryKey -Path $p -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord
                }
                Write-Log -Message "Hidden Gallery from Explorer." -Level Success
            }
        }
    }
    
    # Hide Home
    if ($HideHome) {
        if ($PSCmdlet.ShouldProcess("Explorer", "Hide Home")) {
            $clsid = "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
            Set-RegistryKey -Path "HKLM:\SOFTWARE\Classes\CLSID\$clsid" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord
            Write-Log -Message "Hidden Home from Explorer." -Level Success
        }
    }

    $advanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    # Show file extensions
    if ($ShowFileExtensions) {
        if ($PSCmdlet.ShouldProcess("Explorer", "Show file extensions")) {
            if (Set-RegistryKey -Path $advanced -Name "HideFileExt" -Value 0 -Type DWord) {
                Write-Log -Message "File extensions shown for known file types." -Level Success
            }
        }
    }

    # Show hidden files
    if ($ShowHiddenFiles) {
        if ($PSCmdlet.ShouldProcess("Explorer", "Show hidden files")) {
            if (Set-RegistryKey -Path $advanced -Name "Hidden" -Value 1 -Type DWord) {
                Write-Log -Message "Hidden files and folders shown." -Level Success
            }
        }
    }

    # Default landing page
    if ($LaunchTo) {
        $launchValue = switch ($LaunchTo) {
            "ThisPC" { 1 }
            "Home" { 2 }
            "Downloads" { 3 }
            "OneDrive" { 4 }
        }
        if ($PSCmdlet.ShouldProcess("Explorer", "Launch to $LaunchTo")) {
            if (Set-RegistryKey -Path $advanced -Name "LaunchTo" -Value $launchValue -Type DWord) {
                Write-Log -Message "File Explorer now opens to $LaunchTo." -Level Success
            }
        }
    }

    # Hide OneDrive from the navigation pane
    if ($HideOneDrive) {
        if ($PSCmdlet.ShouldProcess("Explorer", "Hide OneDrive from navigation pane")) {
            if (Set-RegistryKey -Path "HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord) {
                Write-Log -Message "OneDrive hidden from Explorer navigation pane." -Level Success
            }
        }
    }

    # Hide "3D Objects" and "Music" folders under This PC (delete the NameSpace keys)
    $thisPcFolders = @()
    if ($Hide3DObjects) { $thisPcFolders += "{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" }
    if ($HideMusic) { $thisPcFolders += "{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" }
    foreach ($clsid in $thisPcFolders) {
        if ($PSCmdlet.ShouldProcess("This PC folder $clsid", "Hide")) {
            foreach ($hive in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\$clsid",
                    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\$clsid")) {
                if (Test-Path $hive) { Remove-Item -Path $hive -Recurse -Force -ErrorAction SilentlyContinue }
            }
        }
    }
    if ($thisPcFolders.Count -gt 0) { Write-Log -Message "Hid $($thisPcFolders.Count) folder(s) from This PC." -Level Success }
}

<#
.SYNOPSIS
    Removes clutter items from the File Explorer right-click context menu.

.PARAMETER HideShare
    Removes the "Share" item.

.PARAMETER HideGiveAccessTo
    Removes the "Give access to" item.

.PARAMETER HideIncludeInLibrary
    Removes the "Include in library" item.
#>
function Set-WinDebloat7ContextMenuItems {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [switch]$HideShare,
        [switch]$HideGiveAccessTo,
        [switch]$HideIncludeInLibrary
    )

    # These handlers live under HKCR (machine-wide). Deleting the handler key
    # removes the menu item; it can be restored by re-registering the shell ext.
    $targets = @()
    if ($HideShare) {
        $targets += "Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\ModernSharing"
    }
    if ($HideGiveAccessTo) {
        $targets += @(
            "Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\Sharing"
            "Registry::HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\Sharing"
            "Registry::HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\Sharing"
            "Registry::HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers\Sharing"
            "Registry::HKEY_CLASSES_ROOT\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing"
        )
    }
    if ($HideIncludeInLibrary) {
        $targets += "Registry::HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\Library Location"
    }

    if ($targets.Count -eq 0) { return }

    $removed = 0
    foreach ($t in $targets) {
        if ($PSCmdlet.ShouldProcess($t, "Remove context menu handler")) {
            if (Test-Path $t) {
                try {
                    Remove-Item -Path $t -Recurse -Force -ErrorAction Stop
                    $removed++
                }
                catch {
                    Write-Log -Message "Could not remove '$t' (needs TrustedInstaller?): $($_.Exception.Message)" -Level Warning
                }
            }
        }
    }
    Write-Log -Message "Removed $removed context menu handler(s)." -Level Success
}

#endregion

#region Search & Taskbar Extras

<#
.SYNOPSIS
    Debloats Windows Search.

.PARAMETER DisableBingSearch
    Removes Bing web results and Cortana from Start menu search (local results only).

.PARAMETER DisableSearchHighlights
    Disables Search Highlights (dynamic/branded content in the search box).

.PARAMETER DisableSearchHistory
    Stops Windows from storing device search history.
#>
function Set-WinDebloat7Search {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [switch]$DisableBingSearch,
        [switch]$DisableSearchHighlights,
        [switch]$DisableSearchHistory
    )

    $searchSettings = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"

    if ($DisableBingSearch) {
        if ($PSCmdlet.ShouldProcess("Windows Search", "Disable Bing web results & Cortana")) {
            $ok = (Set-RegistryKey -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord) -and
                  (Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord) -and
                  (Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "CortanaConsent" -Value 0 -Type DWord)
            if ($ok) { Write-Log -Message "Bing web results and Cortana removed from Start search." -Level Success }
        }
    }

    if ($DisableSearchHighlights) {
        if ($PSCmdlet.ShouldProcess("Windows Search", "Disable Search Highlights")) {
            if (Set-RegistryKey -Path $searchSettings -Name "IsDynamicSearchBoxEnabled" -Value 0 -Type DWord) {
                Write-Log -Message "Search Highlights disabled." -Level Success
            }
        }
    }

    if ($DisableSearchHistory) {
        if ($PSCmdlet.ShouldProcess("Windows Search", "Disable search history")) {
            if (Set-RegistryKey -Path $searchSettings -Name "IsDeviceSearchHistoryEnabled" -Value 0 -Type DWord) {
                Write-Log -Message "Device search history disabled." -Level Success
            }
        }
    }
}

<#
.SYNOPSIS
    Extra taskbar tweaks beyond alignment.

.PARAMETER SearchMode
    Taskbar search appearance: Hidden, Icon, IconLabel, or Box.

.PARAMETER HideTaskView
    Hides the Task View button.

.PARAMETER EnableEndTask
    Adds "End Task" to the taskbar right-click menu of running apps.

.PARAMETER EnableLastActiveClick
    Clicking a running app's taskbar icon focuses its last active window
    instead of showing thumbnail previews.
#>
function Set-WinDebloat7TaskbarTweaks {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [ValidateSet("Hidden", "Icon", "IconLabel", "Box")]
        [string]$SearchMode,
        [switch]$HideTaskView,
        [switch]$EnableEndTask,
        [switch]$EnableLastActiveClick
    )

    $advanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    if ($SearchMode) {
        $searchValue = switch ($SearchMode) {
            "Hidden" { 0 }
            "Icon" { 1 }
            "Box" { 2 }
            "IconLabel" { 3 }
        }
        if ($PSCmdlet.ShouldProcess("Taskbar", "Set search to $SearchMode")) {
            if (Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value $searchValue -Type DWord) {
                Write-Log -Message "Taskbar search set to $SearchMode." -Level Success
            }
        }
    }

    if ($HideTaskView) {
        if ($PSCmdlet.ShouldProcess("Taskbar", "Hide Task View button")) {
            if (Set-RegistryKey -Path $advanced -Name "ShowTaskViewButton" -Value 0 -Type DWord) {
                Write-Log -Message "Task View button hidden." -Level Success
            }
        }
    }

    if ($EnableEndTask) {
        if ($PSCmdlet.ShouldProcess("Taskbar", "Enable End Task in right-click menu")) {
            if (Set-RegistryKey -Path "$advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1 -Type DWord) {
                Write-Log -Message "'End Task' added to taskbar right-click menu." -Level Success
            }
        }
    }

    if ($EnableLastActiveClick) {
        if ($PSCmdlet.ShouldProcess("Taskbar", "Enable last-active-window click")) {
            if (Set-RegistryKey -Path $advanced -Name "LastActiveClick" -Value 1 -Type DWord) {
                Write-Log -Message "Taskbar icon clicks now focus the last active window." -Level Success
            }
        }
    }
}

#endregion

#region Explorer Restart

<#
.SYNOPSIS
    Restarts the Windows Explorer shell so pending UI tweaks take effect
    without a full sign-out.
#>
function Restart-WinDebloat7Explorer {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()

    if ($PSCmdlet.ShouldProcess("explorer.exe", "Restart shell")) {
        Write-Log -Message "Restarting Windows Explorer..." -Level Info
        try {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            # Windows normally relaunches the shell automatically; start it
            # explicitly in case the auto-restart policy is disabled.
            Start-Sleep -Milliseconds 500
            if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
                Start-Process explorer.exe
            }
            Write-Log -Message "Explorer restarted." -Level Success
        }
        catch {
            Write-Log -Message "Failed to restart Explorer: $($_.Exception.Message)" -Level Warning
        }
    }
}

#endregion

#region Start Menu

<#
.SYNOPSIS
    Configures Start Menu options.
    
.PARAMETER DisableRecommended
    Removes the "Recommended" section (or minimizes it) in Start Menu.
#>
function Set-WinDebloat7StartMenu {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [switch]$DisableRecommended
    )
    
    if ($DisableRecommended) {
        if ($PSCmdlet.ShouldProcess("Start Menu", "Disable Recommended Section")) {
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
            if (Set-RegistryKey -Path $path -Name "HideRecommendedSection" -Value 1 -Type DWord) {
                Write-Log -Message "Disabled Recommended section in Start Menu." -Level Success
            }
            else {
                Write-Log -Message "Failed to disable Recommended section." -Level Error
            }
        }
    }
}

#endregion

Export-ModuleMember -Function @(
    "Set-WinDebloat7TaskbarAlignment",
    "Set-WinDebloat7ContextMenu",
    "Set-WinDebloat7Explorer",
    "Set-WinDebloat7StartMenu",
    "Set-WinDebloat7Search",
    "Set-WinDebloat7TaskbarTweaks",
    "Set-WinDebloat7ContextMenuItems",
    "Restart-WinDebloat7Explorer"
)
