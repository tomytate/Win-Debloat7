<#
.SYNOPSIS
    State management and snapshot module for Win-Debloat7
    
.DESCRIPTION
    Handles creating system snapshots and restoring system state.
    Uses PowerShell 7.5 ConvertTo-CliXml for robust serialization.
    
.NOTES
    Module: Win-Debloat7.Core.State
    Version: 1.1.0
    
.LINK
    https://learn.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-75
#>

#Requires -Version 7.5

using namespace System.Management.Automation
using namespace System.Collections.Generic
using namespace System.Security.Cryptography

Import-Module "$PSScriptRoot\Logger.psm1" -Force
Import-Module "$PSScriptRoot\Registry.psm1" -Force

class SystemSnapshot {
    [string]$Id
    [datetime]$Timestamp
    [string]$Name
    [string]$Description
    [hashtable]$Registry
    [array]$Services
    [string]$Version = "1.1.0"
}

# Cache for version info (PERF-001 fix)
$Script:CachedVersionInfo = $null

<#
.SYNOPSIS
    Creates a new system snapshot for restoration purposes.
    
.DESCRIPTION
    Captures current system state including services and registry keys.
    Uses CLIXML serialization for reliable data preservation.
    
.PARAMETER Name
    A friendly name for the snapshot.
    
.PARAMETER Description
    Optional description of the snapshot.
    
.PARAMETER Encrypt
    If specified, encrypts the snapshot using DPAPI.
    
.OUTPUTS
    [SystemSnapshot] The created snapshot object.
    
.EXAMPLE
    New-WinDebloat7Snapshot -Name "Pre-Optimization"
#>
function New-WinDebloat7Snapshot {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([SystemSnapshot])]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Name = "Auto-Snapshot",
        
        [string]$Description,
        
        [switch]$Encrypt
    )
    
    Write-Log -Message "Creating system snapshot: $Name" -Level Info
    
    $snapshot = [SystemSnapshot]::new()
    $snapshot.Id = [guid]::NewGuid().ToString()
    $snapshot.Timestamp = Get-Date
    $snapshot.Name = $Name
    $snapshot.Description = $Description
    
    # 1. Capture Services (PERF-002 fix: Filter to relevant services)
    $relevantServicePatterns = @(
        'DiagTrack', 'Telemetry', 'BITS', 'wuauserv', 'UsoSvc',
        'Xbox*', 'Copilot', 'Connected*', 'dmwappushservice'
    )
    
    $serviceFilter = { 
        $svc = $_.Name
        $relevantServicePatterns | Where-Object { $svc -like $_ } 
    }
    
    try {
        $snapshot.Services = @(
            Get-Service | Where-Object $serviceFilter | 
            Select-Object Name, Status, StartType, DisplayName
        )
        Write-Log -Message "Captured $($snapshot.Services.Count) relevant services" -Level Debug
    }
    catch {
        Write-Log -Message "Failed to capture services: $($_.Exception.Message)" -Level Warning
        $snapshot.Services = @()
    }
    
    # 2. Capture Critical Registry Keys
    $criticalRegistryPaths = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
    )
    
    $snapshot.Registry = @{}
    foreach ($regPath in $criticalRegistryPaths) {
        if (Test-Path $regPath) {
            try {
                $props = Get-ItemProperty -Path $regPath -ErrorAction Stop
                $snapshot.Registry[$regPath] = $props
            }
            catch {
                Write-Log -Message "Could not capture registry: $regPath" -Level Debug
            }
        }
    }
    
    # Save to disk
    $basePath = "$env:ProgramData\Win-Debloat7\Snapshots\$($snapshot.Id)"
    
    try {
        if ($PSCmdlet.ShouldProcess($basePath, "Create Snapshot")) {
            New-Item -Path $basePath -ItemType Directory -Force | Out-Null
            
            # Use PS 7.5 ConvertTo-CliXml for robust serialization
            $cliXml = $snapshot | ConvertTo-CliXml
            
            if ($Encrypt) {
                # SEC-005 fix: Encrypt snapshot using DPAPI
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($cliXml)
                $encrypted = [System.Security.Cryptography.ProtectedData]::Protect(
                    $bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser
                )
                [System.IO.File]::WriteAllBytes("$basePath\snapshot.encrypted", $encrypted)
                Write-Log -Message "Snapshot saved (encrypted): $($snapshot.Id)" -Level Success
            }
            else {
                $cliXml | Out-File -FilePath "$basePath\snapshot.clixml" -Encoding UTF8
                Write-Log -Message "Snapshot saved: $($snapshot.Id)" -Level Success
            }
        }
    }
    catch {
        Write-Log -Message "Failed to save snapshot: $($_.Exception.Message)" -Level Error
        throw
    }
    
    return $snapshot
}

