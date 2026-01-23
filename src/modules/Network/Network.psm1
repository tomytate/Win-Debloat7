<#
.SYNOPSIS
    Network configuration module for Win-Debloat7
    
.DESCRIPTION
    Handles DNS configuration, IPv6 management, and network privacy settings.
    Supports multiple DNS providers with easy switching.
    
.NOTES
    Module: Win-Debloat7.Modules.Network
    Version: 1.0.0
    
.LINK
    https://learn.microsoft.com/powershell/scripting/whats-new/what-s-new-in-powershell-75
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force

#region DNS Providers

$Script:DNSProviders = @{
    Cloudflare = @{
        Name          = "Cloudflare (Privacy-Focused)"
        IPv4Primary   = "1.1.1.1"
        IPv4Secondary = "1.0.0.1"
        IPv6Primary   = "2606:4700:4700::1111"
        IPv6Secondary = "2606:4700:4700::1001"
    }
    Google     = @{
        Name          = "Google Public DNS"
        IPv4Primary   = "8.8.8.8"
        IPv4Secondary = "8.8.4.4"
        IPv6Primary   = "2001:4860:4860::8888"
        IPv6Secondary = "2001:4860:4860::8844"
    }
    Quad9      = @{
        Name          = "Quad9 (Security-Focused)"
        IPv4Primary   = "9.9.9.9"
        IPv4Secondary = "149.112.112.112"
        IPv6Primary   = "2620:fe::fe"
        IPv6Secondary = "2620:fe::9"
    }
    AdGuard    = @{
        Name          = "AdGuard DNS (Ad-Blocking)"
        IPv4Primary   = "94.140.14.14"
        IPv4Secondary = "94.140.15.15"
        IPv6Primary   = "2a10:50c0::ad1:ff"
        IPv6Secondary = "2a10:50c0::ad2:ff"
    }
    OpenDNS    = @{
        Name          = "OpenDNS (Cisco)"
        IPv4Primary   = "208.67.222.222"
        IPv4Secondary = "208.67.220.220"
        IPv6Primary   = "2620:119:35::35"
        IPv6Secondary = "2620:119:53::53"
    }
    NextDNS    = @{
        Name          = "NextDNS (Customizable)"
        IPv4Primary   = "45.90.28.0"
        IPv4Secondary = "45.90.30.0"
        IPv6Primary   = "2a07:a8c0::"
        IPv6Secondary = "2a07:a8c1::"
    }
}

#endregion

#region DNS Configuration

<#
.SYNOPSIS
    Sets DNS servers on all network adapters.
    
.PARAMETER Provider
    DNS provider preset: Cloudflare, Google, Quad9, AdGuard, OpenDNS, NextDNS.
    
.PARAMETER CustomPrimary
    Custom primary DNS server (use with -Provider Custom).
    
.PARAMETER CustomSecondary
    Custom secondary DNS server (use with -Provider Custom).
    
.PARAMETER IncludeIPv6
    Also set IPv6 DNS servers.
    
.EXAMPLE
    Set-WinDebloat7DNS -Provider Cloudflare
    
.EXAMPLE
    Set-WinDebloat7DNS -Provider Custom -CustomPrimary "1.2.3.4" -CustomSecondary "5.6.7.8"
#>
function Set-WinDebloat7DNS {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Cloudflare", "Google", "Quad9", "AdGuard", "OpenDNS", "NextDNS", "Custom", "Reset")]
        [string]$Provider,
        
        [string]$CustomPrimary,
        [string]$CustomSecondary,
        
        [switch]$IncludeIPv6
    )
    
    # Get active network adapters
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    if ($adapters.Count -eq 0) {
        Write-Log -Message "No active network adapters found." -Level Warning
        return
    }
    
    Write-Log -Message "Configuring DNS on $($adapters.Count) adapter(s)..." -Level Info
    
    # Determine DNS servers
    if ($Provider -eq "Reset") {
        # Reset to DHCP
        foreach ($adapter in $adapters) {
            if ($PSCmdlet.ShouldProcess($adapter.Name, "Reset DNS to DHCP")) {
                try {
                    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses
                    Write-Log -Message "Reset DNS on $($adapter.Name) to DHCP" -Level Success
                }
                catch {
                    Write-Log -Message "Failed to reset DNS on $($adapter.Name): $($_.Exception.Message)" -Level Error
                }
            }
        }
        return
    }
    elseif ($Provider -eq "Custom") {
        if (-not $CustomPrimary) {
            Write-Log -Message "Custom provider requires -CustomPrimary parameter." -Level Error
            return
        }
        $primary = $CustomPrimary
        $secondary = $CustomSecondary
        $providerName = "Custom"
    }
    else {
        $dns = $Script:DNSProviders[$Provider]
        $primary = $dns.IPv4Primary
        $secondary = $dns.IPv4Secondary
        $providerName = $dns.Name
    }
    
    $dnsServers = @($primary)
    if ($secondary) { $dnsServers += $secondary }
    
    foreach ($adapter in $adapters) {
        if ($PSCmdlet.ShouldProcess($adapter.Name, "Set DNS to $providerName")) {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $dnsServers
                Write-Log -Message "Set DNS on $($adapter.Name) to $providerName ($($dnsServers -join ', '))" -Level Success
                
                # IPv6 if requested
                if ($IncludeIPv6 -and $Provider -ne "Custom") {
                    $dns = $Script:DNSProviders[$Provider]
                    $ipv6Servers = @($dns.IPv6Primary, $dns.IPv6Secondary)
                    try {
                        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ($dnsServers + $ipv6Servers)
                        Write-Log -Message "Added IPv6 DNS servers" -Level Debug
                    }
                    catch {
                        Write-Log -Message "Failed to set IPv6 DNS: $($_.Exception.Message)" -Level Warning
                    }
                }
            }
            catch {
                Write-Log -Message "Failed to set DNS on $($adapter.Name): $($_.Exception.Message)" -Level Error
            }
        }
    }
    
    # Flush DNS cache
    Write-Log -Message "Flushing DNS cache..." -Level Info
    Clear-DnsClientCache
    Write-Log -Message "DNS configuration complete." -Level Success
}

