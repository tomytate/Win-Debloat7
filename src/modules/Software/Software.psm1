<#
.SYNOPSIS
    Software and package management module for Win-Debloat7
    
.DESCRIPTION
    Handles Winget and Chocolatey package installation with a comprehensive
    curated essentials list. Supports both package managers with auto-detection.
    
.NOTES
    Module: Win-Debloat7.Modules.Software
    Version: 1.2.0
    
.LINK
    https://learn.microsoft.com/powershell/scripting/whats-new/what-s-new-in-powershell-75
#>

#Requires -Version 7.5

using namespace System.Management.Automation
using namespace System.Collections.Generic

Import-Module "$PSScriptRoot\..\..\core\Logger.psm1" -Force

#region Package Manager Detection

<#
.SYNOPSIS
    Tests if a package manager is installed.
    
.PARAMETER Name
    The package manager to check: Winget or Chocolatey.
    
.OUTPUTS
    [bool] True if installed.
#>
function Test-PackageManager {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Winget", "Chocolatey")]
        [string]$Name
    )
    
    switch ($Name) {
        "Winget" {
            try {
                $null = Get-Command winget -ErrorAction Stop
                return $true
            }
            catch {
                return $false
            }
        }
        "Chocolatey" {
            try {
                $null = Get-Command choco -ErrorAction Stop
                return $true
            }
            catch {
                return $false
            }
        }
    }
    return $false
}

<#
.SYNOPSIS
    Installs a package manager if not present.
    
.PARAMETER Name
    Package manager to install: Winget or Chocolatey.
    
.PARAMETER Force
    Skip confirmation prompt.
#>
function Install-PackageManager {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Winget", "Chocolatey")]
        [string]$Name,
        
        [switch]$Force
    )
    
    if (Test-PackageManager -Name $Name) {
        Write-Log -Message "$Name is already installed." -Level Info
        return $true
    }
    
    if (-not $Force) {
        $response = Read-Host "Install $Name? [Y/N]"
        if ($response -notmatch '^[Yy]') {
            Write-Log -Message "User declined $Name installation." -Level Warning
            return $false
        }
    }
    
    switch ($Name) {
        "Winget" {
            Write-Log -Message "Installing Winget via Microsoft Store..." -Level Info
            try {
                # Winget comes with App Installer - trigger store update
                if ($PSCmdlet.ShouldProcess("Winget", "Install via Add-AppxPackage")) {
                    # Download latest release from GitHub
                    $apiUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
                    $release = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
                    $msixUrl = $release.assets | Where-Object { $_.name -like "*.msixbundle" } | Select-Object -First 1 -ExpandProperty browser_download_url
                    
                    $tempPath = "$env:TEMP\winget.msixbundle"
                    Invoke-WebRequest -Uri $msixUrl -OutFile $tempPath -ErrorAction Stop
                    Add-AppxPackage -Path $tempPath -ErrorAction Stop
                    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
                    
                    Write-Log -Message "Winget installed successfully." -Level Success
                    return $true
                }
            }
            catch {
                Write-Log -Message "Failed to install Winget: $($_.Exception.Message)" -Level Error
                return $false
            }
        }
        "Chocolatey" {
            Write-Log -Message "Installing Chocolatey..." -Level Info
            try {
                if ($PSCmdlet.ShouldProcess("Chocolatey", "Install via official script")) {
                    Set-ExecutionPolicy Bypass -Scope Process -Force
                    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                    
                    Write-Log -Message "Chocolatey installed successfully." -Level Success
                    return $true
                }
            }
            catch {
                Write-Log -Message "Failed to install Chocolatey: $($_.Exception.Message)" -Level Error
                return $false
            }
        }
    }
    
    return $false
}

#endregion

#region Essentials List

