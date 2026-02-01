<#
.SYNOPSIS
    UI Customization module for Win-Debloat7
    
.DESCRIPTION
    Manages Visual UI tweaks for Windows 11/10.
    Includes Taskbar alignment, Context Menu style, and Explorer visibility options.
    
.NOTES
    Module: Win-Debloat7.Modules.Tweaks.UI
    Version: 1.2.5
#>

#Requires -Version 7.5
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
    Configures File Explorer visibility options.
    
.PARAMETER HideGallery
    Hides the "Gallery" item from Explorer navigation.
    
.PARAMETER HideHome
    Hides "Home" from Explorer.
#>
function Set-WinDebloat7Explorer {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [switch]$HideGallery,
        [switch]$HideHome
    )
    
    Write-Log -Message "Applying File Explorer tweaks..." -Level Info
    
    # Hide Gallery
    if ($HideGallery) {
        $galleryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace_41040327\{e88865ea-0e1c-4e20-9aa6-ed25316e9424}"
        if ($PSCmdlet.ShouldProcess("Explorer", "Hide Gallery")) {
            if (Test-Path $galleryKey) {
                # We can't easily delete HKLM keys without trustedinstaller usually, but let's try or set property
                # Actually, Win11Debloat deletes this key. 
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
    "Set-WinDebloat7StartMenu"
)
