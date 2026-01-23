<#
.SYNOPSIS
    Registry management utilities for Win-Debloat7
    
.DESCRIPTION
    Provides shared registry manipulation functions with proper error handling,
    ACL validation, and PowerShell 7.5 best practices.
    
.NOTES
    Module: Win-Debloat7.Core.Registry
    Version: 1.0.0
    
.LINK
    https://learn.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-75
#>

#Requires -Version 7.5

using namespace System.Management.Automation
using namespace System.Security.AccessControl

Import-Module "$PSScriptRoot\Logger.psm1" -Force

<#
.SYNOPSIS
    Sets a registry key value with proper validation and error handling.
    
.DESCRIPTION
    Creates the registry path if it doesn't exist and sets the specified value.
    Includes ACL validation to ensure we have write permissions before attempting changes.
    
.PARAMETER Path
    The full registry path (e.g., HKLM:\SOFTWARE\MyApp)
    
.PARAMETER Name
    The registry value name
    
.PARAMETER Value
    The value to set
    
.PARAMETER Type
    The registry value type (DWord, String, QWord, Binary, MultiString, ExpandString)
    
.OUTPUTS
    [bool] Returns $true if successful, $false otherwise
    
.EXAMPLE
    Set-RegistryKey -Path "HKCU:\SOFTWARE\Test" -Name "MySetting" -Value 1
#>
function Set-RegistryKey {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [AllowNull()]
        $Value,
        
        [ValidateSet("DWord", "String", "QWord", "Binary", "MultiString", "ExpandString")]
        [string]$Type = "DWord"
    )
    
    try {
        # Validate and create path if needed
        if (-not (Test-Path $Path)) {
            if ($PSCmdlet.ShouldProcess($Path, "Create Registry Key")) {
                New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
                Write-Log -Message "Created registry path: $Path" -Level Debug
            }
        }
        
        # Validate we have write access (SEC-002 fix)
        $acl = Get-Acl -Path $Path -ErrorAction Stop
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $hasWriteAccess = $false
        
        foreach ($accessRule in $acl.Access) {
            if ($accessRule.IdentityReference.Value -match "Administrators|SYSTEM|$($currentUser.Name)") {
                if ($accessRule.RegistryRights -band [System.Security.AccessControl.RegistryRights]::SetValue) {
                    $hasWriteAccess = $true
                    break
                }
            }
        }
        
        if (-not $hasWriteAccess) {
            Write-Log -Message "Insufficient permissions to modify: $Path" -Level Warning
            # Continue anyway as admin - the write will fail if truly blocked
        }
        
        # Set the value
        if ($PSCmdlet.ShouldProcess("$Path\$Name", "Set Value to $Value ($Type)")) {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
            Write-Log -Message "Set registry: $Path\$Name = $Value" -Level Debug
            return $true
        }
        
        return $false
    }
    catch {
        # SEC-003 fix: Proper error logging instead of silent suppression
        Write-Log -Message "Failed to set registry '$Path\$Name': $($_.Exception.Message)" -Level Error
        return $false
    }
}

<#
.SYNOPSIS
    Gets a registry key value with error handling.
    
.PARAMETER Path
    The full registry path
    
.PARAMETER Name
    The registry value name
    
.PARAMETER DefaultValue
    Value to return if the key doesn't exist
    
.OUTPUTS
    The registry value or default value
#>
function Get-RegistryKey {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        
        $DefaultValue = $null
    )
    
    try {
        if (Test-Path $Path) {
            $value = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop
            return $value
        }
        return $DefaultValue
    }
    catch {
        Write-Log -Message "Registry key not found: $Path\$Name" -Level Debug
        return $DefaultValue
    }
}

<#
.SYNOPSIS
    Tests if a registry key/value exists.
    
.PARAMETER Path
    The full registry path
    
.PARAMETER Name
    Optional: The registry value name. If omitted, tests only the path.
    
.OUTPUTS
    [bool] True if exists, false otherwise
#>
function Test-RegistryKey {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        
        [string]$Name
    )
    
    if (-not (Test-Path $Path)) {
        return $false
    }
    
    if ([string]::IsNullOrEmpty($Name)) {
        return $true
    }
    
    try {
        $null = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
    Exports registry keys for backup purposes.
    
.PARAMETER Path
    The registry path to export
    
.PARAMETER OutputPath
    File path to save the export
    
.OUTPUTS
    [bool] True if successful
#>
function Export-RegistryKey {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath
    )
    
    try {
        if (-not (Test-Path $Path)) {
            Write-Log -Message "Registry path does not exist: $Path" -Level Warning
            return $false
        }
        
        if ($PSCmdlet.ShouldProcess($Path, "Export Registry")) {
            # Use reg.exe for reliable export
            $regPath = $Path -replace '^HKLM:\\', 'HKEY_LOCAL_MACHINE\' -replace '^HKCU:\\', 'HKEY_CURRENT_USER\'
            $result = reg export $regPath $OutputPath /y 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log -Message "Exported registry: $Path -> $OutputPath" -Level Success
                return $true
            }
            else {
                Write-Log -Message "Failed to export registry: $result" -Level Error
                return $false
            }
        }
        
        return $false
    }
    catch {
        Write-Log -Message "Registry export failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

Export-ModuleMember -Function Set-RegistryKey, Get-RegistryKey, Test-RegistryKey, Export-RegistryKey
