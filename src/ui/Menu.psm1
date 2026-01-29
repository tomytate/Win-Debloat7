<#
.SYNOPSIS
    Interactive Menu System for Win-Debloat7
    
.DESCRIPTION
    Provides the TUI for authenticating users and selecting profiles.
    
.NOTES
    Module: Win-Debloat7.UI.Menu
    Version: 1.2.3
#>

#Requires -Version 7.5

using namespace System.Management.Automation

# Modules are loaded via Win-Debloat7.psd1 when running the full framework.
# We skip manual imports here to avoid context/scope collision.


# Extras module (only present in Extras edition)
$extrasModule = "$PSScriptRoot\..\modules\Extras\Extras.psm1"
$extrasAvailable = Test-Path $extrasModule
if ($extrasAvailable) {
    Import-Module $extrasModule -Force -ErrorAction SilentlyContinue
}

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
        Write-WD7Host "  [7] Benchmark System" -Color White
        Write-WD7Host "  [8] System Info" -Color White
        Write-WD7Host "  [9] Snapshots / Restore" -Color White
        Write-WD7Host "  [X] Tweaks & Customization" -Color Secondary
        Write-WD7Host "  [R] System Repair Tools" -Color Warning
        Write-WD7Host "  [F] Windows Features Manager" -Color White
        
        # Show Extras options only if module is available
        if ($extrasAvailable) {
            Write-WD7Host " "
            Write-WD7Host "  ═══ ADVANCED (USE AT OWN RISK) ═══" -Color Warning
            Write-WD7Host "  [D] Defender Remover ⚠️" -Color Warning
            Write-WD7Host "  [A] Windows Activation ⚠️" -Color Warning
        }
        
        Write-WD7Host "  [0] Register Weekly Maintenance" -Color Dark
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
            "7" { Invoke-WinDebloat7Benchmark }
            "8" { Show-SystemInfo }
            "9" { Show-SnapshotMenu }
            "X" { Show-TweaksMenu }
            "x" { Show-TweaksMenu }
            "R" { Show-RepairMenu }
            "r" { Show-RepairMenu }
            "F" { Show-FeaturesMenu }
            "f" { Show-FeaturesMenu }
            "D" {  
                if ($extrasAvailable) {
                    Invoke-WinDebloat7DefenderRemover
                    Read-Host "`nPress Enter to continue..."
                }
                else {
                    Write-WD7Host "Extras module not installed. Download Extras edition for this feature." -Color Warning
                    Start-Sleep -Seconds 2
                }
            }
            "d" { 
                # Case insensitive handler for D
                if ($extrasAvailable) { Invoke-WinDebloat7DefenderRemover; Read-Host "`nPress Enter..." } 
            }
            "A" { 
                if ($extrasAvailable) {
                    Invoke-WinDebloat7Activation
                    Read-Host "`nPress Enter to continue..."
                }
                else {
                    Write-WD7Host "Extras module not installed. Download Extras edition for this feature." -Color Warning
                    Start-Sleep -Seconds 2
                }
            }
            "a" { 
                if ($extrasAvailable) {
                    Invoke-WinDebloat7Activation
                    Read-Host "`nPress Enter to continue..."
                }
                else {
                    Write-WD7Host "Extras module not installed. Download Extras edition for this feature." -Color Warning
                    Start-Sleep -Seconds 2
                }
            }
            "0" {
                Register-WinDebloat7Maintenance
                Read-Host "`nPress Enter to continue..."
            }
            "Q" { exit }
            "q" { exit }
            default { Write-WD7Host "Invalid selection." -Color Warning; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-TweaksMenu {
    while ($true) {
        Show-WD7Header
        Write-WD7Host "Tweaks & Customization" -Color Secondary
        
        Write-WD7Host "  [1] UI Customization (Taskbar, Context Menu)" -Color White
        Write-WD7Host "  [2] Advanced Removal (OneDrive, Edge, Xbox)" -Color White
        Write-WD7Host "  [B] Back" -Color Dark
        
        $sel = Read-Host "`nSelect option"
        
        switch ($sel) {
            "1" { Show-UICustomizationMenu }
            "2" { Show-AdvancedRemovalMenu }
            "B" { return }
            "b" { return }
        }
    }
}

function Show-UICustomizationMenu {
    Show-WD7Header
    Write-WD7Host "UI Customization" -Color Secondary
    
    Write-Host "  [1] Align Taskbar: Left" -ForegroundColor White
    Write-Host "  [2] Align Taskbar: Center" -ForegroundColor White
    Write-Host "  [3] Context Menu: Classic (Win10)" -ForegroundColor White
    Write-Host "  [4] Context Menu: Modern (Win11)" -ForegroundColor White
    Write-Host "  [5] Hide 'Gallery' from Explorer" -ForegroundColor White
    Write-Host "  [6] Hide 'Home' from Explorer" -ForegroundColor White
    Write-Host "  [7] Disable Start Menu 'Recommended'" -ForegroundColor White
    
    $sel = Read-Host "`nSelect tweak to apply (or Enter to cancel)"
    
    switch ($sel) {
        "1" { Set-WinDebloat7TaskbarAlignment -Alignment Left }
        "2" { Set-WinDebloat7TaskbarAlignment -Alignment Center }
        "3" { Set-WinDebloat7ContextMenu -Style Classic }
        "4" { Set-WinDebloat7ContextMenu -Style Modern }
        "5" { Set-WinDebloat7Explorer -HideGallery }
        "6" { Set-WinDebloat7Explorer -HideHome }
        "7" { Set-WinDebloat7StartMenu -DisableRecommended }
    }
    if ($sel) { Read-Host "Press Enter..." }
}

function Show-AdvancedRemovalMenu {
    Show-WD7Header
    Write-WD7Host "Advanced Application Removal" -Color Warning
    
    Write-Host "  [1] Uninstall OneDrive (Complete)" -ForegroundColor White
    Write-Host "  [2] Uninstall Xbox Apps & Services" -ForegroundColor White
    Write-Host "  [3] Uninstall Microsoft Edge (Warning: Experimental)" -ForegroundColor Red
    Write-Host "  [4] Disable Windows 11 AI & Ads (Copilot/Recall)" -ForegroundColor White
    
    $sel = Read-Host "`nSelect removal option (or Enter to cancel)"
    
    switch ($sel) {
        "1" { Uninstall-WinDebloat7OneDrive }
        "2" { Uninstall-WinDebloat7Xbox }
        "3" { Uninstall-WinDebloat7Edge }
        "4" { Disable-WinDebloat7AIandAds }
    }
    if ($sel) { Read-Host "Press Enter..." }
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
            Write-WD7Host "`nDNS Providers:" -Color Secondary
            Write-WD7Host "  [1] Cloudflare (Privacy)" -Color White
            Write-WD7Host "  [2] Google" -Color White
            Write-WD7Host "  [3] Quad9 (Security)" -Color White
            Write-WD7Host "  [4] AdGuard (Ad-Blocking)" -Color White
            Write-WD7Host "  [5] OpenDNS" -Color White
            Write-WD7Host "  [6] Reset to DHCP" -Color White
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
            Write-WD7Host "`nTelemetry Domains to Block ($($domains.Count)):" -Color Secondary
            $domains | ForEach-Object { Write-WD7Host "  $_" -Color Dark }
            Read-Host "`nPress Enter..."
        }
    }
}



