<#
.SYNOPSIS
    Driver update module for Win-Debloat7
    
.DESCRIPTION
    Handles driver enumeration, status checking, and updates via
    Windows Update, Winget, or Snappy Driver Installer.
    
.NOTES
    Module: Win-Debloat7.Modules.Drivers
    Version: 1.0.0
    
.LINK
    https://learn.microsoft.com/powershell/scripting/whats-new/what-s-new-in-powershell-75
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force

#region Driver Status

<#
.SYNOPSIS
    Gets the status of installed drivers.
    
.DESCRIPTION
    Queries Win32_PnPSignedDriver for all signed drivers and
    identifies potential outdated drivers based on date.
    
.PARAMETER Category
    Filter by driver category (Display, Network, Audio, etc.)
    
.OUTPUTS
    [psobject[]] Array of driver information objects.
    
.EXAMPLE
    Get-WinDebloat7DriverStatus -Category "Display"
#>
function Get-WinDebloat7DriverStatus {
    [CmdletBinding()]
    [OutputType([psobject[]])]
    param(
        [ValidateSet("All", "Display", "Network", "Audio", "USB", "Storage", "System")]
        [string]$Category = "All"
    )
    
    Write-Log -Message "Scanning installed drivers..." -Level Info
    
    try {
        $drivers = Get-CimInstance -ClassName Win32_PnPSignedDriver -ErrorAction Stop |
        Where-Object { $null -ne $_.DriverName } |
        Select-Object @{N = 'DeviceName'; E = { $_.DeviceName } },
        @{N = 'DriverVersion'; E = { $_.DriverVersion } },
        @{N = 'DriverDate'; E = { $_.DriverDate } },
        @{N = 'Manufacturer'; E = { $_.Manufacturer } },
        @{N = 'DeviceClass'; E = { $_.DeviceClass } },
        @{N = 'InfName'; E = { $_.InfName } },
        @{N = 'IsSigned'; E = { $_.IsSigned } }
        
        # Filter by category if specified
        if ($Category -ne "All") {
            $classFilter = switch ($Category) {
                "Display" { "Display" }
                "Network" { "Net" }
                "Audio" { "MEDIA|AudioEndpoint" }
                "USB" { "USB" }
                "Storage" { "DiskDrive|SCSIAdapter|hdc" }
                "System" { "System" }
            }
            $drivers = $drivers | Where-Object { $_.DeviceClass -match $classFilter }
        }
        
        # Calculate age and flag outdated drivers (>1 year old)
        $oneYearAgo = (Get-Date).AddYears(-1)
        $drivers = $drivers | ForEach-Object {
            $_ | Add-Member -NotePropertyName "IsOutdated" -NotePropertyValue ($_.DriverDate -lt $oneYearAgo) -PassThru
        }
        
        $outdatedCount = ($drivers | Where-Object { $_.IsOutdated }).Count
        Write-Log -Message "Found $($drivers.Count) drivers ($outdatedCount potentially outdated)" -Level Info
        
        return $drivers
    }
    catch {
        Write-Log -Message "Failed to enumerate drivers: $($_.Exception.Message)" -Level Error
        return @()
    }
}

<#
.SYNOPSIS
    Gets detected GPU information.
    
.OUTPUTS
    [psobject] GPU information including vendor
#>
function Get-WinDebloat7GPUInfo {
    [CmdletBinding()]
    [OutputType([psobject])]
    param()
    
    try {
        $gpu = Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1
        
        $vendor = switch -Regex ($gpu.Name) {
            "NVIDIA" { "NVIDIA" }
            "AMD|Radeon" { "AMD" }
            "Intel" { "Intel" }
            default { "Unknown" }
        }
        
        return [pscustomobject]@{
            Name          = $gpu.Name
            Vendor        = $vendor
            DriverVersion = $gpu.DriverVersion
            DriverDate    = $gpu.DriverDate
            AdapterRAM    = [math]::Round($gpu.AdapterRAM / 1GB, 2)
        }
    }
    catch {
        Write-Log -Message "Failed to get GPU info: $($_.Exception.Message)" -Level Warning
        return $null
    }
}

#endregion

#region Driver Updates

<#
.SYNOPSIS
    Updates drivers using Windows Update.
    
.DESCRIPTION
    Uses the PSWindowsUpdate module to scan for and install driver updates
    from Windows Update.
    
.PARAMETER AcceptAll
    Automatically accept all driver updates without prompting.
