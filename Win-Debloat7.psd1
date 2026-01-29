@{
    # Script module or binary module file associated with this manifest.
    # Script module or binary module file associated with this manifest.
    # RootModule        = ''

    # Version number of this module.
    ModuleVersion     = '1.2.3'

    # ID used to uniquely identify this module
    GUID              = 'a1b2c3d4-e5f6-7890-1234-567890abcdef'

    # Author of this module
    Author            = 'Tomy Tolledo'

    # Company or vendor of this module
    CompanyName       = 'Open Source'

    # Copyright statement for this module
    Copyright         = '(c) 2026 Tomy Tolledo. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Power User Windows Optimization Framework (PowerShell 7.5+)'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '7.5'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules     = @(
        'src\core\Logger.psm1',
        'src\core\Config.psm1',
        'src\core\Registry.psm1',
        'src\core\State.psm1',
        'src\core\SystemState.psm1',
        'src\modules\Bloatware\Bloatware.psm1',
        'src\modules\Privacy\Privacy.psm1',
        'src\modules\Performance\Performance.psm1',
        'src\modules\Repair\Repair.psm1',
        'src\modules\Features\Features.psm1',
        'src\modules\Security\Security.psm1',
        'src\modules\Performance\Gaming.psm1',
        'src\modules\Performance\Benchmark.psm1',
        'src\modules\Maintenance\Maintenance.psm1',
        'src\modules\Windows11\Version-Detection.psm1',
        'src\modules\Software\Software.psm1',
        'src\modules\Drivers\Drivers.psm1',
        'src\modules\Network\Network.psm1',
        'src\modules\Privacy\Tasks.psm1',
        'src\modules\Privacy\Hosts.psm1',
        # Extras module excluded related to standard release
        'src\ui\Colors.psm1',
        'src\ui\Menu.psm1',
        'src\ui\gui\GUI.psm1'
    )

    # Functions to export from this module (CQ-002 fix: Explicit exports instead of wildcards)
    FunctionsToExport = @(
        # Core
        'Start-WD7Logging', 'Write-Log', 'Get-WD7LogPath',
        'Import-WinDebloat7Config', 'Test-WinDebloat7Config',
        'New-WinDebloat7Snapshot', 'Restore-WinDebloat7Snapshot', 'Get-WinDebloat7Snapshot',
        'Set-RegistryKey', 'Get-RegistryKey', 'Test-RegistryKey', 'Export-RegistryKey',
        # Modules
        'Get-WinDebloat7BloatwareList', 'Remove-WinDebloat7Bloatware', 'Uninstall-WinDebloat7OneDrive', 'Uninstall-WinDebloat7Edge', 'Uninstall-WinDebloat7Xbox', 'Disable-WinDebloat7AIandAds',
        'Set-WinDebloat7Privacy',
        'Set-WinDebloat7Performance',
        # Repair
        'Repair-WinDebloat7System', 'Reset-WinDebloat7Network', 'Reset-WinDebloat7Update',
        # Features
        'Set-WinDebloat7OptionalFeatures', 'Remove-WinDebloat7Capabilities',
        # Security
        'Disable-WinDebloat7SMBv1', 'Enable-WinDebloat7PUAProtection',
        'Set-WinDebloat7Gaming',
        'Measure-WinDebloat7System', 'Compare-WinDebloat7Benchmarks',
        'Get-WindowsVersionInfo', 'Test-Windows11Version', 'Clear-WindowsVersionCache',
        # Software
        'Test-PackageManager', 'Install-PackageManager', 'Get-WinDebloat7EssentialsList',
        'Install-WinDebloat7Software', 'Update-WinDebloat7Software', 'Install-WinDebloat7Essentials', 'Install-WinDebloat7ProfileSoftware',
        # Drivers
        'Get-WinDebloat7DriverStatus', 'Get-WinDebloat7GPUInfo', 'Update-WinDebloat7Drivers',
        # Network
        'Set-WinDebloat7DNS', 'Get-WinDebloat7DNSProviders', 'Disable-WinDebloat7IPv6', 'Enable-WinDebloat7IPv6',
        'Get-WinDebloat7NetworkStatus', 'Set-WinDebloat7Network',
        # Privacy Tasks
        'Get-WinDebloat7TelemetryTasks', 'Disable-WinDebloat7TelemetryTasks', 'Enable-WinDebloat7TelemetryTasks',
        # Hosts Blocking
        'Backup-HostsFile', 'Add-WinDebloat7HostsBlock', 'Remove-WinDebloat7HostsBlock',
        'Get-WinDebloat7HostsStatus', 'Get-WinDebloat7TelemetryDomains',
        # Maintenance
        'Register-WinDebloat7Maintenance', 'Unregister-WinDebloat7Maintenance', 'Invoke-WinDebloat7Maintenance',
        # Extras (only available in Extras edition)
        # UI
        'Show-MainMenu', 'Show-WinDebloat7GUI',
        'Write-WD7Host', 'Show-WD7Header', 'Show-WD7Separator', 'Show-WD7Progress', 'Show-WD7StatusBadge'
    )

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('Optimization', 'Debloat', 'Windows11', 'PowerShell7.5', 'Privacy', 'Performance')
            
            # Project URI
            ProjectUri   = 'https://github.com/tomytate/Win-Debloat7'
            
            # License URI
            LicenseUri   = 'https://github.com/tomytate/Win-Debloat7/blob/main/LICENSE'
            
            # Release Notes
            ReleaseNotes = @'
## v1.2.3 (2026-01-29) - Platinum Release
- NEW: PowerShell 7.5 Modernization (WebCmdlet Retry, #Requires enforcement)
- FIX: Benchmark Module syntax correction
- FIX: Hardened Test Suite (10/10 Verification)

## v1.2.2 (2026-01-29)
- FIX: Core Registry Export Stability
- FIX: Module Test Isolation logic

## v1.2.1 (2026-01-29)
- NEW: Auto-Install PowerShell 7.5 Dependency logic in Launcher
- FIX: Robustness improvements in Launcher (Wait-on-error)
- FIX: Software Update feature added (winget upgrade --all)
- NEW: GUI V2 "Command Center" (5-Tab Layout)
- NEW: System Tweaks Hub (Privacy/Performance/Network)
- NEW: Robust Windows 11 24H2 Detection
- NEW: Smart RAM & Connection Monitoring
'@
        }
    }
}