<#
.SYNOPSIS
    Gets the list of available DNS providers.
    
.OUTPUTS
    [hashtable] DNS provider configurations.
#>
function Get-WinDebloat7DNSProviders {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    return $Script:DNSProviders
}

#endregion

#region IPv6 Management

<#
.SYNOPSIS
    Disables IPv6 on all network adapters.
    
.DESCRIPTION
    Disables IPv6 binding on all adapters. Some privacy tools recommend this
    to prevent IPv6 leaks, though it may break some network features.
#>
function Disable-WinDebloat7IPv6 {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param()
    
    Write-Log -Message "Disabling IPv6 on all adapters..." -Level Info
    
    $adapters = Get-NetAdapter
    $successCount = 0
    
    foreach ($adapter in $adapters) {
        if ($PSCmdlet.ShouldProcess($adapter.Name, "Disable IPv6")) {
            try {
                Disable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -ErrorAction Stop
                Write-Log -Message "Disabled IPv6 on $($adapter.Name)" -Level Success
                $successCount++
            }
            catch {
                Write-Log -Message "Failed to disable IPv6 on $($adapter.Name): $($_.Exception.Message)" -Level Warning
            }
        }
    }
    
    Write-Log -Message "IPv6 disabled on $successCount adapter(s)." -Level Success
}

<#
.SYNOPSIS
    Enables IPv6 on all network adapters.
#>
function Enable-WinDebloat7IPv6 {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()
    
    Write-Log -Message "Enabling IPv6 on all adapters..." -Level Info
    
    $adapters = Get-NetAdapter
    
    foreach ($adapter in $adapters) {
        if ($PSCmdlet.ShouldProcess($adapter.Name, "Enable IPv6")) {
            try {
                Enable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -ErrorAction Stop
                Write-Log -Message "Enabled IPv6 on $($adapter.Name)" -Level Success
            }
            catch {
                Write-Log -Message "Failed to enable IPv6 on $($adapter.Name): $($_.Exception.Message)" -Level Warning
            }
        }
    }
}

#endregion

#region Network Status

<#
.SYNOPSIS
    Gets the current network configuration status.
    
.OUTPUTS
    [psobject[]] Network adapter status objects.
#>
function Get-WinDebloat7NetworkStatus {
    [CmdletBinding()]
    [OutputType([psobject[]])]
    param()
    
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    $results = foreach ($adapter in $adapters) {
        $dnsServers = (Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4).ServerAddresses
        $ipv6Enabled = (Get-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6).Enabled
        
        # Try to identify DNS provider
        $provider = "Unknown"
        foreach ($providerName in $Script:DNSProviders.Keys) {
            $p = $Script:DNSProviders[$providerName]
            if ($dnsServers -contains $p.IPv4Primary) {
                $provider = $providerName
                break
            }
        }
        if ($dnsServers.Count -eq 0) { $provider = "DHCP" }
        
        [pscustomobject]@{
            Adapter     = $adapter.Name
            Status      = $adapter.Status
            DNSServers  = $dnsServers -join ", "
            DNSProvider = $provider
            IPv6Enabled = $ipv6Enabled
        }
    }
    
    return $results
}

<#
.SYNOPSIS
    Applies network settings from a profile configuration.
    
.PARAMETER Config
    The configuration object loaded from a YAML profile.
#>
function Set-WinDebloat7Network {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [psobject]$Config
    )
    
    if (-not $Config.network) {
        Write-Log -Message "No network configuration in profile." -Level Info
        return
    }
    
    # DNS Configuration
    if ($Config.network.dns_servers -and $Config.network.dns_servers.Count -gt 0) {
        $primary = $Config.network.dns_servers[0]
        $secondary = if ($Config.network.dns_servers.Count -gt 1) { $Config.network.dns_servers[1] } else { $null }
        
        # Check if it matches a known provider
        $matchedProvider = $null
        foreach ($providerName in $Script:DNSProviders.Keys) {
            if ($Script:DNSProviders[$providerName].IPv4Primary -eq $primary) {
                $matchedProvider = $providerName
                break
            }
        }
        
        if ($matchedProvider) {
            Set-WinDebloat7DNS -Provider $matchedProvider
        }
        else {
            Set-WinDebloat7DNS -Provider Custom -CustomPrimary $primary -CustomSecondary $secondary
        }
    }
    
    # IPv6
    if ($Config.network.disable_ipv6 -eq $true) {
        Disable-WinDebloat7IPv6
    }
}

#endregion

Export-ModuleMember -Function @(
    'Set-WinDebloat7DNS',
    'Get-WinDebloat7DNSProviders',
    'Disable-WinDebloat7IPv6',
    'Enable-WinDebloat7IPv6',
    'Get-WinDebloat7NetworkStatus',
    'Set-WinDebloat7Network'
)
