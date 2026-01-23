@{
    # Script module or binary module file associated with this manifest.
    # Script module or binary module file associated with this manifest.
    # RootModule        = ''

    # Version number of this module.
    ModuleVersion     = '1.1.0'

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
        'src\core\State.psm1',
        'src\core\SystemState.psm1',
        'src\core\Registry.psm1',
        'src\modules\Bloatware\Bloatware.psm1',
        'src\modules\Privacy\Privacy.psm1',
        'src\modules\Performance\Performance.psm1',
        'src\modules\Performance\Gaming.psm1',
        'src\modules\Windows11\Version-Detection.psm1',
        'src\modules\Software\Software.psm1',
        'src\modules\Drivers\Drivers.psm1',
        'src\modules\Network\Network.psm1',
        'src\modules\Privacy\Tasks.psm1',
        'src\modules\Privacy\Hosts.psm1',
        'src\modules\Extras\Extras.psm1',
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
        'Get-WinDebloat7BloatwareList', 'Remove-WinDebloat7Bloatware',
        'Set-WinDebloat7Privacy',
        'Set-WinDebloat7Performance',
        'Set-WinDebloat7Gaming',
        'Get-WindowsVersionInfo', 'Test-Windows11Version', 'Clear-WindowsVersionCache',
        # Software
        'Test-PackageManager', 'Install-PackageManager', 'Get-WinDebloat7EssentialsList',
        'Install-WinDebloat7Software', 'Install-WinDebloat7Essentials', 'Install-WinDebloat7ProfileSoftware',
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
        # Extras (only available in Extras edition)
        'Invoke-WinDebloat7DefenderRemover', 'Invoke-WinDebloat7Activation',
        # UI
        'Show-MainMenu', 'Show-WinDebloat7GUI'
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
## v1.1.0 (2026-01-23)
- NEW: Premium WPF GUI (Press 2) with System Health Dashboard
- NEW: Defender Remover & Windows Activation (CLI Extras)
- NEW: Microsoft Office 365 (Online Installer) support
- IMPROVED: PowerShell 7.5 optimizations (List[T], CliXml)
- FIXED: Copilot detection & UI freezing issues
'@
        }
    }
}

