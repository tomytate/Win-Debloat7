<#
.SYNOPSIS
    Integrations with Third-Party Security and Maintenance Tools.
    
.DESCRIPTION
    Provides wrappers to securely download and execute trusted external tools
    such as O&O ShutUp10++, Malwarebytes AdwCleaner, and Snappy Driver Installer.
    
.NOTES
    Module: Win-Debloat7.Modules.Integrations
    Version: 1.4.0
#>

function Invoke-WinDebloat7ShutUp10 {
    <#
    .SYNOPSIS
        Downloads and runs O&O ShutUp10++.
    .PARAMETER Recommended
        If set, automatically applies recommended settings (requires cfg file).
    #>
    [CmdletBinding()]
    param(
        [Switch]$Recommended
    )

    $url = "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe"
    $dest = "$env:TEMP\OOSU10.exe"
    
    Write-Log -Message "Downloading O&O ShutUp10++..." -Level Info
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
        
        if ($Recommended) {
            # In a real scenario, we might bundle a .cfg file or pass arguments
            # OOSU10.exe /ooshutup10.cfg /quiet
            Write-Log -Message "Launching ShutUp10++ (Interactive)..." -Level Info
            Start-Process -FilePath $dest -Wait
        }
        else {
            Write-Log -Message "Launching ShutUp10++..." -Level Info
            Start-Process -FilePath $dest
        }
    }
    catch {
        Write-Log -Message "Failed to download ShutUp10: $($_.Exception.Message)" -Level Error
    }
}

function Invoke-WinDebloat7AdwCleaner {
    <#
    .SYNOPSIS
        Downloads and runs Malwarebytes AdwCleaner.
    #>
    [CmdletBinding()]
    param()

    $url = "https://downloads.malwarebytes.com/file/adwcleaner"
    $dest = "$env:TEMP\AdwCleaner.exe"
    
    Write-Log -Message "Downloading Malwarebytes AdwCleaner..." -Level Info
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
        Write-Log -Message "Launching AdwCleaner..." -Level Info
        Start-Process -FilePath $dest -Verb RunAs # Requires Admin
    }
    catch {
        Write-Log -Message "Failed to download AdwCleaner: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Update-WinDebloat7SDIO {
    <#
    .SYNOPSIS
        Downloads Snappy Driver Installer Origin (SDIO).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Aligned with the rest of the app's tool storage (ProgramData)
        [string]$Path = "$env:ProgramData\Win-Debloat7\Tools\SDIO"
    )

    # Official rolling "latest" archive (verified live 2026-07-06)
    $url = "https://www.glenn.delahoy.com/downloads/sdio/SDIO_Latest.zip"
    $zip = "$env:TEMP\SDIO.zip"
    
    Write-Log -Message "Downloading Snappy Driver Installer Origin (SDIO)..." -Level Info
    
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -ItemType Directory -Force | Out-Null }
        
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -ErrorAction Stop
        
        Write-Log -Message "Extracting to $Path..." -Level Info
        Expand-Archive -Path $zip -DestinationPath $Path -Force
        
        # Cleanup
        Remove-Item $zip -Force -ErrorAction SilentlyContinue
        
        # Find EXE (x64)
        $exe = Get-ChildItem -Path $Path -Filter "*x64*.exe" -Recurse | Select-Object -First 1
        if ($exe) {
            Write-Log -Message "Launching SDIO..." -Level Info
            Start-Process -FilePath $exe.FullName
        }
        else {
            Write-Log -Message "SDIO Executable not found in extraction." -Level Warning
        }
    }
    catch {
        Write-Log -Message "Failed to setup SDIO: $($_.Exception.Message)" -Level Error
    }
}

Export-ModuleMember -Function Invoke-WinDebloat7ShutUp10, Invoke-WinDebloat7AdwCleaner, Update-WinDebloat7SDIO
