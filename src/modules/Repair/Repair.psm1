<#
.SYNOPSIS
    System Repair module for Win-Debloat7
    
.DESCRIPTION
    Provides on-demand tools to repair Windows components.
    Includes SFC, DISM, Network Reset, and Update Reset.
    
.NOTES
    Module: Win-Debloat7.Modules.Repair
    Version: 1.3.0
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force

#region System Repair

<#
.SYNOPSIS
    Runs comprehensive system repair (enhanced 4-step sequence).
    
.DESCRIPTION
    Source: Win-Debloat7 Internal.
    Sequence: ChkDsk (performance mode) → SFC → DISM RestoreHealth → SFC (using repaired image).
#>
function Repair-WinDebloat7System {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param()

    Write-Log -Message "Starting Enhanced System Repair (4-Step Sequence)..." -Level Info
    
    if ($PSCmdlet.ShouldProcess("Windows System", "Full Repair (ChkDsk + SFC + DISM + SFC)")) {
        
        # Step 1: ChkDsk (Performance Mode)
        Write-Log -Message "[1/4] Running ChkDsk (scan mode)..." -Level Info
        try {
            $chkdsk = Start-Process -FilePath "chkdsk.exe" -ArgumentList "C:", "/scan", "/perf" -Wait -PassThru -NoNewWindow
            if ($chkdsk.ExitCode -eq 0) {
                Write-Log -Message "ChkDsk completed successfully." -Level Success
            }
            else {
                Write-Log -Message "ChkDsk returned exit code: $($chkdsk.ExitCode)" -Level Warning
            }
        }
        catch {
            Write-Log -Message "ChkDsk failed: $($_.Exception.Message)" -Level Warning
        }

        # Step 2: SFC First Pass
        Write-Log -Message "[2/4] Running SFC (first pass)..." -Level Info
        try {
            Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow
            Write-Log -Message "SFC first pass completed." -Level Success
        }
        catch {
            Write-Log -Message "SFC first pass failed: $($_.Exception.Message)" -Level Warning
        }

        # Step 3: DISM RestoreHealth
        Write-Log -Message "[3/4] Running DISM RestoreHealth (this may take 10-30 minutes)..." -Level Info
        try {
            $dism = Start-Process -FilePath "dism.exe" -ArgumentList "/Online", "/Cleanup-Image", "/RestoreHealth" -Wait -PassThru -NoNewWindow
            if ($dism.ExitCode -eq 0) {
                Write-Log -Message "DISM RestoreHealth completed successfully." -Level Success
            }
            else {
                Write-Log -Message "DISM RestoreHealth returned exit code: $($dism.ExitCode)" -Level Warning
            }
        }
        catch {
            Write-Log -Message "DISM failed: $($_.Exception.Message)" -Level Error
        }

        # Step 4: SFC Second Pass (uses repaired component store)
        Write-Log -Message "[4/4] Running SFC (second pass with repaired image)..." -Level Info
        try {
            Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow
            Write-Log -Message "SFC second pass completed." -Level Success
        }
        catch {
            Write-Log -Message "SFC second pass failed: $($_.Exception.Message)" -Level Warning
        }
        
        Write-Log -Message "Enhanced system repair complete." -Level Success
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
            # SEC-003 Fix: Replaced Invoke-Expression with Start-Process
            $parts = $cmd -split ' ', 2
            $exe = $parts[0]
            $procArgs = if ($parts.Count -gt 1) { $parts[1] } else { "" }
            Start-Process -FilePath $exe -ArgumentList $procArgs -NoNewWindow -Wait
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
