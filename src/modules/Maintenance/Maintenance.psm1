<#
.SYNOPSIS
    Scheduled maintenance module for Win-Debloat7
    
.DESCRIPTION
    Manages automated system maintenance tasks.
    Registers a Windows Scheduled Task to run weekly optimizations.
    
.NOTES
    Module: Win-Debloat7.Modules.Maintenance
    Version: 1.2.5
#>

#Requires -Version 7.5

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force

<#
.SYNOPSIS
    Registers the Win-Debloat7 maintenance task.
    
.DESCRIPTION
    Creates a scheduled task that runs weekly.
    Performs: Disk Cleanup, Update Checks, and Profile Re-application.
    
.PARAMETER Daily
    Run daily instead of weekly.
#>
function Register-WinDebloat7Maintenance {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$Daily
    )
    
    $taskName = "Win-Debloat7-Maintenance"
    # Fix: Resolve absolute path to avoid relative path issues in Task Scheduler
    $scriptRoot = Resolve-Path "$PSScriptRoot\..\..\.."
    $scriptPath = Join-Path $scriptRoot "Win-Debloat7.ps1"
    
    if (-not (Test-Path $scriptPath)) {
        throw "Could not locate Win-Debloat7.ps1 at $scriptPath"
    }
    
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-Command `"$scriptPath -Maintenance -Unattended`""
    $trigger = if ($Daily) { New-ScheduledTaskTrigger -Daily -At 3am } else { New-ScheduledTaskTrigger -Weekly -At 3am -DaysOfWeek Sunday }
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries:$false -DontStopIfGoingOnBatteries:$false -StartWhenAvailable -RunOnlyIfNetworkAvailable
    
    try {
        if ($PSCmdlet.ShouldProcess($taskName, "Register Scheduled Task")) {
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force -ErrorAction Stop | Out-Null
            Write-Log -Message "Maintenance task registered successfully." -Level Success
        }
    }
    catch {
        Write-Log -Message "Failed to register maintenance task: $($_.Exception.Message)" -Level Error
        throw
    }
}

<#
.SYNOPSIS
    Unregisters the maintenance task.
#>
function Unregister-WinDebloat7Maintenance {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    $taskName = "Win-Debloat7-Maintenance"
    
    try {
        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
            if ($PSCmdlet.ShouldProcess($taskName, "Unregister Scheduled Task")) {
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
                Write-Log -Message "Maintenance task removed." -Level Success
            }
        }
        else {
            Write-Log -Message "Maintenance task not found." -Level Info
        }
    }
    catch {
        Write-Log -Message "Failed to remove maintenance task: $($_.Exception.Message)" -Level Error
    }
}

<#
.SYNOPSIS
    Executes the maintenance logic.
    Called by the scheduled task.
#>
function Invoke-WinDebloat7Maintenance {
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Starting Scheduled Maintenance (Deep Clean)..." -Level Info
    
    # 1. Deep Disk Cleanup (cleanmgr /SAGERUN:777)
    # GEMS Integration: Pre-select all cleanup options in Registry
    Write-Log -Message "Configuring Deep Cleanup settings..." -Level Info
    
    $cleanmgrKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    $cleanOptions = @(
        "Active Setup Temp Folders", "BranchCache", "D3D Shader Cache", "Delivery Optimization Files",
        "Downloaded Program Files", "Internet Cache Files", "Language Pack", "Old ChkDsk Files",
        "Recycle Bin", "Temporary Files", "Temporary Setup Files", "Thumbnail Cache", 
        "Update Cleanup", "Windows Defender", "Windows Error Reporting Files"
    )
    
    foreach ($opt in $cleanOptions) {
        $path = "$cleanmgrKey\$opt"
        if (Test-Path $path) {
            # StateFlags0777 = 2 means selected for SAGERUN:777
            Set-ItemProperty -Path $path -Name "StateFlags0777" -Value 2 -Type DWord -ErrorAction SilentlyContinue
        }
    }
    
    Write-Log -Message "Running Deep Disk Cleanup..." -Level Info
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/SAGERUN:777" -Wait -WindowStyle Hidden
    
    # 2. Windows Update Component Cleanup (DISM)
    Write-Log -Message "Running Component Store Cleanup..." -Level Info
    Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup /NoRestart" -Wait -WindowStyle Hidden
    
    # 3. App Updates (Winget)
    Write-Log -Message "Updating Applications..." -Level Info
    winget upgrade --all --accept-source-agreements --accept-package-agreements --silent --include-unknown 2>$null
    
    Write-Log -Message "Maintenance completed." -Level Success
}

Export-ModuleMember -Function Register-WinDebloat7Maintenance, Unregister-WinDebloat7Maintenance, Invoke-WinDebloat7Maintenance
