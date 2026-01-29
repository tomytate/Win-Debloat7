<#
.SYNOPSIS
    Configuration management module for Win-Debloat7
    
.DESCRIPTION
    Handles YAML profile loading, validation and schema checking.
    Uses PowerShell 7.5 best practices with user consent for dependencies.
    
.NOTES
    Module: Win-Debloat7.Core.Config
    Version: 1.2.3
    
.LINK
    https://learn.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-75
#>

#Requires -Version 7.5

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\Logger.psm1" -Force

# Schema definition for validation (SEC-004 fix)
$Script:ProfileSchema = @{
    Required             = @('metadata')
    MetadataRequired     = @('name', 'version')
    ValidSections        = @('metadata', 'bloatware', 'privacy', 'performance', 'network', 'software')
    ValidTelemetryLevels = @('Security', 'Basic', 'Full')
    ValidPowerPlans      = @('Balanced', 'HighPerformance', 'Ultimate')
    ValidRemovalModes    = @('None', 'Conservative', 'Moderate', 'Aggressive', 'Custom')
}

<#
.SYNOPSIS
    Imports and validates a Win-Debloat7 configuration profile.
    
.DESCRIPTION
    Loads a YAML configuration file, validates against the schema,
    and returns a structured configuration object.
    
.PARAMETER Path
    Full path to the YAML profile file.
    
.PARAMETER SkipDependencyCheck
    If specified, skips the dependency check for powershell-yaml.
    
.OUTPUTS
    [psobject] The validated configuration object.
    
.EXAMPLE
    $config = Import-WinDebloat7Config -Path "profiles/moderate.yaml"
#>
function Import-WinDebloat7Config {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$Path,
        
        [switch]$SkipDependencyCheck
    )
    
    Write-Log -Message "Loading profile: $Path" -Level Info
    
    # Check for vendored powershell-yaml module
    $vendorPath = "$PSScriptRoot\..\modules\Vendor\powershell-yaml"
    if (Test-Path $vendorPath) {
        # Try to find the .psd1 file recursively in the vendor directory (handling version subfolders)
        $moduleManifest = Get-ChildItem -Path $vendorPath -Filter "powershell-yaml.psd1" -Recurse | Select-Object -First 1
        
        if ($moduleManifest) {
            Write-Log -Message "Loading vendored 'powershell-yaml' from $($moduleManifest.FullName)" -Level Debug
            Import-Module $moduleManifest.FullName -Force -ErrorAction SilentlyContinue
        }
    }

    # Check for powershell-yaml module with user consent (SEC-001 fix)
    if (-not $SkipDependencyCheck) {
        if (-not (Get-Module -Name "powershell-yaml" -ErrorAction SilentlyContinue) -and -not (Get-Module -ListAvailable -Name "powershell-yaml")) {
            Write-Log -Message "Module 'powershell-yaml' not found." -Level Warning
            
            # Prompt for user consent - security best practice
            $response = Read-Host "Install 'powershell-yaml' from PowerShell Gallery? [Y/N]"
            
            if ($response -match '^[Yy]') {
                try {
                    Write-Log -Message "Installing 'powershell-yaml' via PSResourceGet..." -Level Info
                    # PS 7.5+ prefers Install-PSResource over Install-Module
                    Install-PSResource -Name "powershell-yaml" -Scope CurrentUser -TrustRepository -ErrorAction Stop
                    Import-Module "powershell-yaml" -ErrorAction Stop
                    Write-Log -Message "Successfully installed 'powershell-yaml'." -Level Success
                }
                catch {
                    Write-Log -Message "Failed to install 'powershell-yaml'. Error: $($_.Exception.Message)" -Level Error
                    throw "Dependency 'powershell-yaml' is missing and installation failed."
                }
            }
            else {
                throw "Dependency 'powershell-yaml' is required. Please install it manually: Install-PSResource powershell-yaml"
            }
        }
        elseif (-not (Get-Module -Name "powershell-yaml" -ErrorAction SilentlyContinue)) {
            Import-Module "powershell-yaml" -ErrorAction Stop
        }
    }
    
    try {
        $Content = Get-Content $Path -Raw -ErrorAction Stop
        $Config = $Content | ConvertFrom-Yaml -ErrorAction Stop
        
        # Schema Validation (SEC-004 fix)
        $validationErrors = @()
        
        # 1. Check required sections
        if (-not $Config.metadata) {
            $validationErrors += "Missing required 'metadata' section"
        }
        else {
            foreach ($field in $Script:ProfileSchema.MetadataRequired) {
                if (-not $Config.metadata.$field) {
                    $validationErrors += "Missing required metadata field: '$field'"
                }
            }
        }
        
        # 2. Validate telemetry level if specified
        if ($Config.privacy -and $Config.privacy.telemetry_level) {
            if ($Config.privacy.telemetry_level -notin $Script:ProfileSchema.ValidTelemetryLevels) {
                $validationErrors += "Invalid telemetry_level: '$($Config.privacy.telemetry_level)'. Valid: $($Script:ProfileSchema.ValidTelemetryLevels -join ', ')"
            }
        }
        
        # 3. Validate power plan if specified
        if ($Config.performance -and $Config.performance.power_plan) {
            if ($Config.performance.power_plan -notin $Script:ProfileSchema.ValidPowerPlans) {
                $validationErrors += "Invalid power_plan: '$($Config.performance.power_plan)'. Valid: $($Script:ProfileSchema.ValidPowerPlans -join ', ')"
            }
        }
        
        # 4. Validate removal mode if specified
        if ($Config.bloatware -and $Config.bloatware.removal_mode) {
            if ($Config.bloatware.removal_mode -notin $Script:ProfileSchema.ValidRemovalModes) {
                $validationErrors += "Invalid removal_mode: '$($Config.bloatware.removal_mode)'. Valid: $($Script:ProfileSchema.ValidRemovalModes -join ', ')"
            }
            
            # GOLD STANDARD: Enforce custom_list requirement
            if ($Config.bloatware.removal_mode -eq 'Custom' -and (-not $Config.bloatware.custom_list)) {
                $validationErrors += "Removal mode is 'Custom' but 'custom_list' is missing or empty."
            }
        }
        
        # 4b. Normalize Lists (Force Array) to prevent iteration errors
        $listFields = @(
            @{ Section = 'bloatware'; Field = 'custom_list' }
            @{ Section = 'bloatware'; Field = 'exclude_list' }
            @{ Section = 'software'; Field = 'install_list' }
        )
        
        foreach ($item in $listFields) {
            $sec = $item.Section
            $fld = $item.Field
            
            if ($Config.$sec -and $Config.$sec.$fld) {
                if ($Config.$sec.$fld -isnot [Array]) {
                    # Convert single string to single-item array
                    $Config.$sec.$fld = @($Config.$sec.$fld)
                }
            }
        }
        
        # 5. Check for common typos (camelCase vs snake_case)
        $typoMap = @{
            'telemetry-level'       = 'telemetry_level'
            'telemetryLevel'        = 'telemetry_level'
            'powerPlan'             = 'power_plan'
            'power-plan'            = 'power_plan'
            'disableBackgroundApps' = 'disable_background_apps'
            'removalMode'           = 'removal_mode'
            'removal-mode'          = 'removal_mode'
            'excludeList'           = 'exclude_list'
            'customList'            = 'custom_list'
            'disableCopilot'        = 'disable_copilot'
            'disableRecall'         = 'disable_recall'
        }
        
        foreach ($section in $Config.PSObject.Properties) {
            if ($null -ne $section.Value -and $section.Value -is [PSCustomObject]) {
                foreach ($prop in $section.Value.PSObject.Properties) {
                    if ($typoMap.ContainsKey($prop.Name)) {
                        Write-Log -Message "Config typo: '$($prop.Name)' should be '$($typoMap[$prop.Name])' in [$($section.Name)]" -Level Warning
                    }
                }
            }
        }
        
        # Report validation errors
        if ($validationErrors.Count -gt 0) {
            foreach ($err in $validationErrors) {
                Write-Log -Message "Validation Error: $err" -Level Error
            }
            throw "Profile validation failed with $($validationErrors.Count) error(s)"
        }
        
        Write-Log -Message "Profile loaded: $($Config.metadata.name) v$($Config.metadata.version)" -Level Success
        return $Config
        
    }
    catch {
        Write-Log -Message "Failed to load profile: $($_.Exception.Message)" -Level Error
        throw
    }
}

