<#
.SYNOPSIS
    State management and snapshot module for Win-Debloat7

.DESCRIPTION
    Creates comprehensive, restorable system snapshots and performs true
    value-level rollback. The snapshot captures the full value-set of every
    registry key the framework can modify (see Get-WinDebloat7RegistryTargets)
    plus the state of the relevant services, so a restore returns the system
    to exactly the captured state:
      * changed values are re-set to their prior data and type,
      * values the framework added are deleted,
      * keys the framework created are removed.

.NOTES
    Module: Win-Debloat7.Core.State
    Version: 1.4.0
.LINK
    https://learn.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-76
#>

#Requires -Version 7.6

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
    [string]$Version = "1.4.0"
}

#region Registry target catalog

# The single source of truth for every registry key the framework may write.
# Derived from all Set-RegistryKey / Set-ItemProperty / Set-WinDebloat7RegistryValue
# call sites across the modules. Snapshots capture the direct values of these keys
# (not their subkeys), which keeps captures small while covering every change the
# framework makes. Keep this in sync when a module writes a new key.
$Script:RegistrySnapshotTargets = @(
    # ── Privacy / telemetry ─────────────────────────────────────────────
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy'
    'HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy'
    'HKCU:\SOFTWARE\Microsoft\Input\TIPC'
    'HKCU:\SOFTWARE\Microsoft\InputPersonalization'
    'HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore'
    'HKCU:\SOFTWARE\Microsoft\Personalization\Settings'
    'HKCU:\SOFTWARE\Microsoft\Siuf\Rules'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'
    'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice'
    'HKCU:\Control Panel\International\User Profile'

    # ── AI / Copilot / Recall ───────────────────────────────────────────
    'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
    'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    'HKCU:\Software\Microsoft\Notepad'
    'HKCU:\Software\Microsoft\Paint'

    # ── Suggestions / ads / spotlight ───────────────────────────────────
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.BackupReminder'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Mobility'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'

    # ── Performance / gaming ────────────────────────────────────────────
    'HKCU:\Control Panel\Desktop'
    'HKCU:\Control Panel\Desktop\WindowMetrics'
    'HKCU:\Control Panel\Mouse'
    'HKLM:\SYSTEM\CurrentControlSet\Control'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'
    'HKCU:\System\GameConfigStore'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'
    'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
    'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    'HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters'

    # ── System QoL / boot / updates ─────────────────────────────────────
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'
    'HKLM:\SYSTEM\CurrentControlSet\Control\Power'
    'HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
    'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
    'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9'
    'HKCU:\Control Panel\Accessibility\StickyKeys'
    'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
    'HKLM:\SOFTWARE\Microsoft\EdgeUpdate'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive'

    # ── Search / shell / Explorer / taskbar ─────────────────────────────
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
    'HKCU:\Software\Policies\Microsoft\Windows\Explorer'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Clipboard'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Start\Companions\Microsoft.YourPhone_8wekyb3d8bbwe'
    'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
    'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
    'HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
    # Gallery / Home navigation-pane pins (Set-WinDebloat7Explorer)
    'HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-ed25316e9424}'
    'HKLM:\SOFTWARE\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-ed25316e9424}'
    'HKLM:\SOFTWARE\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}'
    # "This PC" folder entries removed by Hide3DObjects / HideMusic
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}'
    'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}'
    'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}'
    # Shell context-menu handler keys deleted by Set-WinDebloat7ContextMenuItems.
    # Their identity lives in the DEFAULT (unnamed) value = handler CLSID, which
    # the snapshot captures so restore can recreate the handler. The '*' below is
    # a literal registry key name, not a wildcard - all snapshot operations use
    # -LiteralPath / raw .NET access.
    'Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\ModernSharing'
    'Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\Sharing'
    'Registry::HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\Sharing'
    'Registry::HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\Sharing'
    'Registry::HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers\Sharing'
    'Registry::HKEY_CLASSES_ROOT\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing'
    'Registry::HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\Library Location'
)

<#
.SYNOPSIS
    Returns the list of registry keys the framework may modify (and that
    snapshots therefore capture and restore).
#>
function Get-WinDebloat7RegistryTargets {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()
    return $Script:RegistrySnapshotTargets
}

# Maps a RegistryValueKind name to a Set-ItemProperty -Type value.
function ConvertTo-WD7RegistryType {
    param([string]$Kind)
    switch ($Kind) {
        'DWord' { 'DWord' }
        'QWord' { 'QWord' }
        'Binary' { 'Binary' }
        'MultiString' { 'MultiString' }
        'ExpandString' { 'ExpandString' }
        'String' { 'String' }
        default { 'String' }  # None / Unknown fall back to String
    }
}

