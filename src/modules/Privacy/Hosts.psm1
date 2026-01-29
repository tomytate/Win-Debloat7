<#
.SYNOPSIS
    Hosts file management module for Win-Debloat7
    
.DESCRIPTION
    Manages Windows hosts file to block telemetry endpoints at DNS level.
    Includes backup/restore functionality and curated blocklist.
    
.NOTES
    Module: Win-Debloat7.Modules.Privacy.Hosts
    Version: 1.2.3
    
.LINK
    https://learn.microsoft.com/powershell/scripting/whats-new/what-s-new-in-powershell-75
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force

#region Blocked Domains

$Script:HostsFilePath = "$env:SystemRoot\System32\drivers\etc\hosts"
$Script:BackupPath = "$env:ProgramData\Win-Debloat7\Backups"
$Script:BlockMarkerStart = "# >>> Win-Debloat7 Telemetry Block Start <<<"
$Script:BlockMarkerEnd = "# >>> Win-Debloat7 Telemetry Block End <<<"

# Curated list of telemetry domains to block
$Script:TelemetryDomains = @(
    # Microsoft Telemetry Core
    "vortex.data.microsoft.com"
    "vortex-win.data.microsoft.com"
    "telecommand.telemetry.microsoft.com"
    "telecommand.telemetry.microsoft.com.nsatc.net"
    "oca.telemetry.microsoft.com"
    "oca.telemetry.microsoft.com.nsatc.net"
    "sqm.telemetry.microsoft.com"
    "sqm.telemetry.microsoft.com.nsatc.net"
    "watson.telemetry.microsoft.com"
    "watson.telemetry.microsoft.com.nsatc.net"
    "redir.metaservices.microsoft.com"
    "choice.microsoft.com"
    "choice.microsoft.com.nsatc.net"
    "df.telemetry.microsoft.com"
    "reports.wes.df.telemetry.microsoft.com"
    "wes.df.telemetry.microsoft.com"
    "services.wes.df.telemetry.microsoft.com"
    "sqm.df.telemetry.microsoft.com"
    "telemetry.microsoft.com"
    "watson.ppe.telemetry.microsoft.com"
    "telemetry.appex.bing.net"
    "telemetry.urs.microsoft.com"
    "telemetry.appex.bing.net:443"
    "settings-sandbox.data.microsoft.com"
    "settings-win.data.microsoft.com"
    "statsfe2.ws.microsoft.com"
    "statsfe1.ws.microsoft.com"
    "statsfe2.update.microsoft.com.akadns.net"
    
    # Cortana & Search
    "www.bing.com"  # Comment out if you use Bing
    # "search.msn.com"  # Breaks some search features
    
    # Advertising
    "ads.msn.com"
    "ads1.msads.net"
    "ads1.msn.com"
    "a.ads1.msn.com"
    "a.ads2.msn.com"
    "adnexus.net"
    "adnxs.com"
    "az361816.vo.msecnd.net"
    "az512334.vo.msecnd.net"
    
    # Windows Spotlight & Tips
    "arc.msn.com"
    "g.msn.com"
    "ris.api.iris.microsoft.com"
    
    # Location Tracking
    "inference.location.live.net"
    "location-inference-westus.cloudapp.net"
    
    # Error Reporting (comment if you want crash reports)
    # "watson.live.com"
    # "watson.microsoft.com"
    
    # Feedback Hub
    "feedback.windows.com"
    "feedback.microsoft-hohm.com"
    "feedback.search.microsoft.com"
)

#endregion

#region Hosts Functions

<#
.SYNOPSIS
    Backs up the current hosts file.
    
.OUTPUTS
    [string] Path to the backup file.
