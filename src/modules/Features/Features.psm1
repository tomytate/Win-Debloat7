<#
.SYNOPSIS
    Windows Features Management module for Win-Debloat7
    
.DESCRIPTION
    Manages Windows Optional Features and Capabilities.
    Disables unused features (Fax, IIS) and removes legacy capabilities (WordPad, Math Recognizer).
    
.NOTES
    Module: Win-Debloat7.Modules.Features
    Version: 1.2.3
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force

#region Optional Features

<#
.SYNOPSIS
    Disables specified Optional Features.
    
.PARAMETER Features
    List of features to disable.
#>
function Set-WinDebloat7OptionalFeatures {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string[]]$Features = @(
            "FaxServicesClientPackage",
            "IIS-WebServerRole",
            "LegacyComponents",
            "MicrosoftWindowsPowerShellV2",
            "MicrosoftWindowsPowerShellV2Root",
            "WorkFolders-Client",
            "Printing-XPSServices-Features"
        ),
        [switch]$Enable
    )

    $action = if ($Enable) { "Enable" } else { "Disable" }
    Write-Log -Message "$action Windows Features..." -Level Info

    if ($PSCmdlet.ShouldProcess("Optional Features", "$action List")) {
        foreach ($feat in $Features) {
            # Check existence first to avoid errors
            if (Get-WindowsOptionalFeature -Online -FeatureName $feat -ErrorAction SilentlyContinue) {
                if ($Enable) {
                    Enable-WindowsOptionalFeature -Online -FeatureName $feat -NoRestart -ErrorAction SilentlyContinue | Out-Null
                    Write-Log -Message "Enabled: $feat" -Level Info
                }
                else {
                    Disable-WindowsOptionalFeature -Online -FeatureName $feat -NoRestart -ErrorAction SilentlyContinue | Out-Null
                    Write-Log -Message "Disabled: $feat" -Level Info
                }
            }
        }
        Write-Log -Message "Optional Features processed." -Level Success
    }
}

#endregion

#region Capabilities

<#
.SYNOPSIS
    Removes specified Windows Capabilities.
    
.PARAMETER Capabilities
    List of capabilities to remove.
#>
function Remove-WinDebloat7Capabilities {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string[]]$Capabilities = @(
            "App.StepsRecorder*",
            "Browser.InternetExplorer*",
            "MathRecognizer*",
            "Microsoft.Windows.WordPad*",
            "Print.Fax.Scan*"
        )
    )

    Write-Log -Message "Removing Windows Capabilities..." -Level Info

    if ($PSCmdlet.ShouldProcess("Capabilities", "Remove List")) {
        foreach ($capName in $Capabilities) {
            $caps = Get-WindowsCapability -Online | Where-Object { $_.Name -like $capName -and $_.State -eq 'Installed' }
            foreach ($c in $caps) {
                Write-Log -Message "Removing: $($c.Name)" -Level Info
                Remove-WindowsCapability -Online -Name $c.Name -ErrorAction SilentlyContinue | Out-Null
            }
        }
        Write-Log -Message "Capabilities removal complete." -Level Success
    }
}

#endregion

Export-ModuleMember -Function @(
    "Set-WinDebloat7OptionalFeatures",
    "Remove-WinDebloat7Capabilities"
)
