<#
.SYNOPSIS
    Extras module for Win-Debloat7 (Advanced Edition)
    
.DESCRIPTION
    Provides integrations for third-party tools like MAS and Defender Remover.
    These tools are NOT included in the Standard edition due to AV flags.
    
.NOTES
    Module: Win-Debloat7.Modules.Extras
    Version: 1.2.3
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force

<#
.SYNOPSIS
    Downloads and runs the latest Defender Remover.
#>
function Invoke-WinDebloat7DefenderRemover {
    [CmdletBinding()]
    param()

    Write-Log -Message "Launching Defender Remover..." -Level Info
    
    # Check connectivity
    if (-not (Test-Connection "api.github.com" -Count 1 -Quiet)) {
        Write-Log -Message "Internet connection required for Defender Remover." -Level Error
        return
    }

    try {
        Write-Host "Fetching latest release from GitHub..." -ForegroundColor Cyan
        $apiUrl = "https://api.github.com/repos/ionuttbara/windows-defender-remover/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
        
        $asset = $release.assets | Where-Object { $_.name -like "*.exe" } | Select-Object -First 1
        if (-not $asset) { throw "Executable asset not found." }
        
        $dlUrl = $asset.browser_download_url
        $destPath = "$env:TEMP\$($asset.name)"
        
        Write-Host "Downloading $($asset.name)..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $dlUrl -OutFile $destPath -MaximumRetryCount 3 -RetryIntervalSec 5 -ErrorAction Stop
        
        Write-Host "Running Defender Remover..." -ForegroundColor Green
        Start-Process -FilePath $destPath -Wait
        
        Write-Log -Message "Defender Remover execution finished." -Level Success
    }
    catch {
        Write-Log -Message "Error launching Defender Remover: $($_.Exception.Message)" -Level Error
        Start-Process "https://github.com/ionuttbara/windows-defender-remover/releases/latest"
    }
}

<#
.SYNOPSIS
    Runs Microsoft Activation Scripts (MAS).
#>
function Invoke-WinDebloat7Activation {
    [CmdletBinding()]
    param()

    Write-Log -Message "Launching Microsoft Activation Scripts (MAS)..." -Level Info
    
    if (-not (Test-Connection "get.activated.win" -Count 1 -Quiet)) {
        Write-Log -Message "Internet connection required for MAS." -Level Error
        return
    }

    try {
        Write-Host "Invoking MAS (irm https://get.activated.win | iex)..." -ForegroundColor Green
        Invoke-RestMethod https://get.activated.win | Invoke-Expression
    }
    catch {
        Write-Log -Message "Error running MAS: $($_.Exception.Message)" -Level Error
    }
}

Export-ModuleMember -Function Invoke-WinDebloat7DefenderRemover, Invoke-WinDebloat7Activation