#>
function Backup-HostsFile {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param()
    
    if (-not (Test-Path $Script:BackupPath)) {
        New-Item -Path $Script:BackupPath -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFile = "$Script:BackupPath\hosts-backup-$timestamp"
    
    if ($PSCmdlet.ShouldProcess($Script:HostsFilePath, "Backup to $backupFile")) {
        try {
            Copy-Item -Path $Script:HostsFilePath -Destination $backupFile -Force
            Write-Log -Message "Hosts file backed up to: $backupFile" -Level Success
            return $backupFile
        }
        catch {
            Write-Log -Message "Failed to backup hosts file: $($_.Exception.Message)" -Level Error
            return $null
        }
    }
}

<#
.SYNOPSIS
    Adds telemetry blocking entries to the hosts file.
    
.DESCRIPTION
    Appends entries to block known telemetry domains. Creates a backup first.
    Entries are marked so they can be cleanly removed later.
    
.PARAMETER SkipBackup
    Skip creating a backup (not recommended).
#>
function Add-WinDebloat7HostsBlock {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [switch]$SkipBackup
    )
    
    # Check if already blocked
    $currentContent = Get-Content $Script:HostsFilePath -Raw -ErrorAction SilentlyContinue
    if ($currentContent -match [regex]::Escape($Script:BlockMarkerStart)) {
        Write-Log -Message "Telemetry blocks already present in hosts file." -Level Info
        return
    }
    
    # Backup
    if (-not $SkipBackup) {
        $backup = Backup-HostsFile
        if (-not $backup) {
            Write-Log -Message "Aborting - backup failed." -Level Error
            return
        }
    }
    
    Write-Log -Message "Adding telemetry blocks to hosts file..." -Level Info
    
    # Build block content
    $blockContent = @()
    $blockContent += ""
    $blockContent += $Script:BlockMarkerStart
    $blockContent += "# Added by Win-Debloat7 on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $blockContent += "# To remove: Run Remove-WinDebloat7HostsBlock or delete this section"
    $blockContent += ""
    
    foreach ($domain in $Script:TelemetryDomains) {
        $blockContent += "0.0.0.0 $domain"
    }
    
    $blockContent += ""
    $blockContent += $Script:BlockMarkerEnd
    
    if ($PSCmdlet.ShouldProcess($Script:HostsFilePath, "Add $($Script:TelemetryDomains.Count) blocked domains")) {
        try {
            Add-Content -Path $Script:HostsFilePath -Value ($blockContent -join "`n") -Encoding UTF8
            
            # Flush DNS cache
            Clear-DnsClientCache
            
            Write-Log -Message "Added $($Script:TelemetryDomains.Count) telemetry blocks to hosts file." -Level Success
        }
        catch {
            Write-Log -Message "Failed to modify hosts file: $($_.Exception.Message)" -Level Error
        }
    }
}

<#
.SYNOPSIS
    Removes Win-Debloat7 telemetry blocks from hosts file.
#>
function Remove-WinDebloat7HostsBlock {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()
    
    Write-Log -Message "Removing telemetry blocks from hosts file..." -Level Info
    
    try {
        $content = Get-Content $Script:HostsFilePath -Raw
        
        # Check if blocks exist
        if ($content -notmatch [regex]::Escape($Script:BlockMarkerStart)) {
            Write-Log -Message "No Win-Debloat7 blocks found in hosts file." -Level Info
            return
        }
        
        # Remove the blocked section
        $pattern = "$([regex]::Escape($Script:BlockMarkerStart))[\s\S]*?$([regex]::Escape($Script:BlockMarkerEnd))"
        $newContent = $content -replace $pattern, ""
        
        # Clean up extra blank lines
        $newContent = $newContent -replace "(\r?\n){3,}", "`n`n"
        
        if ($PSCmdlet.ShouldProcess($Script:HostsFilePath, "Remove telemetry blocks")) {
            Set-Content -Path $Script:HostsFilePath -Value $newContent.Trim() -Encoding UTF8
            
            # Flush DNS cache
            Clear-DnsClientCache
            
            Write-Log -Message "Telemetry blocks removed from hosts file." -Level Success
        }
    }
    catch {
        Write-Log -Message "Failed to modify hosts file: $($_.Exception.Message)" -Level Error
    }
}

<#
.SYNOPSIS
    Gets the current status of hosts file blocking.
    
.OUTPUTS
    [psobject] Status object.
#>
function Get-WinDebloat7HostsStatus {
    [CmdletBinding()]
    [OutputType([psobject])]
    param()
    
    $content = Get-Content $Script:HostsFilePath -Raw -ErrorAction SilentlyContinue
    
    $isBlocked = $content -match [regex]::Escape($Script:BlockMarkerStart)
    
    $blockedCount = 0
    if ($isBlocked) {
        $blockedCount = ([regex]::Matches($content, "^0\.0\.0\.0 ", [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
    }
    
    # Get last backup
    $lastBackup = Get-ChildItem "$Script:BackupPath\hosts-backup-*" -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1
    
    return [pscustomobject]@{
        HostsFilePath           = $Script:HostsFilePath
        TelemetryBlocked        = $isBlocked
        BlockedDomainCount      = $blockedCount
        AvailableDomainsToBlock = $Script:TelemetryDomains.Count
        LastBackup              = $lastBackup.FullName
        LastBackupDate          = $lastBackup.LastWriteTime
    }
}

<#
.SYNOPSIS
    Gets the list of domains that will be blocked.
    
.OUTPUTS
    [string[]] Array of domain names.
#>
function Get-WinDebloat7TelemetryDomains {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()
    
    return $Script:TelemetryDomains
}

#endregion

Export-ModuleMember -Function @(
    'Backup-HostsFile',
    'Add-WinDebloat7HostsBlock',
    'Remove-WinDebloat7HostsBlock',
    'Get-WinDebloat7HostsStatus',
    'Get-WinDebloat7TelemetryDomains'
)
