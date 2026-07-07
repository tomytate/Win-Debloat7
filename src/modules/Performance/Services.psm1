<#
.SYNOPSIS
    Service optimization module for Win-Debloat7.
    
.DESCRIPTION
    Manages Windows service startup types for privacy, performance, and security.
    Uses presets from config/services.json.
    
.NOTES
    Module: Win-Debloat7.Modules.Services
    Version: 1.3.1
#>

#Requires -Version 7.6
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force

#region Service Optimization

function Set-WinDebloat7Services {
    <#
    .SYNOPSIS
        Optimizes Windows service startup types based on a preset.
    
    .PARAMETER Preset
        The optimization preset: Privacy, Performance, Security, or Minimal.
    
    .PARAMETER ConfigPath
        Optional path to services.json configuration file.
    
    .EXAMPLE
        Set-WinDebloat7Services -Preset Privacy
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Privacy", "Performance", "Security", "Minimal", "Gaming")]
        [string]$Preset,

        [string]$ConfigPath = "$PSScriptRoot\..\..\..\config\services.json"
    )

    # Load services configuration
    if (-not (Test-Path $ConfigPath)) {
        Write-Log -Message "Services configuration not found: $ConfigPath" -Level Error
        return
    }

    try {
        # PS 7.5: Test-Json with -IgnoreComments available but we use standard parsing
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Log -Message "Failed to parse services.json: $($_.Exception.Message)" -Level Error
        return
    }

    if (-not $config.presets.$Preset) {
        Write-Log -Message "Preset '$Preset' not found in configuration." -Level Error
        return
    }

    $servicesToOptimize = $config.presets.$Preset
    Write-Log -Message "Applying '$Preset' preset ($($servicesToOptimize.Count) services)..." -Level Info

    $successCount = 0
    $failCount = 0

    # Optimized: Batch query all services first (O(1) lookup vs O(N) per service)
    Write-Log -Message "Querying service states..." -Level Info
    $validationList = @{}
    try {
        Get-Service -Name $servicesToOptimize -ErrorAction SilentlyContinue | ForEach-Object {
            $validationList[$_.Name] = $_
        }
    }
    catch {
        Write-Log -Message "Error querying services: $($_.Exception.Message)" -Level Warning
    }

    foreach ($serviceName in $servicesToOptimize) {
        $serviceConfig = $config.services.$serviceName

        if (-not $serviceConfig) {
            Write-Log -Message "Service config not found for: $serviceName" -Level Warning
            continue
        }

        $targetStartup = $serviceConfig.StartupType

        if ($PSCmdlet.ShouldProcess($serviceConfig.DisplayName, "Set startup to $targetStartup")) {
            try {
                if ($validationList.ContainsKey($serviceName)) {
                    $service = $validationList[$serviceName]
                }
                else {
                    # Fallback check if not found in batch (maybe stopped/hidden?)
                    $service = Get-Service -Name $serviceName -ErrorAction Stop
                }

                # Validate service can be modified - stop running services before disabling
                if ($service.Status -eq 'Running' -and $targetStartup -eq 'Disabled') {
                    Write-Log -Message "Stopping $serviceName before disabling..." -Level Info
                    Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
                }

                # Map startup type strings to valid Set-Service values
                $startupMapping = @{
                    "Disabled"              = "Disabled"
                    "Manual"                = "Manual"
                    "Automatic"             = "Automatic"
                    "AutomaticDelayedStart" = "AutomaticDelayedStart"
                }

                $mappedStartup = $startupMapping[$targetStartup]
                if (-not $mappedStartup) { $mappedStartup = "Manual" } # Default fallback

                Set-Service -Name $serviceName -StartupType $mappedStartup -ErrorAction Stop
                Write-Log -Message "Set $serviceName to $mappedStartup" -Level Success
                $successCount++
            }
            catch {
                Write-Log -Message "Failed to configure $serviceName : $($_.Exception.Message)" -Level Warning
                $failCount++
            }
        }
    }


    Write-Log -Message "Service optimization complete: $successCount succeeded, $failCount failed." -Level Info
}

function Get-WinDebloat7ServicePresets {
    <#
    .SYNOPSIS
        Gets available service optimization presets.
    
    .OUTPUTS
        [string[]] List of preset names.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return @("Privacy", "Performance", "Security", "Minimal", "Gaming")
}

function Get-WinDebloat7ServiceStatus {
    <#
    .SYNOPSIS
        Gets the current status of optimizable services.
    
    .OUTPUTS
        [psobject[]] Service status objects.
    #>
    [CmdletBinding()]
    [OutputType([psobject[]])]
    param(
        [string]$ConfigPath = "$PSScriptRoot\..\..\..\config\services.json"
    )

    if (-not (Test-Path $ConfigPath)) {
        Write-Log -Message "Services configuration not found." -Level Error
        return @()
    }

    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $results = [System.Collections.Generic.List[psobject]]::new()

    foreach ($serviceName in $config.services.PSObject.Properties.Name) {
        $serviceConfig = $config.services.$serviceName

        try {
            $service = Get-Service -Name $serviceName -ErrorAction Stop
            $wmiService = Get-CimInstance -ClassName Win32_Service -Filter "Name = '$serviceName'" -ErrorAction SilentlyContinue

            $results.Add([pscustomobject]@{
                    Name               = $serviceName
                    DisplayName        = $serviceConfig.DisplayName
                    Status             = $service.Status
                    CurrentStartup     = $wmiService.StartMode
                    RecommendedStartup = $serviceConfig.StartupType
                    Category           = $serviceConfig.Category
                    Description        = $serviceConfig.Description
                })
        }
        catch {
            # Service doesn't exist on this system - skip silently (expected for optional services)
            Write-Verbose "Service $serviceName not found on this system."
        }
    }

    return $results.ToArray()
}

#endregion

Export-ModuleMember -Function @(
    'Set-WinDebloat7Services',
    'Get-WinDebloat7ServicePresets',
    'Get-WinDebloat7ServiceStatus'
)
