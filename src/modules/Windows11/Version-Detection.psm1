<#
.SYNOPSIS
    Version detection for Windows 11 and 25H2 support.
    
.DESCRIPTION
    Provides functions to detect specific Windows 11 versions and feature updates.
    Includes result caching to prevent repeated CIM queries (PERF-001 fix).
    
.NOTES
    Module: Win-Debloat7.Modules.Windows11.VersionDetection
    Version: 1.4.0
.LINK
    https://learn.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-76
#>

#Requires -Version 7.6

using namespace System.Management.Automation

class WindowsVersionInfo {
    [string]$ProductName    # Raw CIM caption, e.g. "Microsoft Windows 11 Pro"
    [string]$Edition        # Home / Pro / Enterprise / Education...
    [string]$DisplayVersion # Feature-update label, e.g. "24H2"
    [string]$FriendlyName   # Feature-update label (alias of DisplayVersion)
    [int]$BuildNumber
    [int]$Ubr              # Update Build Revision (the .xxxx after the build)
    [bool]$IsWindows11
    [string]$FullName       # Composed, display-ready, e.g. "Windows 11 Pro"
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
    Write-Host "Running on $($ver.FriendlyName)"
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

    # Read the registry once for the authoritative feature-update label, edition,
    # and update revision. CIM's Caption is unreliable after in-place upgrades.
    # Skipped under -TestOS so unit tests exercise the build->label fallback map
    # deterministically instead of reading the host's real registry.
    $cvKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $displayVersion = $null
    $editionId = $null
    if (-not $TestOS) {
        try { $displayVersion = Get-ItemPropertyValue -Path $cvKey -Name "DisplayVersion" -ErrorAction Stop } catch { }
        if (-not $displayVersion) {
            # Pre-2004 builds used ReleaseId (e.g. "1909") instead of DisplayVersion
            try { $displayVersion = Get-ItemPropertyValue -Path $cvKey -Name "ReleaseId" -ErrorAction Stop } catch { }
        }
        try { $editionId = Get-ItemPropertyValue -Path $cvKey -Name "EditionID" -ErrorAction Stop } catch { }
        try { $info.Ubr = [int](Get-ItemPropertyValue -Path $cvKey -Name "UBR" -ErrorAction Stop) } catch { }
    }

    # Prefer the registry's DisplayVersion; fall back to a correct build->label map
    # (ordered elseif chain - the module's old switch had no 'break' and always
    # collapsed to "21H2" because every -ge condition matched).
    if ($displayVersion) {
        $info.DisplayVersion = $displayVersion
    }
    else {
        $info.DisplayVersion =
        if ($build -ge 26200) { "25H2" }
        elseif ($build -ge 26100) { "24H2" }
        elseif ($build -ge 22631) { "23H2" }
        elseif ($build -ge 22621) { "22H2" }
        elseif ($build -ge 22000) { "21H2" }
        elseif ($build -ge 19045) { "22H2" }   # Windows 10
        elseif ($build -ge 19044) { "21H2" }   # Windows 10
        elseif ($build -ge 19043) { "21H1" }   # Windows 10
        elseif ($build -ge 19042) { "20H2" }   # Windows 10
        elseif ($build -ge 19041) { "2004" }   # Windows 10
        elseif ($build -ge 18363) { "1909" }   # Windows 10
        else { "Legacy" }
    }
    $info.FriendlyName = $info.DisplayVersion

    # Edition: prefer EditionID (Core/Professional/Enterprise/...), else parse Caption
    $info.Edition =
    switch -Wildcard ($editionId) {
        "Core*" { "Home"; break }
        "Professional*" { "Pro"; break }
        "Enterprise*" { "Enterprise"; break }
        "Education*" { "Education"; break }
        "ServerStandard*" { "Server Standard"; break }
        "ServerDatacenter*" { "Server Datacenter"; break }
        default {
            $m = [regex]::Match($os.Caption, '(Home|Pro(?:fessional)?|Enterprise|Education|Server\s+\w+)')
            if ($m.Success) { $m.Value -replace 'Professional', 'Pro' } else { "" }
        }
    }

    # Compose a display-ready name; force the "11" label when the build says so
    # even if a stale Caption still reports Windows 10.
    $osFamily = if ($info.IsWindows11) { "Windows 11" }
    elseif ($build -ge 10240) { "Windows 10" }
    else { ($os.Caption -replace '^Microsoft\s+', '').Trim() }
    $info.FullName = (@($osFamily, $info.Edition) | Where-Object { $_ }) -join ' '

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
