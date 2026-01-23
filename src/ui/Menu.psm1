<#
.SYNOPSIS
    Interactive Menu System for Win-Debloat7
    
.DESCRIPTION
    Provides the TUI for authenticating users and selecting profiles.
    
.NOTES
    Module: Win-Debloat7.UI.Menu
    Version: 1.0.0
#>

#Requires -Version 7.5

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\Colors.psm1" -Force
Import-Module "$PSScriptRoot\..\core\Config.psm1" -Force
Import-Module "$PSScriptRoot\..\core\State.psm1" -Force
Import-Module "$PSScriptRoot\..\modules\Bloatware\Bloatware.psm1" -Force
Import-Module "$PSScriptRoot\..\modules\Privacy\Privacy.psm1" -Force
Import-Module "$PSScriptRoot\..\modules\Performance\Performance.psm1" -Force
Import-Module "$PSScriptRoot\..\modules\Windows11\Version-Detection.psm1" -Force
Import-Module "$PSScriptRoot\..\modules\Software\Software.psm1" -Force
Import-Module "$PSScriptRoot\..\modules\Drivers\Drivers.psm1" -Force
Import-Module "$PSScriptRoot\..\modules\Network\Network.psm1" -Force
Import-Module "$PSScriptRoot\..\modules\Privacy\Tasks.psm1" -Force
Import-Module "$PSScriptRoot\..\modules\Privacy\Hosts.psm1" -Force

function Show-MainMenu {
    while ($true) {
        Show-WD7Header
        
        Write-WD7Host "Choose an option:" -Color Info
        Write-WD7Host "  [1] Quick Debloat (Recommended)" -Color White
        Write-WD7Host "  [2] Launch Premium GUI" -Color Primary
        Write-WD7Host "  [3] Select Profile..." -Color White
        Write-WD7Host "  [4] Install Essential Apps" -Color White
        Write-WD7Host "  [5] Update Drivers" -Color White
        Write-WD7Host "  [6] Network & Privacy Settings" -Color White
        Write-WD7Host "  [7] System Info" -Color White
        Write-WD7Host "  [8] Snapshots / Restore" -Color White
        Write-WD7Host "  [Q] Quit" -Color Dark
        
        $choice = Read-Host "`nEnter selection"
        
        switch ($choice) {
            "1" { Invoke-Profile "$PSScriptRoot\..\..\profiles\moderate.yaml" }
            "2" { 
                try {
                    Import-Module "$PSScriptRoot\gui\GUI.psm1" -Force
                    Show-WinDebloat7GUI
                }
                catch {
                    Write-WD7Host "Failed to launch GUI: $($_.Exception.Message)" -Color Error
                    Start-Sleep -Seconds 2
                }
            }
            "3" { Show-ProfileSelection }
            "4" { Install-WinDebloat7Essentials }
            "5" { Update-WinDebloat7Drivers }
            "6" { Show-NetworkPrivacyMenu }
            "7" { Show-SystemInfo }
            "8" { Show-SnapshotMenu }
            "Q" { exit }
            "q" { exit }
            default { Write-WD7Host "Invalid selection." -Color Warning; Start-Sleep -Seconds 1 }
        }
    }
}


function Show-ProfileSelection {
    Show-WD7Header
    Write-WD7Host "Select a Profile to Apply:" -Color Secondary
    
    $profiles = Get-ChildItem "$PSScriptRoot\..\..\profiles\*.yaml"
    $i = 1
    $profileMap = @{}
    
    foreach ($p in $profiles) {
        Write-WD7Host "  [$i] $($p.BaseName)" -Color White
        $profileMap[$i] = $p.FullName
        $i++
    }
    
    Write-WD7Host "  [B] Back" -Color Dark
    $sel = Read-Host "`nSelect Profile number"
    
    if ($sel -match "^[Bb]$") { return }
    
    if ($profileMap.ContainsKey([int]$sel)) {
        Invoke-Profile $profileMap[[int]$sel]
    }
    else {
        Write-WD7Host "Invalid Profile." -Color Error; Start-Sleep -Seconds 1
    }
}