<#
.SYNOPSIS
    Restores a previously created system snapshot.
    
.PARAMETER SnapshotId
    The unique ID of the snapshot to restore.
    
.OUTPUTS
    [void]
#>
function Restore-WinDebloat7Snapshot {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SnapshotId
    )
    
    $basePath = "$env:ProgramData\Win-Debloat7\Snapshots\$SnapshotId"
    $clixmlPath = "$basePath\snapshot.clixml"
    $encryptedPath = "$basePath\snapshot.encrypted"
    
    # Try to load snapshot
    $snapshot = $null
    
    if (Test-Path $clixmlPath) {
        try {
            $content = Get-Content $clixmlPath -Raw
            $snapshot = $content | ConvertFrom-CliXml
        }
        catch {
            Write-Log -Message "Failed to load snapshot: $($_.Exception.Message)" -Level Error
            throw "Snapshot ID not found or corrupted: $SnapshotId"
        }
    }
    elseif (Test-Path $encryptedPath) {
        try {
            $encrypted = [System.IO.File]::ReadAllBytes($encryptedPath)
            $decrypted = [System.Security.Cryptography.ProtectedData]::Unprotect(
                $encrypted, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser
            )
            $clixml = [System.Text.Encoding]::UTF8.GetString($decrypted)
            $snapshot = $clixml | ConvertFrom-CliXml
        }
        catch {
            Write-Log -Message "Failed to decrypt snapshot: $($_.Exception.Message)" -Level Error
            throw "Snapshot decryption failed for: $SnapshotId"
        }
    }
    else {
        throw "Snapshot ID not found: $SnapshotId"
    }
    
    Write-Log -Message "Restoring Snapshot: $($snapshot.Name) ($($snapshot.Timestamp))" -Level Info
    
    $successCount = 0
    $failCount = 0
    
    # 1. Restore Services
    foreach ($svc in $snapshot.Services) {
        try {
            $current = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
            if ($current -and $current.StartType -ne $svc.StartType) {
                if ($PSCmdlet.ShouldProcess($svc.Name, "Restore Service to $($svc.StartType)")) {
                    Write-Log -Message "Restoring Service: $($svc.Name) to $($svc.StartType)" -Level Info
                    Set-Service -Name $svc.Name -StartupType $svc.StartType -ErrorAction Stop
                    $successCount++
                }
            }
        }
        catch {
            Write-Log -Message "Failed to restore service $($svc.Name): $($_.Exception.Message)" -Level Warning
            $failCount++
        }
    }
    
    # 2. Restore Registry
    foreach ($regPath in $snapshot.Registry.Keys) {
        $regData = $snapshot.Registry[$regPath]
        if ($regData) {
            foreach ($prop in $regData.PSObject.Properties) {
                if ($prop.Name -notmatch '^PS') {
                    # Skip PS* internal properties
                    if (Set-RegistryKey -Path $regPath -Name $prop.Name -Value $prop.Value) {
                        $successCount++
                    }
                    else {
                        $failCount++
                    }
                }
            }
        }
    }
    
    Write-Log -Message "Restore completed: $successCount succeeded, $failCount failed" -Level $(if ($failCount -eq 0) { "Success" } else { "Warning" })
}

<#
.SYNOPSIS
    Lists all available snapshots.
    
.OUTPUTS
    [SystemSnapshot[]] Array of snapshot objects.
#>
function Get-WinDebloat7Snapshot {
    [CmdletBinding()]
    [OutputType([SystemSnapshot[]])]
    param()
    
    $basePath = "$env:ProgramData\Win-Debloat7\Snapshots"
    
    if (-not (Test-Path $basePath)) {
        return @()
    }
    
    $snapshots = @(
        Get-ChildItem $basePath -Directory | ForEach-Object {
            $clixmlPath = Join-Path $_.FullName "snapshot.clixml"
            $encryptedPath = Join-Path $_.FullName "snapshot.encrypted"
            
            if (Test-Path $clixmlPath) {
                try {
                    $content = Get-Content $clixmlPath -Raw
                    $content | ConvertFrom-CliXml
                }
                catch {
                    Write-Log -Message "Could not read snapshot: $($_.FullName)" -Level Debug
                }
            }
            elseif (Test-Path $encryptedPath) {
                # Return metadata only for encrypted snapshots
                [PSCustomObject]@{
                    Id        = $_.Name
                    Name      = "(Encrypted)"
                    Timestamp = $_.CreationTime
                    Encrypted = $true
                }
            }
        }
    )
    
    return $snapshots
}

Export-ModuleMember -Function New-WinDebloat7Snapshot, Restore-WinDebloat7Snapshot, Get-WinDebloat7Snapshot