# Comprehensive curated app list by category
$Script:EssentialsApps = @{
    # === BROWSERS ===
    Browsers      = @{
        DisplayName = "Web Browsers"
        Apps        = @(
            @{ Name = "Mozilla Firefox"; Winget = "Mozilla.Firefox"; Choco = "firefox" }
            @{ Name = "Google Chrome"; Winget = "Google.Chrome"; Choco = "googlechrome" }
            @{ Name = "Brave Browser"; Winget = "Brave.Brave"; Choco = "brave" }
            @{ Name = "Microsoft Edge"; Winget = "Microsoft.Edge"; Choco = "microsoft-edge" }
            @{ Name = "Vivaldi"; Winget = "Vivaldi.Vivaldi"; Choco = "vivaldi" }
            @{ Name = "Opera GX"; Winget = "Opera.OperaGX"; Choco = "opera-gx" }
            @{ Name = "LibreWolf"; Winget = "LibreWolf.LibreWolf"; Choco = "librewolf" }
            @{ Name = "Tor Browser"; Winget = "TorProject.TorBrowser"; Choco = "tor-browser" }
        )
    }
    
    # === RUNTIMES ===
    Runtimes      = @{
        DisplayName = "Runtimes & Frameworks"
        Apps        = @(
            @{ Name = ".NET 8 Desktop Runtime"; Winget = "Microsoft.DotNet.DesktopRuntime.8"; Choco = "dotnet-8.0-desktopruntime" }
            @{ Name = ".NET 9 Desktop Runtime"; Winget = "Microsoft.DotNet.DesktopRuntime.9"; Choco = "dotnet-9.0-desktopruntime" }
            @{ Name = "VC++ 2015-2022 Redist"; Winget = "Microsoft.VCRedist.2015+.x64"; Choco = "vcredist140" }
            @{ Name = "VC++ 2015-2022 Redist (x86)"; Winget = "Microsoft.VCRedist.2015+.x86"; Choco = "vcredist140" }
            @{ Name = "Java Runtime (Temurin)"; Winget = "EclipseAdoptium.Temurin.21.JRE"; Choco = "temurin21jre" }
            @{ Name = "Java Development Kit"; Winget = "EclipseAdoptium.Temurin.21.JDK"; Choco = "temurin21" }
            @{ Name = "Node.js LTS"; Winget = "OpenJS.NodeJS.LTS"; Choco = "nodejs-lts" }
            @{ Name = "Python 3.12"; Winget = "Python.Python.3.12"; Choco = "python312" }
            @{ Name = "DirectX Runtime"; Winget = "Microsoft.DirectX"; Choco = "directx" }
        )
    }
    
    # === UTILITIES ===
    Utilities     = @{
        DisplayName = "System Utilities"
        Apps        = @(
            @{ Name = "7-Zip"; Winget = "7zip.7zip"; Choco = "7zip" }
            @{ Name = "WinRAR"; Winget = "RARLab.WinRAR"; Choco = "winrar" }
            @{ Name = "Everything Search"; Winget = "voidtools.Everything"; Choco = "everything" }
            @{ Name = "PowerToys"; Winget = "Microsoft.PowerToys"; Choco = "powertoys" }
            @{ Name = "Sysinternals Suite"; Winget = "Microsoft.Sysinternals"; Choco = "sysinternals" }
            @{ Name = "Process Explorer"; Winget = "Microsoft.Sysinternals.ProcessExplorer"; Choco = "procexp" }
            @{ Name = "HWiNFO"; Winget = "REALiX.HWiNFO"; Choco = "hwinfo" }
            @{ Name = "CPU-Z"; Winget = "CPUID.CPU-Z"; Choco = "cpu-z" }
            @{ Name = "GPU-Z"; Winget = "TechPowerUp.GPU-Z"; Choco = "gpu-z" }
            @{ Name = "CrystalDiskInfo"; Winget = "CrystalDewWorld.CrystalDiskInfo"; Choco = "crystaldiskinfo" }
            @{ Name = "TreeSize Free"; Winget = "JAMSoftware.TreeSizeFree"; Choco = "treesizefree" }
            @{ Name = "WizTree"; Winget = "NimbleWorks.WizTree"; Choco = "wiztree" }
            @{ Name = "Revo Uninstaller"; Winget = "RevoUninstaller.RevoUninstaller"; Choco = "revo-uninstaller" }
            @{ Name = "BleachBit"; Winget = "BleachBit.BleachBit"; Choco = "bleachbit" }
        )
    }
    
    # === MEDIA ===
    Media         = @{
        DisplayName = "Media & Graphics"
        Apps        = @(
            @{ Name = "VLC Media Player"; Winget = "VideoLAN.VLC"; Choco = "vlc" }
            @{ Name = "MPC-HC"; Winget = "clsid2.mpc-hc"; Choco = "mpc-hc" }
            @{ Name = "mpv"; Winget = "mpv.net"; Choco = "mpv" }
            @{ Name = "Spotify"; Winget = "Spotify.Spotify"; Choco = "spotify" }
            @{ Name = "foobar2000"; Winget = "PeterPawlowski.foobar2000"; Choco = "foobar2000" }
            @{ Name = "ImageGlass"; Winget = "DuongDieuPhap.ImageGlass"; Choco = "imageglass" }
            @{ Name = "IrfanView"; Winget = "IrfanSkiljan.IrfanView"; Choco = "irfanview" }
            @{ Name = "ShareX"; Winget = "ShareX.ShareX"; Choco = "sharex" }
            @{ Name = "OBS Studio"; Winget = "OBSProject.OBSStudio"; Choco = "obs-studio" }
            @{ Name = "HandBrake"; Winget = "HandBrake.HandBrake"; Choco = "handbrake" }
            @{ Name = "Audacity"; Winget = "Audacity.Audacity"; Choco = "audacity" }
            @{ Name = "GIMP"; Winget = "GIMP.GIMP"; Choco = "gimp" }
            @{ Name = "Krita"; Winget = "KDE.Krita"; Choco = "krita" }
            @{ Name = "Inkscape"; Winget = "Inkscape.Inkscape"; Choco = "inkscape" }
            @{ Name = "Blender"; Winget = "BlenderFoundation.Blender"; Choco = "blender" }
        )
    }
    
    # === COMMUNICATION ===
    Communication = @{
        DisplayName = "Communication & Social"
        Apps        = @(
            @{ Name = "Discord"; Winget = "Discord.Discord"; Choco = "discord" }
            @{ Name = "Slack"; Winget = "SlackTechnologies.Slack"; Choco = "slack" }
            @{ Name = "Microsoft Teams (Work)"; Winget = "Microsoft.Teams"; Choco = "microsoft-teams" }
            @{ Name = "Microsoft Teams (Classic)"; Winget = "Microsoft.Teams.Classic"; Choco = "microsoft-teams" }
            @{ Name = "Zoom"; Winget = "Zoom.Zoom"; Choco = "zoom" }
            @{ Name = "Telegram"; Winget = "Telegram.TelegramDesktop"; Choco = "telegram" }
            @{ Name = "Signal"; Winget = "OpenWhisperSystems.Signal"; Choco = "signal" }
            @{ Name = "WhatsApp"; Winget = "WhatsApp.WhatsApp"; Choco = "whatsapp" }
            @{ Name = "Thunderbird"; Winget = "Mozilla.Thunderbird"; Choco = "thunderbird" }
        )
    }
    
    # === SECURITY ===
    Security      = @{
        DisplayName = "Security & Privacy"
        Apps        = @(
            @{ Name = "Bitwarden"; Winget = "Bitwarden.Bitwarden"; Choco = "bitwarden" }
            @{ Name = "KeePassXC"; Winget = "KeePassXCTeam.KeePassXC"; Choco = "keepassxc" }
            @{ Name = "Malwarebytes"; Winget = "Malwarebytes.Malwarebytes"; Choco = "malwarebytes" }
            @{ Name = "ProtonVPN"; Winget = "ProtonTechnologies.ProtonVPN"; Choco = "protonvpn" }
            @{ Name = "Mullvad VPN"; Winget = "MullvadVPN.MullvadVPN"; Choco = "mullvad-vpn" }
            @{ Name = "WireGuard"; Winget = "WireGuard.WireGuard"; Choco = "wireguard" }
            @{ Name = "VeraCrypt"; Winget = "IDRIX.VeraCrypt"; Choco = "veracrypt" }
            @{ Name = "Gpg4win"; Winget = "GnuPG.Gpg4win"; Choco = "gpg4win" }
        )
    }
    
    # === DEV TOOLS ===
    DevTools      = @{
        DisplayName = "Developer Tools"
        Apps        = @(
            @{ Name = "Visual Studio Code"; Winget = "Microsoft.VisualStudioCode"; Choco = "vscode" }
            @{ Name = "Visual Studio 2022 Community"; Winget = "Microsoft.VisualStudio.2022.Community"; Choco = "visualstudio2022community" }

            @{ Name = "JetBrains Toolbox"; Winget = "JetBrains.Toolbox"; Choco = "jetbrainstoolbox" }
            @{ Name = "Sublime Text"; Winget = "SublimeHQ.SublimeText.4"; Choco = "sublimetext4" }
            @{ Name = "Notepad++"; Winget = "Notepad++.Notepad++"; Choco = "notepadplusplus" }
            @{ Name = "Git"; Winget = "Git.Git"; Choco = "git" }
            @{ Name = "GitHub Desktop"; Winget = "GitHub.GitHubDesktop"; Choco = "github-desktop" }
            @{ Name = "Windows Terminal"; Winget = "Microsoft.WindowsTerminal"; Choco = "microsoft-windows-terminal" }
            @{ Name = "PowerShell 7"; Winget = "Microsoft.PowerShell"; Choco = "powershell-core" }
            @{ Name = "Docker Desktop"; Winget = "Docker.DockerDesktop"; Choco = "docker-desktop" }
            @{ Name = "Postman"; Winget = "Postman.Postman"; Choco = "postman" }
            @{ Name = "HeidiSQL"; Winget = "HeidiSQL.HeidiSQL"; Choco = "heidisql" }
            @{ Name = "DBeaver"; Winget = "dbeaver.dbeaver"; Choco = "dbeaver" }
            @{ Name = "WinSCP"; Winget = "WinSCP.WinSCP"; Choco = "winscp" }
            @{ Name = "PuTTY"; Winget = "PuTTY.PuTTY"; Choco = "putty" }
            @{ Name = "FileZilla"; Winget = "TimKosse.FileZilla.Client"; Choco = "filezilla" }
        )
    }
    
    # === GAMING ===
    Gaming        = @{
        DisplayName = "Gaming & Game Launchers"
        Apps        = @(
            @{ Name = "Steam"; Winget = "Valve.Steam"; Choco = "steam" }
            @{ Name = "Epic Games Launcher"; Winget = "EpicGames.EpicGamesLauncher"; Choco = "epicgameslauncher" }
            @{ Name = "GOG Galaxy"; Winget = "GOG.Galaxy"; Choco = "goggalaxy" }
            @{ Name = "EA App"; Winget = "ElectronicArts.EADesktop"; Choco = "ea-app" }
            @{ Name = "Ubisoft Connect"; Winget = "Ubisoft.Connect"; Choco = "ubisoft-connect" }
            @{ Name = "Battle.net"; Winget = "Blizzard.BattleNet"; Choco = "battle.net" }
            @{ Name = "Playnite"; Winget = "Playnite.Playnite"; Choco = "playnite" }
            @{ Name = "Heroic Games Launcher"; Winget = "HeroicGamesLauncher.HeroicGamesLauncher"; Choco = "heroic" }
            @{ Name = "MSI Afterburner"; Winget = "Guru3D.Afterburner"; Choco = "msiafterburner" }
            @{ Name = "RTSS"; Winget = "Guru3D.RTSS"; Choco = "rtss" }
        )
    }
    
    # === PRODUCTIVITY ===
    Productivity  = @{
        DisplayName = "Productivity & Office"
        Apps        = @(
            @{ Name = "Microsoft Office 365 (Online)"; Winget = "Microsoft.Office"; Choco = "office365business" }
            @{ Name = "LibreOffice"; Winget = "TheDocumentFoundation.LibreOffice"; Choco = "libreoffice-fresh" }
            @{ Name = "ONLYOFFICE"; Winget = "ONLYOFFICE.DesktopEditors"; Choco = "onlyoffice" }
            @{ Name = "Notion"; Winget = "Notion.Notion"; Choco = "notion" }
            @{ Name = "Obsidian"; Winget = "Obsidian.Obsidian"; Choco = "obsidian" }
            @{ Name = "Evernote"; Winget = "Evernote.Evernote"; Choco = "evernote" }
            @{ Name = "Adobe Reader DC"; Winget = "Adobe.Acrobat.Reader.64-bit"; Choco = "adobereader" }
            @{ Name = "Foxit Reader"; Winget = "Foxit.FoxitReader"; Choco = "foxitreader" }
            @{ Name = "SumatraPDF"; Winget = "SumatraPDF.SumatraPDF"; Choco = "sumatrapdf" }
            @{ Name = "Calibre"; Winget = "calibre.calibre"; Choco = "calibre" }
        )
    }
    
    # === NETWORK ===
    Network       = @{
        DisplayName = "Network & Download Tools"
        Apps        = @(
            @{ Name = "qBittorrent"; Winget = "qBittorrent.qBittorrent"; Choco = "qbittorrent" }
            @{ Name = "Free Download Manager"; Winget = "SoftDeluxe.FreeDownloadManager"; Choco = "freedownloadmanager" }
            @{ Name = "JDownloader"; Winget = "AppWork.JDownloader"; Choco = "jdownloader" }
            @{ Name = "Wireshark"; Winget = "WiresharkFoundation.Wireshark"; Choco = "wireshark" }
            @{ Name = "Nmap"; Winget = "Insecure.Nmap"; Choco = "nmap" }
            @{ Name = "Advanced IP Scanner"; Winget = "Famatech.AdvancedIPScanner"; Choco = "advanced-ip-scanner" }
            @{ Name = "Angry IP Scanner"; Winget = "angryziber.AngryIPScanner"; Choco = "angryip" }
        )
    }
    
    # === DRIVERS ===
    Drivers       = @{
        DisplayName = "GPU Drivers & Tools"
        Apps        = @(
            @{ Name = "NVIDIA GeForce Experience"; Winget = "NVIDIA.GeForceExperience"; Choco = "geforce-experience" }
            @{ Name = "AMD Radeon Software"; Winget = "AMD.RyzenMaster"; Choco = "amd-ryzen-master" }
            @{ Name = "Intel Graphics Command Center"; Winget = "Intel.IntelDriverAndSupportAssistant"; Choco = "intel-dsa" }
            @{ Name = "DDU (Display Driver Uninstaller)"; Winget = "Wagnardsoft.DisplayDriverUninstaller"; Choco = "ddu" }
            @{ Name = "NVCleanstall"; Winget = "TechPowerUp.NVCleanstall"; Choco = "nvcleanstall" }
            @{ Name = "Snappy Driver Installer Origin"; Winget = "GlennDelahoy.SnappyDriverInstallerOrigin"; Choco = "sdio" }
        )
    }
}