function Invoke-Profile {
    param($Path)
    
    try {
        Show-WD7Header
        Write-WD7Host "Loading Profile: $Path" -Color Info
        $config = Import-WinDebloat7Config -Path $Path
        
        Write-WD7Host "`nApplying Configuration..." -Color Primary
        
        # 1. Auto-Snapshot before changes
        Write-WD7Host "Creating safety snapshot..." -Color Info
        New-WinDebloat7Snapshot -Name "Pre-$($config.metadata.name)" -Description "Before applying profile" | Out-Null
        
        # 2. Modules
        Remove-WinDebloat7Bloatware -Config $config
        Set-WinDebloat7Privacy -Config $config
        Set-WinDebloat7Performance -Config $config
        
        Write-WD7Host "`n[✓] Optimization Complete!" -Color Success
        Read-Host "Press Enter to return to menu..."
        
    }
    catch {
        Write-WD7Host "Error: $($_.Exception.Message)" -Color Error
        Read-Host "Press Enter to continue..."
    }
}

function Show-SystemInfo {
    Show-WD7Header
    $ver = Get-WindowsVersionInfo
    
    Write-WD7Host "System Information" -Color Secondary
    Write-Host "  OS:       " -NoNewline; Write-WD7Host $ver.ProductName -Color White
    Write-Host "  Version:  " -NoNewline; Write-WD7Host "$($ver.DisplayVersion) ($($ver.FriendlyName))" -Color White
    Write-Host "  Build:    " -NoNewline; Write-WD7Host $ver.BuildNumber -Color White
    Write-Host "  Is Win11: " -NoNewline; Write-WD7Host $ver.IsWindows11 -Color White
    
    Read-Host "`nPress Enter to return..."
}

function Show-SnapshotMenu {
    Show-WD7Header
    Write-WD7Host "Snapshot Management" -Color Secondary
    
    $snaps = Get-WinDebloat7Snapshot
    if ($snaps.Count -eq 0) {
        Write-WD7Host "No snapshots found." -Color Info
    }
    else {
        $snaps | Format-Table Timestamp, Name, Id -AutoSize | Out-String | Write-Host
    }
    
    Write-WD7Host "`n [C] Create Snapshot  [R] Restore Snapshot  [B] Back" -Color Info
    $c = Read-Host "Select"
    
    switch ($c) {
        "C" { New-WinDebloat7Snapshot -Name "Manual-User" -Description "Created via Menu"; Start-Sleep -Seconds 1 }
        "c" { New-WinDebloat7Snapshot -Name "Manual-User" -Description "Created via Menu"; Start-Sleep -Seconds 1 }
        "R" { 
            $id = Read-Host "Enter Snapshot ID to restore"
            if ($id) { Restore-WinDebloat7Snapshot -SnapshotId $id }
            Read-Host "Press Enter..."
        }
    }
}

function Show-NetworkPrivacyMenu {
    Show-WD7Header
    Write-WD7Host "Network & Privacy Settings" -Color Secondary
    
    # Show current status
    $netStatus = Get-WinDebloat7NetworkStatus | Select-Object -First 1
    $hostsStatus = Get-WinDebloat7HostsStatus
    $tasks = Get-WinDebloat7TelemetryTasks -Mode All
    $enabledTasks = ($tasks | Where-Object { $_.Enabled }).Count
    
    Write-Host "`nCurrent Status:" -ForegroundColor Cyan
    Write-Host "  DNS Provider: $($netStatus.DNSProvider)" -ForegroundColor Gray
    Write-Host "  IPv6 Enabled: $($netStatus.IPv6Enabled)" -ForegroundColor Gray
    Write-Host "  Hosts Blocking: $(if ($hostsStatus.TelemetryBlocked) { 'Active' } else { 'Inactive' })" -ForegroundColor Gray
    Write-Host "  Telemetry Tasks: $enabledTasks enabled" -ForegroundColor Gray
    
    Write-Host "`nOptions:" -ForegroundColor Cyan
    Write-WD7Host "  [1] Change DNS Server" -Color White
    Write-WD7Host "  [2] Disable IPv6" -Color White
    Write-WD7Host "  [3] Block Telemetry Domains (Hosts)" -Color White
    Write-WD7Host "  [4] Disable Telemetry Tasks (Safe)" -Color White
    Write-WD7Host "  [5] Disable Telemetry Tasks (Aggressive)" -Color White
    Write-WD7Host "  [6] View Blocked Domains" -Color White
    Write-WD7Host "  [B] Back" -Color Dark
    
    $sel = Read-Host "`nSelect option"
    
    switch ($sel) {
        "1" {
            Write-Host "`nDNS Providers:" -ForegroundColor Cyan
            Write-Host "  [1] Cloudflare (Privacy)" -ForegroundColor White
            Write-Host "  [2] Google" -ForegroundColor White
            Write-Host "  [3] Quad9 (Security)" -ForegroundColor White
            Write-Host "  [4] AdGuard (Ad-Blocking)" -ForegroundColor White
            Write-Host "  [5] OpenDNS" -ForegroundColor White
            Write-Host "  [6] Reset to DHCP" -ForegroundColor White
            $dns = Read-Host "Select"
            switch ($dns) {
                "1" { Set-WinDebloat7DNS -Provider Cloudflare }
                "2" { Set-WinDebloat7DNS -Provider Google }
                "3" { Set-WinDebloat7DNS -Provider Quad9 }
                "4" { Set-WinDebloat7DNS -Provider AdGuard }
                "5" { Set-WinDebloat7DNS -Provider OpenDNS }
                "6" { Set-WinDebloat7DNS -Provider Reset }
            }
            Read-Host "Press Enter..."
        }
        "2" { 
            Disable-WinDebloat7IPv6
            Read-Host "Press Enter..."
        }
        "3" { 
            Add-WinDebloat7HostsBlock
            Read-Host "Press Enter..."
        }
        "4" { 
            Disable-WinDebloat7TelemetryTasks -Mode Safe
            Read-Host "Press Enter..."
        }
        "5" { 
            Disable-WinDebloat7TelemetryTasks -Mode Aggressive
            Read-Host "Press Enter..."
        }
        "6" {
            $domains = Get-WinDebloat7TelemetryDomains
            Write-Host "`nTelemetry Domains to Block ($($domains.Count)):" -ForegroundColor Cyan
            $domains | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            Read-Host "`nPress Enter..."
        }
    }
}