#>
function Update-DriversViaWindowsUpdate {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [switch]$AcceptAll
    )
    
    # Check for PSWindowsUpdate module
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Log -Message "PSWindowsUpdate module not found." -Level Warning
        
        $response = Read-Host "Install PSWindowsUpdate module? [Y/N]"
        if ($response -match '^[Yy]') {
            try {
                Install-PSResource -Name PSWindowsUpdate -Scope CurrentUser -TrustRepository -ErrorAction Stop
                Import-Module PSWindowsUpdate -ErrorAction Stop
            }
            catch {
                Write-Log -Message "Failed to install PSWindowsUpdate: $($_.Exception.Message)" -Level Error
                return
            }
        }
        else {
            return
        }
    }
    
    Import-Module PSWindowsUpdate -ErrorAction Stop
    
    Write-Log -Message "Scanning Windows Update for driver updates..." -Level Info
    
    try {
        # Get driver updates
        $updates = Get-WindowsUpdate -Category "Drivers" -ErrorAction Stop
        
        if ($updates.Count -eq 0) {
            Write-Log -Message "No driver updates available from Windows Update." -Level Info
            return
        }
        
        Write-Host "`nAvailable Driver Updates:" -ForegroundColor Cyan
        $updates | ForEach-Object { 
            Write-Host "  - $($_.Title)" -ForegroundColor White 
        }
        
        if (-not $AcceptAll) {
            $confirm = Read-Host "`nInstall $($updates.Count) driver updates? [Y/N]"
            if ($confirm -notmatch '^[Yy]') { return }
        }
        
        if ($PSCmdlet.ShouldProcess("$($updates.Count) drivers", "Install via Windows Update")) {
            Write-Log -Message "Installing driver updates via Windows Update..." -Level Info
            Install-WindowsUpdate -Category "Drivers" -AcceptAll -IgnoreReboot -ErrorAction Stop
            Write-Log -Message "Driver updates installed successfully." -Level Success
        }
    }
    catch {
        Write-Log -Message "Windows Update driver installation failed: $($_.Exception.Message)" -Level Error
    }
}

<#
.SYNOPSIS
    Updates GPU drivers via Winget.
    
.DESCRIPTION
    Detects GPU vendor and installs appropriate driver/software package.
#>
function Update-GPUDriverViaWinget {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()
    
    # Check for Winget
    try { $null = Get-Command winget -ErrorAction Stop }
    catch {
        Write-Log -Message "Winget not available for GPU driver installation." -Level Warning
        return
    }
    
    $gpu = Get-WinDebloat7GPUInfo
    if (-not $gpu) {
        Write-Log -Message "Could not detect GPU." -Level Warning
        return
    }
    
    Write-Log -Message "Detected GPU: $($gpu.Name) ($($gpu.Vendor))" -Level Info
    
    $packages = switch ($gpu.Vendor) {
        "NVIDIA" { 
            @(
                @{ Name = "GeForce Experience"; Id = "NVIDIA.GeForceExperience" }
                @{ Name = "NVIDIA App"; Id = "NVIDIA.NVIDIAApp" }
            )
        }
        "AMD" {
            @(
                @{ Name = "AMD Software: Adrenalin Edition"; Id = "AMD.RyzenMaster" }
            )
        }
        "Intel" {
            @(
                @{ Name = "Intel Driver & Support Assistant"; Id = "Intel.IntelDriverAndSupportAssistant" }
            )
        }
        default {
            Write-Log -Message "Unknown GPU vendor - cannot auto-update drivers." -Level Warning
            return
        }
    }
    
    Write-Host "`nGPU Driver Options for $($gpu.Vendor):" -ForegroundColor Cyan
    $i = 1
    foreach ($pkg in $packages) {
        Write-Host "  [$i] $($pkg.Name)" -ForegroundColor White
        $i++
    }
    Write-Host "  [S] Skip GPU driver update" -ForegroundColor Gray
    
    $sel = Read-Host "Select option"
    if ($sel -match '^[Ss]$') { return }
    
    $selectedPkg = $packages[[int]$sel - 1]
    if ($selectedPkg) {
        if ($PSCmdlet.ShouldProcess($selectedPkg.Name, "Install via Winget")) {
            Write-Log -Message "Installing $($selectedPkg.Name)..." -Level Info
            $result = winget install $selectedPkg.Id --accept-source-agreements --accept-package-agreements 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log -Message "$($selectedPkg.Name) installed/updated successfully." -Level Success
            }
            else {
                Write-Log -Message "Installation result: $result" -Level Warning
            }
        }
    }
}

<#
.SYNOPSIS
    Opens Snappy Driver Installer Origin for comprehensive driver updates.
    
.DESCRIPTION
    SDIO is a portable, open-source driver updater with offline driver packs.
    This function downloads and launches SDIO if not present.