# Opens (or creates) a registry key through the .NET API using a fully literal
# path. Required for cataloged keys whose names contain '*' (HKCR\*\shellex\...)
# where the PowerShell provider would treat the name as a wildcard, and for
# setting/removing DEFAULT (unnamed) values, which Set-RegistryKey cannot address.
# Returns a writable RegistryKey (caller must Close it) or $null.
function Get-WD7RawRegistryKey {
    [OutputType([Microsoft.Win32.RegistryKey])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Create
    )

    $hive = $null
    $subKey = $null
    switch -Regex ($Path) {
        '^HKLM:\\(.*)$' { $hive = [Microsoft.Win32.Registry]::LocalMachine; $subKey = $Matches[1]; break }
        '^HKCU:\\(.*)$' { $hive = [Microsoft.Win32.Registry]::CurrentUser; $subKey = $Matches[1]; break }
        '^Registry::HKEY_LOCAL_MACHINE\\(.*)$' { $hive = [Microsoft.Win32.Registry]::LocalMachine; $subKey = $Matches[1]; break }
        '^Registry::HKEY_CURRENT_USER\\(.*)$' { $hive = [Microsoft.Win32.Registry]::CurrentUser; $subKey = $Matches[1]; break }
        '^Registry::HKEY_CLASSES_ROOT\\(.*)$' { $hive = [Microsoft.Win32.Registry]::ClassesRoot; $subKey = $Matches[1]; break }
        '^Registry::HKEY_USERS\\(.*)$' { $hive = [Microsoft.Win32.Registry]::Users; $subKey = $Matches[1]; break }
        default { return $null }
    }

    if ($Create) { return $hive.CreateSubKey($subKey, $true) }
    return $hive.OpenSubKey($subKey, $true)
}