function Invoke-DefenderRemover {
    Write-WD7Host "`n[Defender Remover]" -Color Secondary
    Write-Host "This will download and run the latest Defender Remover by ionuttbara." -ForegroundColor Gray
    Write-Host "Repo: https://github.com/ionuttbara/windows-defender-remover" -ForegroundColor Gray
    
    $confirm = Read-Host "`nDownload and run? [Y/N]"
    if ($confirm -notmatch '^[Yy]') { return }
    
    # Check valid connection
    if (-not (Test-Connection "api.github.com" -Count 1 -Quiet)) {
        Write-WD7Host "Error: Internet connection is required." -Color Error
        Write-Host "Please check your network settings." -ForegroundColor Gray
        Read-Host "Press Enter..."
        return
    }
    
    try {
        Write-Host "Fetching latest release..." -ForegroundColor Cyan
        $apiUrl = "https://api.github.com/repos/ionuttbara/windows-defender-remover/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
        
        # Find the .exe asset
        $asset = $release.assets | Where-Object { $_.name -like "*.exe" } | Select-Object -First 1
        if (-not $asset) {
            # Fallback to .bat or script if exe not found, or generic failure
            throw "Executable asset not found in latest release."
        }
        
        $dlUrl = $asset.browser_download_url
        $destPath = "$env:TEMP\$($asset.name)"
        
        Write-Host "Downloading $($asset.name)..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $dlUrl -OutFile $destPath -ErrorAction Stop
        
        Write-Host "Running Defender Remover..." -ForegroundColor Green
        Start-Process -FilePath $destPath -Wait
        
        Write-Host "Defender Remover execution finished." -ForegroundColor Green
    }
    catch {
        Write-WD7Host "Error launching Defender Remover: $($_.Exception.Message)" -Color Error
        Write-Host "Opening GitHub page instead..." -ForegroundColor Gray
        Start-Process "https://github.com/ionuttbara/windows-defender-remover/releases/latest"
    }
    Read-Host "Press Enter..."
}

function Invoke-WindowsActivation {
    Write-WD7Host "`n[Windows Activation]" -Color Secondary
    Write-Host "This will run the Microsoft Activation Scripts (MAS) via:" -ForegroundColor Gray
    Write-Host "irm https://get.activated.win | iex" -ForegroundColor DarkGray
    
    $confirm = Read-Host "`nRun Activation Script? [Y/N]"
    if ($confirm -notmatch '^[Yy]') { return }
    
    # Check valid connection
    if (-not (Test-Connection "get.activated.win" -Count 1 -Quiet)) {
        Write-WD7Host "Error: Internet connection is required." -Color Error
        Write-Host "Please check your network settings." -ForegroundColor Gray
        Read-Host "Press Enter..."
        return
    }
    
    try {
        Write-Host "Launching MAS..." -ForegroundColor Green
        Invoke-RestMethod https://get.activated.win | Invoke-Expression
    }
    catch {
        Write-WD7Host "Error: $($_.Exception.Message)" -Color Error
    }
    Read-Host "Press Enter..."
}

Export-ModuleMember -Function Show-MainMenu
