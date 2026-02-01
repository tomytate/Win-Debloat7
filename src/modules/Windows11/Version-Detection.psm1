<#
.SYNOPSIS
    Version detection for Windows 11 and 25H2 support.
    
.DESCRIPTION
    Provides functions to detect specific Windows 11 versions and feature updates.
    Includes result caching to prevent repeated CIM queries (PERF-001 fix).
    
.NOTES
    Module: Win-Debloat7.Modules.Windows11.VersionDetection
    Version: 1.2.5
    
.LINK
    https://learn.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-75
#>

#Requires -Version 7.5

using namespace System.Management.Automation

class WindowsVersionInfo {
    [string]$ProductName
    [string]$DisplayVersion
    [int]$BuildNumber
    [string]$FriendlyName
    [bool]$IsWindows11
}

# Cache to prevent repeated CIM queries (PERF-001 fix)
$Script:CachedVersionInfo = $null
$Script:CacheTimestamp = [datetime]::MinValue
$Script:CacheLifetimeMinutes = 5

<#
.SYNOPSIS
    Gets information about the current Windows version.
    
.DESCRIPTION
    Returns a WindowsVersionInfo object containing OS details.
    Results are cached for 5 minutes to improve performance.
    
.PARAMETER Force
    Forces a fresh query, bypassing the cache.
    
.OUTPUTS
    [WindowsVersionInfo]
    
.EXAMPLE
    $ver = Get-WindowsVersionInfo
    Write-Host "Running $($ver.FriendlyName)"
#>
function Get-WindowsVersionInfo {
    [CmdletBinding()]
    [OutputType([WindowsVersionInfo])]
    param(
        [switch]$Force,
        [psobject]$TestOS # For Unit Testing
    )
    
    # PERF-001 fix: Return cached result if valid (skip if testing)
    $now = Get-Date
    if (-not $TestOS -and -not $Force -and $Script:CachedVersionInfo -and 
        ($now - $Script:CacheTimestamp).TotalMinutes -lt $Script:CacheLifetimeMinutes) {
        return $Script:CachedVersionInfo
    }
    
    $os = if ($TestOS) { $TestOS } else { Get-CimInstance Win32_OperatingSystem }
    $build = [int]$os.BuildNumber
    
    $info = [WindowsVersionInfo]::new()
    $info.ProductName = $os.Caption
    $info.BuildNumber = $build
    $info.IsWindows11 = $build -ge 22000
    
    # Try to get DisplayVersion from registry
    try {
        $info.DisplayVersion = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "DisplayVersion" -ErrorAction Stop
    }
    catch {
        $info.DisplayVersion = "Unknown"
    }
    
    # Determine Friendly Name based on build number
    $info.FriendlyName = switch ($build) {
        { $_ -ge 26200 } { "25H2" }
        { $_ -ge 26100 } { "24H2" }
        { $_ -ge 22631 } { "23H2" }
        { $_ -ge 22621 } { "22H2" }
        { $_ -ge 22000 } { "21H2" }
        default { "Windows 10 / Older" }
    }
    
    # Update cache
    $Script:CachedVersionInfo = $info
    $Script:CacheTimestamp = $now
    
    return $info
}

<#
.SYNOPSIS
    Tests if the current Windows version meets a minimum requirement.
    
.PARAMETER MinimumVersion
    The minimum Windows 11 version to check for.
    
.OUTPUTS
    [bool] True if current version meets or exceeds minimum.
    
.EXAMPLE
    if (Test-Windows11Version -MinimumVersion "23H2") { ... }
#>
function Test-Windows11Version {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("21H2", "22H2", "23H2", "24H2", "25H2")]
        [string]$MinimumVersion,
        
        [psobject]$TestOS # For Unit Testing
    )
    
    $current = Get-WindowsVersionInfo -TestOS $TestOS
    if (-not $current.IsWindows11) { return $false }
    
    $minBuild = switch ($MinimumVersion) {
        "21H2" { 22000 }
        "22H2" { 22621 }
        "23H2" { 22631 }
        "24H2" { 26100 }
        "25H2" { 26200 }
    }
    
    return $current.BuildNumber -ge $minBuild
}

<#
.SYNOPSIS
    Clears the version info cache.
#>
function Clear-WindowsVersionCache {
    [CmdletBinding()]
    [OutputType([void])]
    param()
    
    $Script:CachedVersionInfo = $null
    $Script:CacheTimestamp = [datetime]::MinValue
}

Export-ModuleMember -Function Get-WindowsVersionInfo, Test-Windows11Version, Clear-WindowsVersionCache
