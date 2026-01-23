<#
.SYNOPSIS
    Extras / External Tools module for Win-Debloat7
    
.DESCRIPTION
    ⚠️ WARNING: This module integrates with external community tools:
    - Windows Defender Remover (removes core Windows security)
    - Microsoft Activation Scripts (activation tool)
    
    These tools are NOT officially supported and may:
    - Be flagged by antivirus software
    - Violate Microsoft's Terms of Service
    - Permanently damage your Windows installation
    
    USE AT YOUR OWN RISK.
    
.NOTES
    Module: Win-Debloat7.Modules.Extras
    Version: 1.0.0
    Branch: extras
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force
Import-Module "$PSScriptRoot\..\..\ui\Colors.psm1" -Force

<#
.SYNOPSIS
    Downloads and launches Windows Defender Remover.
    
.DESCRIPTION
    ⚠️ WARNING: This PERMANENTLY removes Windows Defender and related security features.
    This is IRREVERSIBLE without a full Windows reinstall.
#>
function Invoke-WinDebloat7DefenderRemover {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param()

    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                   ⚠️  CRITICAL WARNING  ⚠️                    ║" -ForegroundColor Red
    Write-Host "║          Windows Defender Remover (ionuttbara)               ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    
    Write-Host "`nThis tool will PERMANENTLY REMOVE:" -ForegroundColor Yellow
    Write-Host "  • Windows Defender Antivirus" -ForegroundColor Gray
    Write-Host "  • Windows Security Center" -ForegroundColor Gray
    Write-Host "  • SmartScreen Filter" -ForegroundColor Gray
    Write-Host "  • Virtualization-Based Security (VBS)" -ForegroundColor Gray
    
    Write-Host "`n⚠️  RISKS:" -ForegroundColor Red
    Write-Host "  • Leaves your system UNPROTECTED from malware" -ForegroundColor Red
    Write-Host "  • CANNOT be undone without reinstalling Windows" -ForegroundColor Red
    Write-Host "  • May break Windows Updates" -ForegroundColor Red
    
    Write-Host "`nSource: https://github.com/ionuttbara/windows-defender-remover" -ForegroundColor DarkGray
    
    # Triple confirmation
    Write-Host "`nType 'I UNDERSTAND THE RISKS' to continue:" -ForegroundColor Yellow
    $confirm1 = Read-Host
    if ($confirm1 -ne 'I UNDERSTAND THE RISKS') {
        Write-Log -Message "Defender Remover: User cancelled (safety confirmation)" -Level Info
        return
    }
    
    Write-Host "`nFinal confirmation - Download and run? [YES/NO]" -ForegroundColor Yellow
    $confirm2 = Read-Host
    if ($confirm2 -ne 'YES') {
        Write-Log -Message "Defender Remover: User cancelled (final confirmation)" -Level Info
        return
    }
    
    # Check internet connectivity
    try {
        $null = Invoke-WebRequest -Uri "https://api.github.com" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    }
    catch {
        Write-Log -Message "Cannot reach GitHub API - check internet connection" -Level Error
        return
    }

    try {
        if ($PSCmdlet.ShouldProcess("Windows Defender", "Download and execute Remover tool")) {
            Write-Log -Message "Fetching Defender Remover release info..." -Level Info
            
            $apiUrl = "https://api.github.com/repos/ionuttbara/windows-defender-remover/releases/latest"
            $release = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing -ErrorAction Stop
            
            $asset = $release.assets | Where-Object { $_.name -like "*.exe" } | Select-Object -First 1
            
            if (-not $asset) {
                throw "No executable found in latest release"
            }

            $dlUrl = $asset.browser_download_url
            $destPath = "$env:TEMP\$($asset.name)"

            Write-Log -Message "Downloading: $($asset.name)" -Level Info
            Invoke-WebRequest -Uri $dlUrl -OutFile $destPath -UseBasicParsing -ErrorAction Stop
            
            $fileHash = (Get-FileHash -Path $destPath -Algorithm SHA256).Hash
            Write-Log -Message "Downloaded file SHA256: $fileHash" -Level Debug
            
            Write-Log -Message "Launching Defender Remover (interactive)..." -Level Warning
            $process = Start-Process -FilePath $destPath -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Log -Message "Defender Remover completed (exit code: 0)" -Level Success
            }
            else {
                Write-Log -Message "Defender Remover exited with code: $($process.ExitCode)" -Level Warning
            }
            
            Remove-Item $destPath -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Log -Message "Defender Remover failed: $($_.Exception.Message)" -Level Error
        Write-Host "`n❌ Error occurred. Opening GitHub releases page as fallback..." -ForegroundColor Red
        Start-Process "https://github.com/ionuttbara/windows-defender-remover/releases/latest"
    }
}

<#
.SYNOPSIS
    Launches Microsoft Activation Scripts (MAS).
    
.DESCRIPTION
    ⚠️ WARNING: This tool modifies Windows activation status.
    May violate Microsoft's Terms of Service.
#>
function Invoke-WinDebloat7Activation {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param()

    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║           Microsoft Activation Scripts (MAS)                 ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    
    Write-Host "`nThis will run the Massgrave Activation Scripts." -ForegroundColor Gray
    Write-Host "Source: https://massgrave.dev" -ForegroundColor DarkGray
    Write-Host "Command: irm https://get.activated.win | iex" -ForegroundColor DarkGray
    
    Write-Host "`n⚠️  LEGAL NOTICE:" -ForegroundColor Yellow
    Write-Host "  • This tool modifies Windows activation" -ForegroundColor Gray
    Write-Host "  • May violate Microsoft's Terms of Service" -ForegroundColor Gray
    Write-Host "  • Antivirus may flag this as a 'hacktool'" -ForegroundColor Gray

    # Check internet
    try {
        $null = Invoke-WebRequest -Uri "https://massgrave.dev" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    }
    catch {
        Write-Log -Message "Cannot reach massgrave.dev - check internet connection" -Level Error
        return
    }

    $confirm = Read-Host "`nProceed with MAS activation? [YES/NO]"
    if ($confirm -ne 'YES') {
        Write-Log -Message "MAS: User cancelled" -Level Info
        return
    }

    try {
        if ($PSCmdlet.ShouldProcess("Windows Activation", "Execute MAS script")) {
            Write-Log -Message "Launching Microsoft Activation Scripts..." -Level Warning
            Write-Host "`nDownloading and executing MAS..." -ForegroundColor Cyan
            
            Invoke-RestMethod https://get.activated.win | Invoke-Expression
            
            Write-Log -Message "MAS execution completed" -Level Success
        }
    }
    catch {
        Write-Log -Message "MAS execution failed: $($_.Exception.Message)" -Level Error
        Write-Host "`n❌ Error occurred. Opening MAS website as fallback..." -ForegroundColor Red
        Start-Process "https://massgrave.dev"
    }
}

Export-ModuleMember -Function Invoke-WinDebloat7DefenderRemover, Invoke-WinDebloat7Activation
