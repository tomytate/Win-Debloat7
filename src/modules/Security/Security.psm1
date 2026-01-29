<#
.SYNOPSIS
    System Security Hardening module for Win-Debloat7
    
.DESCRIPTION
    Applies security best practices.
    Disables SMBv1, Enables PUA Protection, etc.
    
.NOTES
    Module: Win-Debloat7.Modules.Security
    Version: 1.2.3
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force
Import-Module "$PSScriptRoot\..\..\core\Registry.psm1" -Force

#region Protocol Hardening

<#
.SYNOPSIS
    Disables SMBv1 Protocol.
#>
function Disable-WinDebloat7SMBv1 {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-Log -Message "Checking SMBv1 Status..." -Level Info
    
    if ($PSCmdlet.ShouldProcess("SMBv1", "Disable Protocol")) {
        # Using Set-SmbServerConfiguration if available (Windows 8.1+)
        if (Get-Command Set-SmbServerConfiguration -ErrorAction SilentlyContinue) {
            Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue
            Write-Log -Message "SMBv1 Disabled (via Cmdlet)." -Level Success
        }
        else {
            # Fallback Registry
            Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -Value 0 -Type DWord
            Write-Log -Message "SMBv1 Disabled (via Registry)." -Level Success
        }
    }
}

#endregion

#region Defender Hardening

<#
.SYNOPSIS
    Enables PUA (Potentially Unwanted Application) Protection.
#>
function Enable-WinDebloat7PUAProtection {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-Log -Message "Enabling Defender PUA Protection..." -Level Info
    
    if ($PSCmdlet.ShouldProcess("Windows Defender", "Enable PUA Protection")) {
        if (Get-Command Set-MpPreference -ErrorAction SilentlyContinue) {
            Set-MpPreference -PUAProtection Enabled -ErrorAction SilentlyContinue
            Write-Log -Message "PUA Protection Enabled." -Level Success
        }
        else {
            Write-Log -Message "Windows Defender cmdlets not found." -Level Warning
        }
    }
}

#endregion

Export-ModuleMember -Function @(
    "Disable-WinDebloat7SMBv1",
    "Enable-WinDebloat7PUAProtection"
)