#>
function Start-SnappyDriverInstaller {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()
    
    $sdioPath = "$env:ProgramData\Win-Debloat7\Tools\SDIO"
    $sdioExe = "$sdioPath\SDIO_x64_R2408.exe"
    
    # Check if already downloaded
    if (-not (Test-Path $sdioExe)) {
        Write-Log -Message "Snappy Driver Installer Origin not found. Downloading..." -Level Info
        
        try {
            New-Item -Path $sdioPath -ItemType Directory -Force | Out-Null
            
            # SDIO download URL (check for latest version yourself)
            $sdioUrl = "https://www.glenn.delahoy.com/downloads/sdio/SDIO_1.12.18.781.zip"
            $zipPath = "$env:TEMP\sdio.zip"
            
            if ($PSCmdlet.ShouldProcess("SDIO", "Download and extract")) {
                Invoke-WebRequest -Uri $sdioUrl -OutFile $zipPath -ErrorAction Stop
                Expand-Archive -Path $zipPath -DestinationPath $sdioPath -Force
                Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
                
                # Find the exe
                $sdioExe = Get-ChildItem $sdioPath -Filter "SDIO*.exe" -Recurse | Select-Object -First 1 -ExpandProperty FullName
            }
        }
        catch {
            Write-Log -Message "Failed to download SDIO: $($_.Exception.Message)" -Level Error
            Write-Log -Message "Download manually from: https://www.glenn.delahoy.com/snappy-driver-installer-origin/" -Level Info
            return
        }
    }
    
    if (Test-Path $sdioExe) {
        Write-Log -Message "Launching Snappy Driver Installer Origin..." -Level Info
        if ($PSCmdlet.ShouldProcess("SDIO", "Launch")) {
            Start-Process -FilePath $sdioExe
        }
    }
    else {
        Write-Log -Message "SDIO executable not found." -Level Error
    }
}

<#
.SYNOPSIS
    Main driver update function with multiple options.
    
.DESCRIPTION
    Provides interactive driver update experience with multiple sources:
    - Windows Update
    - GPU drivers via Winget
    - Snappy Driver Installer Origin
    
.PARAMETER Method
    Update method: WindowsUpdate, GPU, SDIO, or Interactive (menu).
#>
function Update-WinDebloat7Drivers {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [ValidateSet("WindowsUpdate", "GPU", "SDIO", "Interactive")]
        [string]$Method = "Interactive"
    )
    
    switch ($Method) {
        "WindowsUpdate" { Update-DriversViaWindowsUpdate }
        "GPU" { Update-GPUDriverViaWinget }
        "SDIO" { Start-SnappyDriverInstaller }
        "Interactive" {
            Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "║         Driver Update Center              ║" -ForegroundColor Cyan
            Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
            
            # Show current driver status
            $gpu = Get-WinDebloat7GPUInfo
            if ($gpu) {
                Write-Host "`nCurrent GPU: $($gpu.Name)" -ForegroundColor White
                Write-Host "Driver Version: $($gpu.DriverVersion)" -ForegroundColor Gray
            }
            
            $outdated = (Get-WinDebloat7DriverStatus | Where-Object { $_.IsOutdated }).Count
            Write-Host "Potentially Outdated Drivers: $outdated" -ForegroundColor $(if ($outdated -gt 5) { "Yellow" } else { "Gray" })
            
            Write-Host "`nUpdate Options:" -ForegroundColor Cyan
            Write-Host "  [1] Windows Update - Official Microsoft drivers" -ForegroundColor White
            Write-Host "  [2] GPU Driver - NVIDIA/AMD/Intel via Winget" -ForegroundColor White
            Write-Host "  [3] Snappy Driver Installer - Comprehensive offline drivers" -ForegroundColor White
            Write-Host "  [4] View All Drivers" -ForegroundColor White
            Write-Host "  [B] Back" -ForegroundColor Gray
            
            $choice = Read-Host "`nSelect option"
            
            switch ($choice) {
                "1" { Update-DriversViaWindowsUpdate }
                "2" { Update-GPUDriverViaWinget }
                "3" { Start-SnappyDriverInstaller }
                "4" {
                    $drivers = Get-WinDebloat7DriverStatus
                    $drivers | Sort-Object DeviceClass | Format-Table DeviceName, DriverVersion, IsOutdated -AutoSize | Out-Host
                    Read-Host "Press Enter to continue..."
                }
            }
        }
    }
}

#endregion

Export-ModuleMember -Function @(
    'Get-WinDebloat7DriverStatus',
    'Get-WinDebloat7GPUInfo',
    'Update-WinDebloat7Drivers'
)