# Captures the direct values of one registry key: whether it exists, and each
# value's data + kind. The default (unnamed) value is captured under the key ''
# - it carries the payload for shell-extension handler keys (CLSID string).
function Get-WD7RegistryKeyState {
    param([string]$Path)

    # Note: key is named 'RegValues' (not 'Values') to avoid colliding with the
    # built-in Hashtable.Values property, which member access would resolve first.
    $state = @{ Existed = $false; RegValues = @{} }
    try {
        if (Test-Path -LiteralPath $Path) {
            $state['Existed'] = $true
            $key = Get-Item -LiteralPath $Path -ErrorAction Stop
            foreach ($valueName in $key.GetValueNames()) {
                $state['RegValues'][$valueName] = @{
                    # DoNotExpandEnvironmentNames keeps ExpandString values raw (e.g. %SystemRoot%)
                    Value = $key.GetValue($valueName, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                    Kind  = $key.GetValueKind($valueName).ToString()
                }
            }
        }
    }
    catch {
        Write-Verbose "Snapshot capture failed for '$Path': $($_.Exception.Message)"
    }
    return $state
}

# Restores a single registry key to a captured state. Returns @{ Success; Fail }.
# Factored out of Restore-WinDebloat7Snapshot so the rollback logic is unit-testable.
function Restore-WD7RegistryKey {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        $SnapState   # v1.4 hashtable { Existed; Values } OR legacy flat property object
    )

    $result = @{ Success = 0; Fail = 0 }

    # ── v1.4 value-level format ─────────────────────────────────────────
    # Use IDictionary + indexer access so it works whether $SnapState is a live
    # hashtable or one rehydrated from CLIXML.
    if ($SnapState -is [System.Collections.IDictionary] -and $SnapState.Contains('Existed')) {

        # (a) The framework created this key — remove it to fully revert.
        if (-not $SnapState['Existed']) {
            if (Test-Path -LiteralPath $Path) {
                if ($PSCmdlet.ShouldProcess($Path, "Remove framework-created key")) {
                    try {
                        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
                        Write-Log -Message "Removed created key: $Path" -Level Info
                        $result.Success++
                    }
                    catch {
                        Write-Log -Message "Failed to remove key '$Path': $($_.Exception.Message)" -Level Warning
                        $result.Fail++
                    }
                }
            }
            return $result
        }

        # (b) The key existed — make its values match the snapshot exactly.
        $snapValues = $SnapState['RegValues']

        # b1. Re-set each captured value to its prior data + type
        foreach ($valueName in @($snapValues.Keys)) {
            $entry = $snapValues[$valueName]
            $type = ConvertTo-WD7RegistryType -Kind $entry['Kind']
            $data = $entry['Value']
            # Coerce array types that CLIXML may have widened on deserialization
            if ($type -eq 'Binary' -and $null -ne $data) { $data = [byte[]]$data }
            elseif ($type -eq 'MultiString' -and $null -ne $data) { $data = [string[]]$data }

            # Default (unnamed) values, Registry::-prefixed paths, and paths with
            # literal wildcard characters ('*' key names) can't go through
            # Set-RegistryKey / the -Path provider - use the .NET API.
            if ([string]::IsNullOrEmpty($valueName) -or $Path -notmatch '^HK(LM|CU|CR|U|CC):\\' -or $Path -match '[\*\?\[\]]') {
                $display = if ([string]::IsNullOrEmpty($valueName)) { "$Path\(default)" } else { "$Path\$valueName" }
                if ($PSCmdlet.ShouldProcess($display, "Restore value")) {
                    $raw = $null
                    try {
                        $raw = Get-WD7RawRegistryKey -Path $Path -Create
                        if ($null -eq $raw) { throw "Unsupported registry hive in path" }
                        $raw.SetValue($valueName, $data, [Microsoft.Win32.RegistryValueKind]$entry['Kind'])
                        $result.Success++
                    }
                    catch {
                        Write-Log -Message "Failed to restore '$display': $($_.Exception.Message)" -Level Warning
                        $result.Fail++
                    }
                    finally {
                        if ($raw) { $raw.Close() }
                    }
                }
                continue
            }

            if (Set-RegistryKey -Path $Path -Name $valueName -Value $data -Type $type) { $result.Success++ }
            else { $result.Fail++ }
        }

        # b2. Delete values present now but absent from the snapshot (framework-added)
        try {
            if (Test-Path -LiteralPath $Path) {
                $nowKey = Get-Item -LiteralPath $Path -ErrorAction Stop
                foreach ($valueName in $nowKey.GetValueNames()) {
                    if ($snapValues.Contains($valueName)) { continue }
                    if ([string]::IsNullOrEmpty($valueName)) {
                        # PS7's registry provider can't address the default value
                        # by name for removal - delete it through the .NET API.
                        if ($PSCmdlet.ShouldProcess("$Path\(default)", "Remove framework-added value")) {
                            $raw = Get-WD7RawRegistryKey -Path $Path
                            if ($raw) {
                                try { $raw.DeleteValue('', $false); $result.Success++ }
                                finally { $raw.Close() }
                            }
                        }
                        continue
                    }
                    if ($PSCmdlet.ShouldProcess("$Path\$valueName", "Remove framework-added value")) {
                        Remove-ItemProperty -LiteralPath $Path -Name $valueName -Force -ErrorAction SilentlyContinue
                        $result.Success++
                    }
                }
            }
        }
        catch {
            Write-Verbose "Could not prune added values at '$Path': $($_.Exception.Message)"
        }

        return $result
    }

    # ── Legacy format (pre-1.4 snapshots stored a flat property object) ─
    if ($SnapState) {
        foreach ($prop in $SnapState.PSObject.Properties) {
            if ($prop.Name -notmatch '^PS') {
                $regType = switch ($prop.Value) {
                    { $_ -is [long] -or $_ -is [uint64] } { "QWord"; break }
                    { $_ -is [int] -or $_ -is [uint32] -or $_ -is [byte] -or $_ -is [int16] } { "DWord"; break }
                    { $_ -is [byte[]] } { "Binary"; break }
                    { $_ -is [string[]] } { "MultiString"; break }
                    default { "String" }
                }
                if (Set-RegistryKey -Path $Path -Name $prop.Name -Value $prop.Value -Type $regType) { $result.Success++ }
                else { $result.Fail++ }
            }
        }
    }

    return $result
}

#endregion

<#
.SYNOPSIS
    Creates a comprehensive, restorable system snapshot.

.DESCRIPTION
    Captures the direct values of every registry key the framework can modify
    plus the state of the relevant services, and also creates a Windows System
    Restore point as a second safety net.

.PARAMETER Name
    A friendly name for the snapshot.

.PARAMETER Description
    Optional description of the snapshot.

.PARAMETER Encrypt
    If specified, encrypts the snapshot using DPAPI (CurrentUser scope).

.OUTPUTS
    [SystemSnapshot] The created snapshot object.