function Invoke-WinDebloat7Benchmark {
    Show-WD7Header
    Write-WD7Host "System Benchmarking" -Color Secondary
    Write-Host "This will capture current system metrics and save a report to your Desktop." -ForegroundColor Gray
    Write-Host "For strictly accurate comparison, run this before and after optimization." -ForegroundColor Gray
    
    $run = Read-Host "`nRun Benchmark? [Y/N]"
    if ($run -notmatch '^[Yy]') { return }
    
    Write-Host "`nMeasuring system performance..." -ForegroundColor Cyan
    $metrics = Measure-WinDebloat7System
    
    Write-Host "`nResults:" -ForegroundColor Green
    $metrics | Format-List | Out-String | Write-Host
    
    # Save simple report if standalone
    $reportPath = "$env:USERPROFILE\Desktop\Win-Debloat7_Benchmark_$(Get-Date -Format 'yyyyMMdd-HHmm').txt"
    $metrics | Out-File $reportPath
    Write-Host "Snapshot saved to: $reportPath" -ForegroundColor Gray
    
    Read-Host "`nPress Enter to continue..."
}


function Show-RepairMenu {
    Show-WD7Header
    Write-WD7Host "System Repair Tools" -Color Warning
    
    Write-Host "  [1] Repair Windows Image (SFC + DISM)" -ForegroundColor White
    Write-Host "  [2] Reset Network Stack (IP/DNS/Winsock)" -ForegroundColor White
    Write-Host "  [3] Reset Windows Update Components" -ForegroundColor White
    Write-Host "  [4] Enable PUA Protection (Security)" -ForegroundColor White
    Write-Host "  [5] Disable SMBv1 Protocol (Security)" -ForegroundColor White
    
    $sel = Read-Host "`nSelect repair option (or Enter to cancel)"
    
    switch ($sel) {
        "1" { Repair-WinDebloat7System }
        "2" { Reset-WinDebloat7Network }
        "3" { Reset-WinDebloat7Update }
        "4" { Enable-WinDebloat7PUAProtection }
        "5" { Disable-WinDebloat7SMBv1 }
    }
    if ($sel) { Read-Host "Press Enter..." }
}

function Show-FeaturesMenu {
    Show-WD7Header
    Write-WD7Host "Windows Features Manager" -Color Secondary
    
    Write-Host "  [1] Disable Optional Features (Fax, IIS, WorkFolders)" -ForegroundColor White
    Write-Host "  [2] Enable Optional Features (Revert)" -ForegroundColor White
    Write-Host "  [3] Remove Legacy Capabilities (WordPad, Math, Steps Rec.)" -ForegroundColor White
    
    $sel = Read-Host "`nSelect option (or Enter to cancel)"
    
    switch ($sel) {
        "1" { Set-WinDebloat7OptionalFeatures }
        "2" { Set-WinDebloat7OptionalFeatures -Enable }
        "3" { Remove-WinDebloat7Capabilities }
    }
    if ($sel) { Read-Host "Press Enter..." }
}

Export-ModuleMember -Function Show-MainMenu
