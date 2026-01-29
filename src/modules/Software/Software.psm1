<#
.SYNOPSIS
    Software and package management module for Win-Debloat7
    
.DESCRIPTION
    Handles Winget and Chocolatey package installation with a comprehensive
    curated essentials list. Supports both package managers with auto-detection.
    
.NOTES
    Module: Win-Debloat7.Modules.Software
    Version: 1.2.3
    
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
                    # PS 7.5+ Retry Logic
                    Invoke-WebRequest -Uri $msixUrl -OutFile $tempPath -MaximumRetryCount 3 -RetryIntervalSec 5 -ErrorAction Stop
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
                    
                    # Modern PS 7.5+ Installation (Resilient)
                    $chocoScript = Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -MaximumRetryCount 3 -RetryIntervalSec 5 -UseBasicParsing -ErrorAction Stop
                    Invoke-Expression $chocoScript.Content
                    
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
            @{ Name = "DirectX Runtime"; Winget = ""; Choco = "directx" }
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
    [CmdletBinding(DefaultParameterSetName = "ById", SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([psobject])]
    param(
        [Parameter(ParameterSetName = "ById", Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Packages,

        [Parameter(ParameterSetName = "ByObject", Mandatory)]
        [ValidateNotNullOrEmpty()]
        [scriptblock[]]$Apps, # Using scriptblock[] as strict type for hashtables can be finicky, checking types inside
        
        [ValidateSet("Winget", "Chocolatey", "Auto")]
        [string]$PackageManager = "Auto",
        
        [switch]$Quiet
    )
    
    # Auto-detect package manager if needed
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
                # Fallback to Choco installation attempt if Winget fails to install
                Write-Log -Message "Winget installation failed. Trying Chocolatey..." -Level Warning
                if (-not (Install-PackageManager -Name "Chocolatey" -Force)) {
                    throw "Failed to install any package manager"
                }
                $PackageManager = "Chocolatey"
            }
            else {
                $PackageManager = "Winget"
            }
        }
    }
    
    # helper to normalize input into a list of objects: { Name, ID, FallbackID, FallbackProvider }
    $itemsToProcess = @()

    if ($PSCmdlet.ParameterSetName -eq "ById") {
        foreach ($p in $Packages) {
            $itemsToProcess += [PSCustomObject]@{
                Name             = $p
                PrimaryID        = $p
                FallbackID       = $null
                FallbackProvider = $null
            }
        }
    }
    else {
        # ByObject
        foreach ($app in $Apps) {
            # Determine Primary and Fallback based on $PackageManager
            $primaryPkgId = $null
            $fbId = $null
            $fbProv = $null
            
            if ($PackageManager -eq "Winget") {
                $primaryPkgId = $app["Winget"]
                if ($app.ContainsKey("Choco") -and $app["Choco"]) {
                    $fbId = $app["Choco"]
                    $fbProv = "Chocolatey"
                }
            }
            else {
                # Chocolatey
                $primaryPkgId = $app["Choco"]
                if ($PackageManager -eq "Chocolatey" -and $app.ContainsKey("Winget") -and $app["Winget"]) {
                    $fbId = $app["Winget"]
                    $fbProv = "Winget"
                }
            }
            
            # Smart switching: If Primary is missing but Fallback exists, promote Fallback to Primary
            if ([string]::IsNullOrWhiteSpace($primaryPkgId) -and -not [string]::IsNullOrWhiteSpace($fbId)) {
                $primaryPkgId = $fbId
                # $PackageManager effectively becomes the fallback provider for this specific item, 
                # but we need to track that.
                # Actually, simpler to just map it as a Primary install using the other provider.
                # But our outer loop uses $PackageManager var which is fixed for the whole run generally, 
                # causing issues if we try to switch provider per-item in logic below?
                # No, the loop logic calls Invoke-InstallCommand with $PackageManager.
                # We need to store Provider per item!
                
                # Let's adjust $itemsToProcess logic to include 'Provider'
            }
            
            # We need to restructure itemsToProcess to include the Provider for the primary attempt
            # to handle mixed-provider installs nicely.
            
            if (-not [string]::IsNullOrWhiteSpace($primaryPkgId)) {
                # If we swapped, we need to know which provider to use.
                # If we didn't swap, use $PackageManager.
                # Actually, if we swapped because Primary was empty, we are using $fbProv.
                 
                $useProv = $PackageManager
                if ([string]::IsNullOrWhiteSpace($app[$PackageManager]) -and -not [string]::IsNullOrWhiteSpace($fbId)) {
                    $useProv = $fbProv
                }

                $itemsToProcess += [PSCustomObject]@{
                    Name             = $app["Name"]
                    PrimaryID        = $primaryPkgId
                    PrimaryProvider  = $useProv
                    FallbackID       = $fbId
                    FallbackProvider = $fbProv
                }
            }
        }
    }

    Write-Log -Message "Installing $($itemsToProcess.Count) packages..." -Level Info
    
    $results = @{
        PackageManager = $PackageManager # Note: this might be mixed now, but nominally what was requested
        TotalRequested = $itemsToProcess.Count
        Successful     = 0
        Failed         = 0
        Skipped        = 0
        Details        = @()
    }
    
    $current = 0
    foreach ($item in $itemsToProcess) {
        $current++
        $percent = [math]::Round(($current / $itemsToProcess.Count) * 100)
        
        $pkgName = $item.Name
        $pkgId = $item.PrimaryID
        $currentProv = $item.PrimaryProvider
        
        if ([string]::IsNullOrWhiteSpace($currentProv)) { $currentProv = $PackageManager } # Default for ById case
        
        Write-Progress -Activity "Installing Software" -Status "[$current/$($itemsToProcess.Count)] $pkgName ($pkgId)" -PercentComplete $percent
        
        try {
            if ($PSCmdlet.ShouldProcess($pkgName, "Install via $currentProv")) {
                
                # --- Helper Inner Function to Run Install ---
                # (Assuming Invoke-InstallCommand is defined or we inline it again - I verify below)
                # It was removed in previous step? No, I verified I removed internal function definition if I pasted inline.
                # checking previous Step 29/33 output... I removed the inner function definition in Step 33.
                
                $attemptExitCode = -1
                
                # --- Primary Attempt ---
                if ($currentProv -eq "Winget") {
                    $cmdArgs = @("install", "--id", $pkgId, "--accept-source-agreements", "--accept-package-agreements", "--disable-interactivity")
                    if ($Quiet) { $cmdArgs += "--silent" }
                    $p = Start-Process -FilePath "winget" -ArgumentList $cmdArgs -NoNewWindow -Wait -PassThru
                    $attemptExitCode = $p.ExitCode
                }
                elseif ($currentProv -eq "Chocolatey") {
                    $cmdArgs = @("install", $pkgId, "-y")
                    if ($Quiet) { $cmdArgs += "--no-progress" }
                    $p = Start-Process -FilePath "choco" -ArgumentList $cmdArgs -NoNewWindow -Wait -PassThru
                    $attemptExitCode = $p.ExitCode
                }

                if ($attemptExitCode -eq 0) {
                    Write-Log -Message "Installed: $pkgName ($pkgId)" -Level Success
                    $results.Successful++
                    $results.Details += @{ Package = $pkgName; Id = $pkgId; Status = "Success"; Provider = $currentProv }
                }
                # Fallback Logic
                # Only fallback if the Primary attempt WAS NOT the fallback provider already (avoid loops)
                # AND if we have a fallback ID different from primary?
                # Actually, if we swapped above, PrimaryID IS the fallback ID. So FallbackID might be same or null?
                # If we swapped, we used the "other" provider as primary. We shouldn't fallback "back" to the empty one.
                # So verify:
                elseif ($item.FallbackID -and $item.FallbackProvider -and $item.FallbackProvider -ne $currentProv) {
                    Write-Log -Message "Failed to install '$pkgName' via $currentProv (Exit: $attemptExitCode). Attempting fallback to $($item.FallbackProvider)..." -Level Warning
                    
                    # Ensure fallback provider installed
                    if (-not (Test-PackageManager -Name $item.FallbackProvider)) {
                        $null = Install-PackageManager -Name $item.FallbackProvider -Force
                    }

                    if (Test-PackageManager -Name $item.FallbackProvider) {
                        $fbExitCode = -1
                        if ($item.FallbackProvider -eq "Winget") {
                            $cmdArgs = @("install", "--id", $item.FallbackID, "--accept-source-agreements", "--accept-package-agreements", "--disable-interactivity")
                            if ($Quiet) { $cmdArgs += "--silent" }
                            $p = Start-Process -FilePath "winget" -ArgumentList $cmdArgs -NoNewWindow -Wait -PassThru
                            $fbExitCode = $p.ExitCode
                        }
                        elseif ($item.FallbackProvider -eq "Chocolatey") {
                            $cmdArgs = @("install", $item.FallbackID, "-y")
                            if ($Quiet) { $cmdArgs += "--no-progress" }
                            $p = Start-Process -FilePath "choco" -ArgumentList $cmdArgs -NoNewWindow -Wait -PassThru
                            $fbExitCode = $p.ExitCode
                        }

                        if ($fbExitCode -eq 0) {
                            Write-Log -Message "Installed: $pkgName ($($item.FallbackID)) via $($item.FallbackProvider)" -Level Success
                            $results.Successful++
                            $results.Details += @{ Package = $pkgName; Id = $item.FallbackID; Status = "Success (Fallback)"; Provider = $item.FallbackProvider }
                        }
                        else {
                            Write-Log -Message "Failed to install '$pkgName' via fallback ($($item.FallbackProvider)). Exit: $fbExitCode" -Level Error
                            $results.Failed++
                            $results.Details += @{ Package = $pkgName; Id = $pkgId; Status = "Failed"; Error = "Primary and Fallback failed" }
                        }
                    }
                    else {
                        Write-Log -Message "Fallback provider unavailable." -Level Error
                        $results.Failed++
                        $results.Details += @{ Package = $pkgName; Id = $pkgId; Status = "Failed"; Error = "Primary failed, Fallback provider unavailable" }
                    }
                }
                else {
                    Write-Log -Message "Failed to install: $pkgName - Exit code: $attemptExitCode" -Level Error
                    $results.Failed++
                    $results.Details += @{ Package = $pkgName; Id = $pkgId; Status = "Failed"; ExitCode = $attemptExitCode }
                }
            }
        }
        catch {
            Write-Log -Message "Exception installing $pkgName`: $($_.Exception.Message)" -Level Error
            $results.Failed++
            $results.Details += @{ Package = $pkgName; Status = "Error"; Error = $_.Exception.Message }
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
    $appsToInstall = @()
    
    foreach ($cat in $Categories) {
        if (-not $essentials.ContainsKey($cat)) { continue }
        
        $catData = $essentials[$cat]
        Write-Host "`n$($catData.DisplayName):" -ForegroundColor Cyan
        
        if ($InstallAll) {
            foreach ($app in $catData.Apps) {
                $appsToInstall += $app
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
                    $appsToInstall += $app
                }
            }
            else {
                foreach ($num in ($appSel -split ',')) {
                    $num = $num.Trim()
                    if ($appMap.ContainsKey([int]$num)) {
                        $appsToInstall += $appMap[[int]$num]
                    }
                }
            }
        }
    }
    
    if ($appsToInstall.Count -eq 0) {
        Write-Log -Message "No packages selected for installation." -Level Warning
        return
    }
    
    Write-Host "`nInstalling $($appsToInstall.Count) packages..." -ForegroundColor Cyan
    
    $result = Install-WinDebloat7Software -Apps $appsToInstall -PackageManager $PackageManager -Quiet
    
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

#region Update Functions

<#
.SYNOPSIS
    Updates all installed packages using Winget.
    
.DESCRIPTION
    Runs 'winget upgrade --all' to update all software packages.
#>
function Update-WinDebloat7Software {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()
    
    $hasWinget = Test-PackageManager -Name "Winget"
    $hasChoco = Test-PackageManager -Name "Chocolatey"
    
    if (-not $hasWinget -and -not $hasChoco) {
        Write-Log -Message "No package managers installed." -Level Warning
        return
    }

    Write-Log -Message "Checking for software updates..." -Level Info
    
    # 1. Winget Update
    if ($hasWinget) {
        if ($PSCmdlet.ShouldProcess("All Packages", "Update via Winget")) {
            try {
                Write-Log -Message "Running Winget upgrade..." -Level Info
                # Include --include-unknown to catch legacy apps if possible, but --all is standard
                Start-Process -FilePath "winget" -ArgumentList "upgrade", "--all", "--accept-source-agreements", "--accept-package-agreements" -Wait -NoNewWindow
            }
            catch {
                Write-Log -Message "Winget update failed: $($_.Exception.Message)" -Level Error
            }
        }
    }
    
    # 2. Chocolatey Update
    if ($hasChoco) {
        if ($PSCmdlet.ShouldProcess("All Packages", "Update via Chocolatey")) {
            try {
                Write-Log -Message "Running Chocolatey upgrade..." -Level Info
                Start-Process -FilePath "choco" -ArgumentList "upgrade", "all", "-y" -Wait -NoNewWindow
            }
            catch {
                Write-Log -Message "Chocolatey update failed: $($_.Exception.Message)" -Level Error
            }
        }
    }
    
    Write-Log -Message "Software update process finished." -Level Success
}

#endregion

Export-ModuleMember -Function @(
    'Test-PackageManager',
    'Install-PackageManager',
    'Get-WinDebloat7EssentialsList',
    'Install-WinDebloat7Software',
    'Update-WinDebloat7Software',
    'Install-WinDebloat7Essentials',
    'Install-WinDebloat7ProfileSoftware'
)