.EXAMPLE
    New-WinDebloat7Snapshot -Name "Pre-Optimization" -Encrypt
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

    # Bypass the 24-hour restore point creation limit, then create one as a
    # second safety net alongside the framework's own registry snapshot.
    $rpKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
    try {
        if (Test-Path $rpKey) {
            Write-Log -Message "Bypassing Restore Point frequency limit..." -Level Debug
            Set-ItemProperty -Path $rpKey -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        }
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "$Name ($Description)" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Log -Message "Restore point created successfully." -Level Success
    }
    catch {
        Write-Log -Message "Restore point creation failed (non-critical): $($_.Exception.Message)" -Level Warning
    }

    # 1. Capture services (filtered to the ones the framework may change)
    $servicesJsonPath = Join-Path $PSScriptRoot "..\..\config\services.json"
    $relevantServicePatterns = @('BITS', 'wuauserv', 'UsoSvc', 'Xbox*', 'Copilot', 'Connected*', 'DiagTrack', 'AIFabric*', 'dmwappushservice', 'WaaSMedicSvc')
    if (Test-Path $servicesJsonPath) {
        try {
            $servicesDb = Get-Content $servicesJsonPath -Raw | ConvertFrom-Json
            $relevantServicePatterns += $servicesDb.services.psobject.properties.Name
        }
        catch {
            Write-Verbose "Could not load services.json for snapshot filtering: $($_.Exception.Message)"
        }
    }

    $serviceFilter = {
        $svc = $_.Name
        $relevantServicePatterns | Where-Object { $svc -like $_ }
    }

    try {
        $snapshot.Services = @(
            Get-Service -ErrorAction SilentlyContinue | Where-Object $serviceFilter |
            Select-Object Name, Status, StartType, DisplayName
        )
        Write-Log -Message "Captured $($snapshot.Services.Count) relevant services" -Level Debug
    }
    catch {
        Write-Log -Message "Failed to capture services: $($_.Exception.Message)" -Level Warning
        $snapshot.Services = @()
    }

    # 2. Capture the full value-set of every registry target (true rollback)
    $snapshot.Registry = @{}
    $capturedKeys = 0
    $capturedValues = 0
    foreach ($regPath in $Script:RegistrySnapshotTargets) {
        $keyState = Get-WD7RegistryKeyState -Path $regPath
        $snapshot.Registry[$regPath] = $keyState
        if ($keyState['Existed']) {
            $capturedKeys++
            $capturedValues += $keyState['RegValues'].Count
        }
    }
    Write-Log -Message "Captured $capturedValues values across $capturedKeys of $($Script:RegistrySnapshotTargets.Count) registry keys" -Level Debug

    # 3. Save to disk
    $basePath = "$env:ProgramData\Win-Debloat7\Snapshots\$($snapshot.Id)"
    try {
        if ($PSCmdlet.ShouldProcess($basePath, "Create Snapshot")) {
            New-Item -Path $basePath -ItemType Directory -Force | Out-Null

            $cliXml = $snapshot | ConvertTo-CliXml

            if ($Encrypt) {
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

            # Plaintext metadata sidecar so listings work for encrypted snapshots too
            [ordered]@{
                Id          = $snapshot.Id
                Name        = $snapshot.Name
                Description = $snapshot.Description
                Timestamp   = $snapshot.Timestamp.ToString("o")
                Encrypted   = [bool]$Encrypt
                Version     = $snapshot.Version
            } | ConvertTo-Json | Set-Content -Path "$basePath\meta.json" -Encoding UTF8
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
    Restores a previously created system snapshot (true value-level rollback).

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

    # Load snapshot (plain or DPAPI-encrypted)
    $snapshot = $null
    if (Test-Path $clixmlPath) {
        try {
            $snapshot = (Get-Content $clixmlPath -Raw) | ConvertFrom-CliXml
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

    # 1. Restore services
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

    # 2. Restore registry (per-key logic lives in the testable Restore-WD7RegistryKey)
    foreach ($regPath in $snapshot.Registry.Keys) {
        $r = Restore-WD7RegistryKey -Path $regPath -SnapState $snapshot.Registry[$regPath]
        $successCount += $r.Success
        $failCount += $r.Fail
    }

    Write-Log -Message "Restore completed: $successCount change(s) applied, $failCount failed" -Level $(if ($failCount -eq 0) { "Success" } else { "Warning" })
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
            $metaPath = Join-Path $_.FullName "meta.json"

            if (Test-Path $clixmlPath) {
                try {
                    (Get-Content $clixmlPath -Raw) | ConvertFrom-CliXml
                }
                catch {
                    Write-Log -Message "Could not read snapshot: $($_.FullName)" -Level Debug
                }
            }
            elseif (Test-Path $metaPath) {
                # Encrypted snapshot: use the plaintext metadata sidecar
                try {
                    $meta = Get-Content $metaPath -Raw | ConvertFrom-Json
                    [PSCustomObject]@{
                        Id        = $meta.Id
                        Name      = $meta.Name
                        Timestamp = [datetime]$meta.Timestamp
                        Encrypted = $true
                    }
                }
                catch {
                    Write-Log -Message "Could not read snapshot metadata: $metaPath" -Level Debug
                }
            }
            elseif (Test-Path $encryptedPath) {
                # Legacy encrypted snapshot without a metadata sidecar
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

Export-ModuleMember -Function New-WinDebloat7Snapshot, Restore-WinDebloat7Snapshot, Get-WinDebloat7Snapshot, Get-WinDebloat7RegistryTargets
