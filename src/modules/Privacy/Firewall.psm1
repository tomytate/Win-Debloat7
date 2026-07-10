<#
.SYNOPSIS
    Firewall management module for Win-Debloat7
    
.DESCRIPTION
    Manages Windows Defender Firewall to block telemetry endpoints.
    Replaces the legacy, ineffective hosts file blocking method.
    
.NOTES
    Module: Win-Debloat7.Modules.Privacy.Firewall
    Version: 1.4.0
#>

#Requires -Version 7.6
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force

#region Blocked Domains
$Script:HostsFilePath = "$env:SystemRoot\System32\drivers\etc\hosts"
$Script:BlockMarkerStart = "# >>> Win-Debloat7 Telemetry Block Start <<<"
$Script:BlockMarkerEnd = "# >>> Win-Debloat7 Telemetry Block End <<<"
$Script:FirewallRuleName = "WinDebloat7-Telemetry-Block"

# Curated list of telemetry domains to block
$Script:TelemetryDomains = @(
    "vortex.data.microsoft.com",
    "vortex-win.data.microsoft.com",
    "telecommand.telemetry.microsoft.com",
    "telecommand.telemetry.microsoft.com.nsatc.net",
    "oca.telemetry.microsoft.com",
    "oca.telemetry.microsoft.com.nsatc.net",
    "sqm.telemetry.microsoft.com",
    "sqm.telemetry.microsoft.com.nsatc.net",
    "watson.telemetry.microsoft.com",
    "watson.telemetry.microsoft.com.nsatc.net",
    "redir.metaservices.microsoft.com",
    "choice.microsoft.com",
    "choice.microsoft.com.nsatc.net",
    "df.telemetry.microsoft.com",
    "reports.wes.df.telemetry.microsoft.com",
    "wes.df.telemetry.microsoft.com",
    "services.wes.df.telemetry.microsoft.com",
    "sqm.df.telemetry.microsoft.com",
    "telemetry.microsoft.com",
    "watson.ppe.telemetry.microsoft.com",
    "telemetry.appex.bing.net",
    "telemetry.urs.microsoft.com",
    "telemetry.appex.bing.net:443",
    "settings-sandbox.data.microsoft.com",
    "settings-win.data.microsoft.com",
    "statsfe2.ws.microsoft.com",
    "statsfe1.ws.microsoft.com",
    "statsfe2.update.microsoft.com.akadns.net",
    "ads.msn.com",
    "ads1.msads.net",
    "ads1.msn.com",
    "a.ads1.msn.com",
    "a.ads2.msn.com",
    "adnexus.net",
    "adnxs.com",
    "az361816.vo.msecnd.net",
    "az512334.vo.msecnd.net",
    "arc.msn.com",
    "g.msn.com",
    "ris.api.iris.microsoft.com",
    "inference.location.live.net",
    "location-inference-westus.cloudapp.net",
    "feedback.windows.com",
    "feedback.microsoft-hohm.com",
    "feedback.search.microsoft.com"
)
#endregion

#region Firewall Functions

<#
.SYNOPSIS
    Cleans up the deprecated hosts file block if it exists.
#>
function Remove-LegacyWinDebloat7HostsBlock {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try {
        if (-not (Test-Path $Script:HostsFilePath)) { return }
        if (-not $PSCmdlet.ShouldProcess($Script:HostsFilePath, "Remove legacy telemetry block")) { return }
        $content = Get-Content $Script:HostsFilePath -Raw -ErrorAction SilentlyContinue
        if ($content -match [regex]::Escape($Script:BlockMarkerStart)) {
            Write-Log -Message "Found legacy hosts file telemetry block. Cleaning up..." -Level Info
            $pattern = "$([regex]::Escape($Script:BlockMarkerStart))[\s\S]*?$([regex]::Escape($Script:BlockMarkerEnd))"
            $newContent = $content -replace $pattern, ""
            $newContent = $newContent -replace "(\r?\n){3,}", "`n`n"
            Set-Content -Path $Script:HostsFilePath -Value $newContent.Trim() -Encoding UTF8
            Clear-DnsClientCache
            Write-Log -Message "Legacy hosts block removed successfully." -Level Success
        }
    }
    catch {
        Write-Log -Message "Failed to clean legacy hosts file: $($_.Exception.Message)" -Level Warning
    }
}

<#
.SYNOPSIS
    Adds telemetry blocking entries via Windows Defender Firewall.
