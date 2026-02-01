<#
.SYNOPSIS
    System Repair module for Win-Debloat7
    
.DESCRIPTION
    Provides on-demand tools to repair Windows components.
    Includes SFC, DISM, Network Reset, and Update Reset.
    
.NOTES
    Module: Win-Debloat7.Modules.Repair
    Version: 1.2.5
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force

#region System Repair

<#
.SYNOPSIS
    Runs SFC and DISM repair commands.
#>
function Repair-WinDebloat7System {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param()

    Write-Log -Message "Starting System Repair..." -Level Info
    
    if ($PSCmdlet.ShouldProcess("Windows Image", "Repair (SFC + DISM)")) {
        
        # 1. DISM Check
        Write-Log -Message "Running DISM CheckHealth..." -Level Info
        $dismCheck = Start-Process -FilePath "dism.exe" -ArgumentList "/Online", "/Cleanup-Image", "/CheckHealth" -Wait -PassThru -NoNewWindow
        
        if ($dismCheck.ExitCode -eq 0) {
            Write-Log -Message "Running DISM RestoreHealth (This may take time)..." -Level Info
            Start-Process -FilePath "dism.exe" -ArgumentList "/Online", "/Cleanup-Image", "/RestoreHealth" -Wait -NoNewWindow
        }
        else {
            Write-Log -Message "DISM CheckHealth failed or found no corruption." -Level Warning
        }

        # 2. SFC Scan
        Write-Log -Message "Running System File Checker (SFC)..." -Level Info
        Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow
        
        Write-Log -Message "System repair process complete." -Level Success
    }
}

#endregion

#region Network Reset

<#
.SYNOPSIS
    Resets Network Stack (IP, DNS, Winsock).
#>
function Reset-WinDebloat7Network {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param()

    Write-Log -Message "Starting Network Reset..." -Level Info

    if ($PSCmdlet.ShouldProcess("Network Stack", "Reset (IP/DNS/Winsock)")) {
        $commands = @(
            "ipconfig /release",
            "ipconfig /flushdns",
            "ipconfig /renew",
            "netsh winsock reset",
            "netsh int ip reset"
        )
        
        foreach ($cmd in $commands) {
            Write-Log -Message "Executing: $cmd" -Level Info
            Invoke-Expression $cmd | Out-Null
        }
        
        Write-Log -Message "Network reset complete. You may need to restart." -Level Success
    }
}

#endregion

#region Update Reset

<#
.SYNOPSIS
    Resets Windows Update components.
#>
function Reset-WinDebloat7Update {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param()

    Write-Log -Message "Starting Windows Update Reset..." -Level Info
    
    if ($PSCmdlet.ShouldProcess("Windows Update", "Reset Components")) {
        $services = @("wuauserv", "cryptSvc", "bits", "msiserver")
        
        # Stop Services
        foreach ($svc in $services) {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        }
        
        # Rename Folders
        $folders = @("$env:systemroot\SoftwareDistribution", "$env:systemroot\System32\catroot2")
        foreach ($folder in $folders) {
            if (Test-Path $folder) {
                Rename-Item -Path $folder -NewName "$($folder).old" -Force -ErrorAction SilentlyContinue
            }
        }
        
        # Start Services
        foreach ($svc in $services) {
            Start-Service -Name $svc -ErrorAction SilentlyContinue
        }
        
        Write-Log -Message "Windows Update components reset." -Level Success
    }
}

#endregion

Export-ModuleMember -Function @(
    "Repair-WinDebloat7System",
    "Reset-WinDebloat7Network",
    "Reset-WinDebloat7Update"
)