<#
.SYNOPSIS
    Gets the complete list of essential apps organized by category.
    
.OUTPUTS
    [hashtable] The essentials app dictionary.
#>
function Get-WinDebloat7EssentialsList {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    return $Script:EssentialsApps
}

#endregion

#region Installation Functions

<#
.SYNOPSIS
    Installs software packages using Winget or Chocolatey.
    
.PARAMETER Packages
    Array of package IDs to install (Winget format: "Publisher.Package").
    
.PARAMETER PackageManager
    Which package manager to use. Default: Auto-detect (Winget preferred).
    
.PARAMETER Quiet
    Suppress installation prompts where possible.
    
.OUTPUTS
    [psobject] Installation results summary.
#>
function Install-WinDebloat7Software {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([psobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Packages,
        
        [ValidateSet("Winget", "Chocolatey", "Auto")]
        [string]$PackageManager = "Auto",
        
        [switch]$Quiet
    )
    
    # Auto-detect package manager
    if ($PackageManager -eq "Auto") {
        if (Test-PackageManager -Name "Winget") {
            $PackageManager = "Winget"
        }
        elseif (Test-PackageManager -Name "Chocolatey") {
            $PackageManager = "Chocolatey"
        }
        else {
            Write-Log -Message "No package manager found. Installing Winget..." -Level Warning
            if (-not (Install-PackageManager -Name "Winget" -Force)) {
                throw "Failed to install package manager"
            }
            $PackageManager = "Winget"
        }
    }
    
    Write-Log -Message "Installing $($Packages.Count) packages via $PackageManager" -Level Info
    
    $results = @{
        PackageManager = $PackageManager
        TotalRequested = $Packages.Count
        Successful     = 0
        Failed         = 0
        Skipped        = 0
        Details        = @()
    }
    
    $current = 0
    foreach ($pkg in $Packages) {
        $current++
        $percent = [math]::Round(($current / $Packages.Count) * 100)
        Write-Progress -Activity "Installing Software" -Status "[$current/$($Packages.Count)] $pkg" -PercentComplete $percent
        
        try {
            if ($PSCmdlet.ShouldProcess($pkg, "Install via $PackageManager")) {
                $output = switch ($PackageManager) {
                    "Winget" {
                        $cmdArgs = @("install", $pkg, "--accept-source-agreements", "--accept-package-agreements")
                        if ($Quiet) { $cmdArgs += "--silent" }
                        & winget @cmdArgs 2>&1
                    }
                    "Chocolatey" {
                        $cmdArgs = @("install", $pkg, "-y")
                        if ($Quiet) { $cmdArgs += "--no-progress" }
                        & choco @cmdArgs 2>&1
                    }
                }
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Log -Message "Installed: $pkg" -Level Success
                    $results.Successful++
                    $results.Details += @{ Package = $pkg; Status = "Success" }
                }
                elseif ($output -match "already installed|No applicable|No available upgrade") {
                    Write-Log -Message "Already installed: $pkg" -Level Info
                    $results.Skipped++
                    $results.Details += @{ Package = $pkg; Status = "Skipped (Already Installed)" }
                }
                else {
                    Write-Log -Message "Failed to install: $pkg - Exit code: $LASTEXITCODE" -Level Warning
                    $results.Failed++
                    $results.Details += @{ Package = $pkg; Status = "Failed"; ExitCode = $LASTEXITCODE }
                }
            }
        }
        catch {
            Write-Log -Message "Error installing $pkg`: $($_.Exception.Message)" -Level Error
            $results.Failed++
            $results.Details += @{ Package = $pkg; Status = "Error"; Error = $_.Exception.Message }
        }
    }
    
    Write-Progress -Activity "Installing Software" -Completed
    
    Write-Log -Message "Installation complete: $($results.Successful) installed, $($results.Skipped) skipped, $($results.Failed) failed" -Level $(if ($results.Failed -eq 0) { "Success" } else { "Warning" })
    
    return [pscustomobject]$results
}