<#
.SYNOPSIS
    Validates a configuration against the schema.
    
.PARAMETER Config
    The configuration object to validate.
    
.OUTPUTS
    [bool] True if valid, false otherwise.
#>
function Test-WinDebloat7Config {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [psobject]$Config
    )
    
    try {
        if (-not $Config.metadata) { return $false }
        if (-not $Config.metadata.name) { return $false }
        if (-not $Config.metadata.version) { return $false }
        return $true
    }
    catch {
        return $false
    }
}


<#
.SYNOPSIS
    Analyzes hardware to recommend an optimization profile.
    
.DESCRIPTION
    Checks RAM and GPU to suggest 'Gaming', 'Performance', or 'Moderate'.
    
.OUTPUTS
    [string] The recommended profile name.
#>
function Get-WinDebloat7RecommendedProfile {
    [CmdletBinding()]
    param()
    
    try {
        # Check RAM (GB)
        $ramObj = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $totalRamGB = if ($ramObj) { [math]::Round($ramObj.TotalPhysicalMemory / 1GB) } else { 8 }
        
        # Check GPU
        $gpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue 
        $hasHighEndGpu = $false
        if ($gpus) {
            foreach ($gpu in $gpus) {
                if ($gpu.Name -match 'NVIDIA|AMD|Radeon|GeForce|RTX|GTX') {
                    $hasHighEndGpu = $true
                    break
                }
            }
        }
        
        # Logic
        if ($totalRamGB -lt 8) {
            return "Performance"
        }
        elseif ($totalRamGB -ge 16 -and $hasHighEndGpu) {
            return "Gaming"
        }
        else {
            return "Moderate"
        }
    }
    catch {
        Write-Log -Message "Failed to detect hardware for recommendation: $($_.Exception.Message)" -Level Warning
        return "Moderate" # Fallback
    }
}

Export-ModuleMember -Function Import-WinDebloat7Config, Test-WinDebloat7Config, Get-WinDebloat7RecommendedProfile
