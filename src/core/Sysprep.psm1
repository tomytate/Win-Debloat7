<#
.SYNOPSIS
    Handles Sysprep Audit Mode detection and Default User registry operations.
    
.DESCRIPTION
    Provides functions to detect if Windows is in Audit Mode and to mount/dismount
    the Default User registry hive for applying settings to future users (OEM scenarios).
    
.NOTES
    Module: Win-Debloat7.Core.Sysprep
    Version: 1.3.1
#>

function Test-WinDebloat7Sysprep {
    <#
    .SYNOPSIS
        Checks if the system is currently in Sysprep Audit Mode.
    
    .OUTPUTS
        Boolean
    #>
    [CmdletBinding()]
    param()

    $auditKey = "HKLM:\SYSTEM\Setup\Status\AuditBoot"
    if (Test-Path $auditKey) {
        # Check if setup is in progress/audit mode
        return $true
    }
    
    # Fallback check: ImageState
    $imageState = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State" -Name "ImageState" -ErrorAction SilentlyContinue
    if ($imageState -match "IMAGE_STATE_UNDEPLOYABLE" -or $imageState -match "IMAGE_STATE_GENERALIZE_RESEAL_TO_AUDIT") {
        return $true
    }

    return $false
}

function Mount-WinDebloat7DefaultHive {
    <#
    .SYNOPSIS
        Mounts the Default User registry hive (NTUSER.DAT).
    
    .DESCRIPTION
        Mounts existing default user hive to HKLM\WinDebloat7_Default.
        This allows modifying settings for all future users.
        
    .OUTPUTS
        Boolean (True if mounted successfully or already mounted)
    #>
    [CmdletBinding()]
    param()

    $mountPoint = "HKLM\WinDebloat7_Default"
    $defaultUserDat = "$env:SystemDrive\Users\Default\NTUSER.DAT"

    if (-not (Test-Path $defaultUserDat)) {
        Write-Log -Message "Default User NTUSER.DAT not found at $defaultUserDat" -Level Error
        return $false
    }

    if (Test-Path "Registry::$mountPoint") {
        Write-Log -Message "Default User hive already mounted." -Level Debug
        return $true
    }

    try {
        Write-Log -Message "Mounting Default User hive to $mountPoint" -Level Info
        # reg.exe load is often more reliable for hidden hives than PowerShell provider sometimes
        $process = Start-Process -FilePath "reg.exe" -ArgumentList "load ""$mountPoint"" ""$defaultUserDat""" -PassThru -NoNewWindow -Wait
        
        if ($process.ExitCode -eq 0) {
            return $true
        }
        else {
            Write-Log -Message "Failed to mount Default User hive. Exit Code: $($process.ExitCode)" -Level Error
            return $false
        }
    }
    catch {
        Write-Log -Message "Error mounting Default hive: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Dismount-WinDebloat7DefaultHive {
    <#
    .SYNOPSIS
        Dismounts the Default User registry hive.
    #>
    [CmdletBinding()]
    param()

    $mountPoint = "HKLM\WinDebloat7_Default"

    if (-not (Test-Path "Registry::$mountPoint")) {
        return
    }

    try {
        Write-Log -Message "Dismounting Default User hive..." -Level Info
        [GC]::Collect() # Force garbage collection to release file handles
        
        $process = Start-Process -FilePath "reg.exe" -ArgumentList "unload ""$mountPoint""" -PassThru -NoNewWindow -Wait
        
        if ($process.ExitCode -ne 0) {
            Write-Log -Message "Failed to unload Default User hive. Cleanup required." -Level Warning
        }
    }
    catch {
        Write-Log -Message "Error dismounting hive: $($_.Exception.Message)" -Level Error
    }
}

Export-ModuleMember -Function Test-WinDebloat7Sysprep, Mount-WinDebloat7DefaultHive, Dismount-WinDebloat7DefaultHive