<#
.SYNOPSIS
    Installs essential apps by category with interactive selection.
    
.PARAMETER Categories
    Array of category names to install. If omitted, shows interactive menu.
    
.PARAMETER PackageManager
    Which package manager to use.
    
.PARAMETER InstallAll
    Install all apps from selected categories without prompting.
    
.EXAMPLE
    Install-WinDebloat7Essentials -Categories Browsers, Utilities
    
.EXAMPLE
    Install-WinDebloat7Essentials -InstallAll
#>
function Install-WinDebloat7Essentials {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [ValidateSet("Browsers", "Runtimes", "Utilities", "Media", "Communication", 
            "Security", "DevTools", "Gaming", "Productivity", "Network", "Drivers")]
        [string[]]$Categories,
        
        [ValidateSet("Winget", "Chocolatey", "Auto")]
        [string]$PackageManager = "Auto",
        
        [switch]$InstallAll
    )
    
    $essentials = Get-WinDebloat7EssentialsList
    
    # Determine package manager
    if ($PackageManager -eq "Auto") {
        $PackageManager = if (Test-PackageManager -Name "Winget") { "Winget" } else { "Chocolatey" }
    }
    
    # If no categories specified, show interactive menu
    if (-not $Categories) {
        Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║       Essential Apps Installer            ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host "Using: $PackageManager`n" -ForegroundColor Gray
        
        $i = 1
        $categoryMap = @{}
        foreach ($cat in $essentials.Keys | Sort-Object) {
            $count = $essentials[$cat].Apps.Count
            Write-Host "  [$i] $($essentials[$cat].DisplayName) ($count apps)" -ForegroundColor White
            $categoryMap[$i] = $cat
            $i++
        }
        Write-Host "  [A] Install ALL Categories" -ForegroundColor Yellow
        Write-Host "  [Q] Cancel`n" -ForegroundColor Gray
        
        $selection = Read-Host "Select categories (comma-separated, e.g., 1,3,5)"
        
        if ($selection -match '^[Qq]$') { return }
        
        if ($selection -match '^[Aa]$') {
            $Categories = $essentials.Keys
        }
        else {
            $Categories = @()
            foreach ($num in ($selection -split ',')) {
                $num = $num.Trim()
                if ($categoryMap.ContainsKey([int]$num)) {
                    $Categories += $categoryMap[[int]$num]
                }
            }
        }
    }
    
    if ($Categories.Count -eq 0) {
        Write-Log -Message "No categories selected." -Level Warning
        return
    }
    
    # Collect packages from selected categories
    $packagesToInstall = @()
    
    foreach ($cat in $Categories) {
        if (-not $essentials.ContainsKey($cat)) { continue }
        
        $catData = $essentials[$cat]
        Write-Host "`n$($catData.DisplayName):" -ForegroundColor Cyan
        
        if ($InstallAll) {
            foreach ($app in $catData.Apps) {
                $pkgId = if ($PackageManager -eq "Winget") { $app.Winget } else { $app.Choco }
                $packagesToInstall += $pkgId
                Write-Host "  [+] $($app.Name)" -ForegroundColor Green
            }
        }
        else {
            # Show individual app selection
            $j = 1
            $appMap = @{}
            foreach ($app in $catData.Apps) {
                Write-Host "  [$j] $($app.Name)" -ForegroundColor White
                $appMap[$j] = $app
                $j++
            }
            Write-Host "  [A] All in category  [S] Skip category" -ForegroundColor Gray
            
            $appSel = Read-Host "Select apps (comma-separated)"
            
            if ($appSel -match '^[Ss]$') { continue }
            
            if ($appSel -match '^[Aa]$') {
                foreach ($app in $catData.Apps) {
                    $pkgId = if ($PackageManager -eq "Winget") { $app.Winget } else { $app.Choco }
                    $packagesToInstall += $pkgId
                }
            }
            else {
                foreach ($num in ($appSel -split ',')) {
                    $num = $num.Trim()
                    if ($appMap.ContainsKey([int]$num)) {
                        $app = $appMap[[int]$num]
                        $pkgId = if ($PackageManager -eq "Winget") { $app.Winget } else { $app.Choco }
                        $packagesToInstall += $pkgId
                    }
                }
            }
        }
    }
    
    if ($packagesToInstall.Count -eq 0) {
        Write-Log -Message "No packages selected for installation." -Level Warning
        return
    }
    
    Write-Host "`nInstalling $($packagesToInstall.Count) packages..." -ForegroundColor Cyan
    
    $result = Install-WinDebloat7Software -Packages $packagesToInstall -PackageManager $PackageManager -Quiet
    
    Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║         Installation Complete             ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host "  Installed: $($result.Successful)" -ForegroundColor Green
    Write-Host "  Skipped:   $($result.Skipped)" -ForegroundColor Yellow
    Write-Host "  Failed:    $($result.Failed)" -ForegroundColor $(if ($result.Failed -gt 0) { "Red" } else { "Gray" })
}

<#
.SYNOPSIS
    Installs packages from a profile configuration.
    
.PARAMETER Config
    The configuration object loaded from a YAML profile.
#>
function Install-WinDebloat7ProfileSoftware {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [psobject]$Config
    )
    
    if (-not $Config.software) {
        Write-Log -Message "No software configuration in profile." -Level Info
        return
    }
    
    $pkgMgr = $Config.software.package_manager ?? "Winget"
    $installList = $Config.software.install_list ?? @()
    
    if ($installList.Count -eq 0) {
        Write-Log -Message "No packages specified in profile install_list." -Level Info
        return
    }
    
    Write-Log -Message "Installing profile software via $pkgMgr..." -Level Info
    Install-WinDebloat7Software -Packages $installList -PackageManager $pkgMgr
}

#endregion

Export-ModuleMember -Function @(
    'Test-PackageManager',
    'Install-PackageManager',
    'Get-WinDebloat7EssentialsList',
    'Install-WinDebloat7Software',
    'Install-WinDebloat7Essentials',
    'Install-WinDebloat7ProfileSoftware'
)