#>
function Add-WinDebloat7FirewallBlock {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param()
    
    Remove-LegacyWinDebloat7HostsBlock
    
    Write-Log -Message "Adding telemetry blocks via Windows Firewall..." -Level Info
    
    if ($PSCmdlet.ShouldProcess("Windows Firewall", "Block $($Script:TelemetryDomains.Count) telemetry domains")) {
        try {
            $existingRules = Get-NetFirewallRule -DisplayName $Script:FirewallRuleName -ErrorAction SilentlyContinue
            if ($existingRules) {
                Remove-NetFirewallRule -DisplayName $Script:FirewallRuleName -ErrorAction SilentlyContinue
            }
            
            # Note: New-NetFirewallRule -RemoteAddress does not take FQDNs directly unless IPsec is used,
            # but Windows 11 allows FQDNs in WDAC/Firewall via specific configurations.
            # To be universally compatible, we resolve the domains to IPs first.
            
            $ipsToBlock = @()
            Write-Log -Message "Resolving telemetry domains to IPs (this may take a moment)..." -Level Info
            
            foreach ($domain in $Script:TelemetryDomains) {
                # Some entries might have ports like :443, strip them
                $cleanDomain = $domain -replace ':\d+$', ''
                try {
                    $ips = [System.Net.Dns]::GetHostAddresses($cleanDomain)
                    $ipsToBlock += $ips.IPAddressToString
                }
                catch {
                    Write-Verbose "Domain not resolvable (or already blocked): $cleanDomain"
                }
            }
            
            $ipsToBlock = $ipsToBlock | Select-Object -Unique
            
            if ($ipsToBlock.Count -gt 0) {
                # Split into chunks of 1000 IPs to avoid WMI command length limits
                $chunks = [Math]::Ceiling($ipsToBlock.Count / 1000)
                for ($i = 0; $i -lt $chunks; $i++) {
                    $chunkIps = $ipsToBlock | Select-Object -Skip ($i * 1000) -First 1000
                    New-NetFirewallRule -DisplayName $Script:FirewallRuleName -Direction Outbound -Action Block -RemoteAddress $chunkIps -ErrorAction Stop | Out-Null
                }
                Write-Log -Message "Added firewall rules blocking $($ipsToBlock.Count) telemetry IP addresses." -Level Success
            } else {
                Write-Log -Message "Could not resolve any telemetry domains. They may already be blocked at the DNS level." -Level Warning
            }
        }
        catch {
            Write-Log -Message "Failed to add firewall rules: $($_.Exception.Message)" -Level Error
        }
    }
}

<#
.SYNOPSIS
    Removes Win-Debloat7 telemetry blocks from Windows Firewall.
#>
function Remove-WinDebloat7FirewallBlock {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()
    
    Write-Log -Message "Removing telemetry firewall blocks..." -Level Info
    
    if ($PSCmdlet.ShouldProcess("Windows Firewall", "Remove telemetry blocks")) {
        try {
            $existingRules = Get-NetFirewallRule -DisplayName $Script:FirewallRuleName -ErrorAction SilentlyContinue
            if ($existingRules) {
                Remove-NetFirewallRule -DisplayName $Script:FirewallRuleName -ErrorAction Stop
                Write-Log -Message "Telemetry firewall blocks removed successfully." -Level Success
            } else {
                Write-Log -Message "No telemetry firewall blocks found." -Level Info
            }
            Remove-LegacyWinDebloat7HostsBlock
        }
        catch {
            Write-Log -Message "Failed to remove firewall rules: $($_.Exception.Message)" -Level Error
        }
    }
}

<#
.SYNOPSIS
    Gets the current status of firewall blocking.
    
.OUTPUTS
    [psobject] Status object.
#>
function Get-WinDebloat7FirewallStatus {
    [CmdletBinding()]
    [OutputType([psobject])]
    param()
    
    $existingRules = Get-NetFirewallRule -DisplayName $Script:FirewallRuleName -ErrorAction SilentlyContinue
    $isBlocked = [bool]$existingRules
    
    $blockedCount = 0
    if ($isBlocked) {
        $blockedCount = $existingRules.Count # Represents rule chunks, not raw IPs
    }
    
    return [pscustomobject]@{
        FirewallRuleName        = $Script:FirewallRuleName
        TelemetryBlocked        = $isBlocked
        BlockedDomainCount      = $blockedCount
        AvailableDomainsToBlock = $Script:TelemetryDomains.Count
    }
}

<#
.SYNOPSIS
    Gets the list of domains that will be blocked.
#>
function Get-WinDebloat7TelemetryDomains {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()
    
    return $Script:TelemetryDomains
}

#endregion

Export-ModuleMember -Function @(
    'Add-WinDebloat7FirewallBlock',
    'Remove-WinDebloat7FirewallBlock',
    'Get-WinDebloat7FirewallStatus',
    'Get-WinDebloat7TelemetryDomains'
)
