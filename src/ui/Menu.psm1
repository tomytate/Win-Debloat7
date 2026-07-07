<#
.SYNOPSIS
    Interactive Menu System for Win-Debloat7
    
.DESCRIPTION
    Provides the TUI for authenticating users and selecting profiles.
    
.NOTES
    Module: Win-Debloat7.UI.Menu
    Version: 1.3.1
#>

#Requires -Version 7.6

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
        
        Show-WD7Separator -Title "MAIN MENU" -Color Primary
        Write-Host ""
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
        Write-WD7Host "  [S] Service Optimizer (Presets)" -Color White
        Write-WD7Host "  [U] Update All Apps" -Color White
        Write-WD7Host "  [R] System Repair Tools" -Color Warning
        Write-WD7Host "  [F] Windows Features Manager" -Color White
        Write-WD7Host "  [T] Third Party Tools" -Color White
        
        # Show Extras options only if module is available
        if ($extrasAvailable) {
            Write-Host ""
            Show-WD7Separator -Title "ADVANCED TOOLS" -Color Warning
            Write-WD7Host "  [D] Defender Remover ⚠️" -Color Warning
            Write-WD7Host "  [A] Windows Activation ⚠️" -Color Warning
        }
        
        Write-WD7Host "  [0] Register Weekly Maintenance" -Color Dark
        Write-WD7Host "  [Q] Quit" -Color Dark
        
        Write-Host ""
        Show-WD7Separator
        $choice = Read-Host "  Enter selection"
        
        # Note: PowerShell 'switch' is case-insensitive AND executes every matching
        # clause, so letter options must appear exactly once.
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
            "S" { Show-ServicesMenu }
            "U" {
                Update-WinDebloat7Software
                Read-Host "`nPress Enter to continue..."
            }
            "R" { Show-RepairMenu }
            "F" { Show-FeaturesMenu }
            "T" { Show-IntegrationsMenu }
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
            "0" {
                Register-WinDebloat7Maintenance
                Read-Host "`nPress Enter to continue..."
            }
            "Q" { exit }
            default { Write-WD7Host "Invalid selection." -Color Warning; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-TweaksMenu {
    while ($true) {
        Show-WD7Header
        Show-WD7Separator -Title "TWEAKS & CUSTOMIZATION" -Color Secondary
        
        Write-WD7Host "  [1] UI Customization (Taskbar, Context Menu, Explorer)" -Color White
        Write-WD7Host "  [2] Advanced Removal (OneDrive, Edge, Xbox)" -Color White
        Write-WD7Host "  [3] Search & Suggestions (Bing, Ads, Tips)" -Color White
        Write-WD7Host "  [4] System QoL (Fast Startup, BitLocker, Updates...)" -Color White
        Write-WD7Host "  [B] Back" -Color Dark

        $sel = Read-Host "`nSelect option"

        switch ($sel) {
            "1" { Show-UICustomizationMenu }
            "2" { Show-AdvancedRemovalMenu }
            "3" { Show-SearchSuggestionsMenu }
            "4" { Show-SystemQoLMenu }
            "B" { return }
        }
    }
}

function Show-UICustomizationMenu {
    Show-WD7Header
    Show-WD7Separator -Title "UI CUSTOMIZATION" -Color Secondary

    Write-Host "  [1] Align Taskbar: Left" -ForegroundColor White
    Write-Host "  [2] Align Taskbar: Center" -ForegroundColor White
    Write-Host "  [3] Context Menu: Classic (Win10)" -ForegroundColor White
    Write-Host "  [4] Context Menu: Modern (Win11)" -ForegroundColor White
    Write-Host "  [5] Hide 'Gallery' from Explorer" -ForegroundColor White
    Write-Host "  [6] Hide 'Home' from Explorer" -ForegroundColor White
    Write-Host "  [7] Disable Start Menu 'Recommended'" -ForegroundColor White
    Write-Host "  [8] Explorer: Show file extensions (security best practice)" -ForegroundColor White
    Write-Host "  [9] Explorer: Show hidden files" -ForegroundColor White
    Write-Host "  [10] Explorer: Open to 'This PC'" -ForegroundColor White
    Write-Host "  [11] Taskbar: Hide search / [12] Search icon only" -ForegroundColor White
    Write-Host "  [13] Taskbar: Hide Task View button" -ForegroundColor White
    Write-Host "  [14] Taskbar: Enable 'End Task' in right-click menu" -ForegroundColor White
    Write-Host "  [15] Taskbar: Click focuses last active window" -ForegroundColor White
    Write-Host "  [16] Taskbar: Disable Widgets / [17] Hide Chat icon" -ForegroundColor White
    Write-Host "  [18] Explorer: Hide OneDrive / [19] 3D Objects / [20] Music" -ForegroundColor White
    Write-Host "  [21] Context menu: remove Share / Give access / Include in library" -ForegroundColor White
    Write-Host "  [22] Disable transparency / [23] Disable Snap Assist" -ForegroundColor White
    Write-Host "  [24] Start: hide 'All Apps' list" -ForegroundColor White
    Write-WD7Host "  [R] Restart Explorer (apply pending UI changes)" -Color Primary

    $sel = Read-Host "`nSelect tweak to apply (or Enter to cancel)"

    switch ($sel) {
        "1" { Set-WinDebloat7TaskbarAlignment -Alignment Left }
        "2" { Set-WinDebloat7TaskbarAlignment -Alignment Center }
        "3" { Set-WinDebloat7ContextMenu -Style Classic }
        "4" { Set-WinDebloat7ContextMenu -Style Modern }
        "5" { Set-WinDebloat7Explorer -HideGallery }
        "6" { Set-WinDebloat7Explorer -HideHome }
        "7" { Set-WinDebloat7StartMenu -DisableRecommended }
        "8" { Set-WinDebloat7Explorer -ShowFileExtensions }
        "9" { Set-WinDebloat7Explorer -ShowHiddenFiles }
        "10" { Set-WinDebloat7Explorer -LaunchTo ThisPC }
        "11" { Set-WinDebloat7TaskbarTweaks -SearchMode Hidden }
        "12" { Set-WinDebloat7TaskbarTweaks -SearchMode Icon }
        "13" { Set-WinDebloat7TaskbarTweaks -HideTaskView }
        "14" { Set-WinDebloat7TaskbarTweaks -EnableEndTask }
        "15" { Set-WinDebloat7TaskbarTweaks -EnableLastActiveClick }
        "16" { Disable-WinDebloat7Widgets }
        "17" { Disable-WinDebloat7ChatTaskbar }
        "18" { Set-WinDebloat7Explorer -HideOneDrive }
        "19" { Set-WinDebloat7Explorer -Hide3DObjects }
        "20" { Set-WinDebloat7Explorer -HideMusic }
        "21" { Set-WinDebloat7ContextMenuItems -HideShare -HideGiveAccessTo -HideIncludeInLibrary }
        "22" { Disable-WinDebloat7Transparency }
        "23" { Disable-WinDebloat7SnapAssist }
        "24" { Disable-WinDebloat7StartAllApps }
        "R" { Restart-WinDebloat7Explorer }
    }
    if ($sel) { Read-Host "Press Enter..." }
}

function Show-SearchSuggestionsMenu {
    Show-WD7Header
    Show-WD7Separator -Title "SEARCH & SUGGESTIONS" -Color Secondary

    Write-Host "  [1] Disable Bing web results & Cortana in Start search" -ForegroundColor White
    Write-Host "  [2] Disable Search Highlights (branded search content)" -ForegroundColor White
    Write-Host "  [3] Disable device search history" -ForegroundColor White
    Write-Host "  [4] Disable ALL Windows suggestions & ads (Start, Settings," -ForegroundColor White
    Write-Host "      lock screen tips, promoted-app installs, nag toasts)" -ForegroundColor White
    Write-Host "  [5] Hide the Settings 'Home' page" -ForegroundColor White
    Write-Host "  [6] Hide Phone Link panel in Start" -ForegroundColor White
    Write-Host "  [A] Apply all of the above" -ForegroundColor Yellow

    $sel = Read-Host "`nSelect tweak to apply (or Enter to cancel)"

    switch ($sel) {
        "1" { Set-WinDebloat7Search -DisableBingSearch }
        "2" { Set-WinDebloat7Search -DisableSearchHighlights }
        "3" { Set-WinDebloat7Search -DisableSearchHistory }
        "4" { Disable-WinDebloat7WindowsSuggestions }
        "5" { Disable-WinDebloat7SettingsHome }
        "6" { Disable-WinDebloat7PhoneLinkStart }
        "A" {
            Set-WinDebloat7Search -DisableBingSearch -DisableSearchHighlights -DisableSearchHistory
            Disable-WinDebloat7WindowsSuggestions
            Disable-WinDebloat7SettingsHome
            Disable-WinDebloat7PhoneLinkStart
        }
    }
    if ($sel) { Read-Host "Press Enter..." }
}

function Show-SystemQoLMenu {
    Show-WD7Header
    Show-WD7Separator -Title "SYSTEM QOL TWEAKS" -Color Secondary

    Write-Host "  [1] Disable Fast Startup (clean full shutdowns)" -ForegroundColor White
    Write-Host "  [2] Prevent automatic BitLocker encryption (24H2+ installs)" -ForegroundColor White
    Write-Host "  [3] Disable Delivery Optimization (P2P update sharing)" -ForegroundColor White
    Write-Host "  [4] Disable Storage Sense (automatic disk cleanup)" -ForegroundColor White
    Write-Host "  [5] Prevent auto-reboot after updates while signed in" -ForegroundColor White
    Write-Host "  [6] Turn off 'Get latest updates as soon as available'" -ForegroundColor White
    Write-Host "  [7] Disable Sticky Keys shortcut (5x Shift pop-up)" -ForegroundColor White
    Write-Host "  [8] Disable drag-to-share tray (24H2+)" -ForegroundColor White
    Write-Host "  [9] Disable Find My Device" -ForegroundColor White
    Write-Host "  [10] Disable Modern Standby networking (battery saver)" -ForegroundColor White

    $sel = Read-Host "`nSelect tweak to apply (or Enter to cancel)"

    switch ($sel) {
        "1" { Disable-WinDebloat7FastStartup }
        "2" { Disable-WinDebloat7AutoBitLocker }
        "3" { Disable-WinDebloat7DeliveryOptimization }
        "4" { Disable-WinDebloat7StorageSense }
        "5" { Set-WinDebloat7UpdateBehavior -NoAutoReboot }
        "6" { Set-WinDebloat7UpdateBehavior -NoEarlyUpdates }
        "7" { Disable-WinDebloat7StickyKeysShortcut }
        "8" { Disable-WinDebloat7ShareDragTray }
        "9" { Disable-WinDebloat7FindMyDevice }
        "10" { Disable-WinDebloat7ModernStandbyNetworking }
    }
    if ($sel) { Read-Host "Press Enter..." }
}

function Show-AdvancedRemovalMenu {
    Show-WD7Header
    Show-WD7Separator -Title "ADVANCED REMOVAL" -Color Warning
    
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


function Show-ServicesMenu {
    Show-WD7Header
    Show-WD7Separator -Title "SERVICE OPTIMIZER" -Color Secondary

    Write-WD7Host "  Preset-based service tuning (config/services.json):" -Color Info
    Write-Host ""
    Write-Host "  [1] Privacy     - Disable telemetry & diagnostic services" -ForegroundColor White
    Write-Host "  [2] Performance - Trim background services (Search, Sensors, Maps)" -ForegroundColor White
    Write-Host "  [3] Security    - Disable risky services (RemoteRegistry, UPnP)" -ForegroundColor White
    Write-Host "  [4] Minimal     - Bare essentials (RetailDemo, Fax, WMP Sharing)" -ForegroundColor White
    Write-Host "  [5] Gaming      - Trim Xbox services (for non-gamers)" -ForegroundColor White
    Write-Host "  [V] View current service status" -ForegroundColor Gray

    $sel = Read-Host "`nSelect option (or Enter to cancel)"

    if ($sel -match '^[Vv]$') {
        Write-WD7Host "`nQuerying services (this may take a moment)..." -Color Info
        Get-WinDebloat7ServiceStatus | Sort-Object Category, Name |
        Format-Table Name, Status, CurrentStartup, RecommendedStartup, Category -AutoSize | Out-Host
        Read-Host "Press Enter..."
        return
    }

    $preset = switch ($sel) {
        "1" { "Privacy" }
        "2" { "Performance" }
        "3" { "Security" }
        "4" { "Minimal" }
        "5" { "Gaming" }
        default { $null }
    }

    if ($preset) {
        $confirm = Read-Host "Apply the '$preset' service preset now? [Y/N]"
        if ($confirm -match '^[Yy]') {
            Set-WinDebloat7Services -Preset $preset -Confirm:$false
        }
        Read-Host "Press Enter..."
    }
}

function Show-ProfileSelection {
    Show-WD7Header
    Show-WD7Separator -Title "SELECT PROFILE" -Color Secondary
    
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

    if ($sel -match '^\d+$' -and $profileMap.ContainsKey([int]$sel)) {
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
        New-WinDebloat7Snapshot -Name "Pre-$($config.metadata.name)" -Description "Before applying profile" -Encrypt | Out-Null

        # 2. Modules
        Remove-WinDebloat7Bloatware -Config $config
        Set-WinDebloat7Privacy -Config $config
        Set-WinDebloat7Performance -Config $config
        Set-WinDebloat7Network -Config $config
        Install-WinDebloat7ProfileSoftware -Config $config

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
    
    Show-WD7Separator -Title "SYSTEM INFORMATION" -Color Secondary
    Write-Host "  OS:       " -NoNewline; Write-WD7Host $ver.ProductName -Color White
    Write-Host "  Version:  " -NoNewline; Write-WD7Host "$($ver.DisplayVersion) ($($ver.FriendlyName))" -Color White
    Write-Host "  Build:    " -NoNewline; Write-WD7Host $ver.BuildNumber -Color White
    Write-Host "  Is Win11: " -NoNewline; Write-WD7Host $ver.IsWindows11 -Color White
    
    Read-Host "`nPress Enter to return..."
}

function Show-SnapshotMenu {
    Show-WD7Header
    Show-WD7Separator -Title "SNAPSHOT MANAGEMENT" -Color Secondary
    
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
        "C" { New-WinDebloat7Snapshot -Name "Manual-User" -Description "Created via Menu" | Out-Null; Start-Sleep -Seconds 1 }
        "R" {
            $id = Read-Host "Enter Snapshot ID to restore"
            if ($id) { Restore-WinDebloat7Snapshot -SnapshotId $id }
            Read-Host "Press Enter..."
        }
    }
}

function Show-NetworkPrivacyMenu {
    Show-WD7Header
    Show-WD7Separator -Title "NETWORK & PRIVACY" -Color Secondary
    
    # Show current status
    $netStatus = Get-WinDebloat7NetworkStatus | Select-Object -First 1
    $hostsStatus = Get-WinDebloat7FirewallStatus
    $tasks = Get-WinDebloat7TelemetryTasks -Mode All
    $enabledTasks = ($tasks | Where-Object { $_.Enabled }).Count
    
    Write-Host "`nCurrent Status:" -ForegroundColor Cyan
    Write-Host "  DNS Provider: $($netStatus.DNSProvider)" -ForegroundColor Gray
    Write-Host "  IPv6 Enabled: $($netStatus.IPv6Enabled)" -ForegroundColor Gray
    Write-Host "  Firewall Blocking: $(if ($hostsStatus.TelemetryBlocked) { 'Active' } else { 'Inactive' })" -ForegroundColor Gray
    Write-Host "  Telemetry Tasks: $enabledTasks enabled" -ForegroundColor Gray
    
    Write-Host "`nOptions:" -ForegroundColor Cyan
    Write-WD7Host "  [1] Change DNS Server" -Color White
    Write-WD7Host "  [2] Disable IPv6" -Color White
    Write-WD7Host "  [3] Block Telemetry Domains (Firewall)" -Color White
    Write-WD7Host "  [4] Disable Telemetry Tasks (Safe)" -Color White
    Write-WD7Host "  [5] Disable Telemetry Tasks (Aggressive)" -Color White
    Write-WD7Host "  [6] View Blocked Domains" -Color White
    Write-WD7Host "  [B] Back" -Color Dark
    
    $sel = Read-Host "`nSelect option"
    
    switch ($sel) {
        "1" {
            Write-Host "`n"
            Show-WD7Separator -Title "DNS PROVIDERS" -Color Secondary
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
            Add-WinDebloat7FirewallBlock
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
            Write-Host "`n"
            Show-WD7Separator -Title "TELEMETRY DOMAINS" -Color Secondary
            $domains | ForEach-Object { Write-WD7Host "  $_" -Color Dark }
            Read-Host "`nPress Enter..."
        }
    }
}



function Invoke-WinDebloat7Benchmark {
    Show-WD7Header
    Show-WD7Separator -Title "BENCHMARKING" -Color Secondary
    Write-WD7Host "This will capture current system metrics and save a report to your Desktop." -Color Gray
    Write-WD7Host "For strictly accurate comparison, run this before and after optimization." -Color Gray
    
    $run = Read-Host "`nRun Benchmark? [Y/N]"
    if ($run -notmatch '^[Yy]') { return }
    
    Write-WD7Host "`nMeasuring system performance..." -Color Cyan
    $metrics = Measure-WinDebloat7System
    
    Write-WD7Host "`nResults:" -Color Green
    $metrics | Format-List | Out-String | Write-Host
    
    # Save simple report if standalone
    $reportPath = "$env:USERPROFILE\Desktop\Win-Debloat7_Benchmark_$(Get-Date -Format 'yyyyMMdd-HHmm').txt"
    $metrics | Out-File $reportPath
    Write-WD7Host "Snapshot saved to: $reportPath" -Color Gray
    
    Read-Host "`nPress Enter to continue..."
}


function Show-RepairMenu {
    Show-WD7Header
    Show-WD7Separator -Title "SYSTEM REPAIR" -Color Warning
    
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
    Show-WD7Separator -Title "WINDOWS FEATURES" -Color Secondary
    
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

function Show-IntegrationsMenu {
    Show-WD7Header
    Show-WD7Separator -Title "THIRD PARTY TOOLS" -Color Warning
    
    Write-Host "  [1] O&O ShutUp10++ (Privacy)" -ForegroundColor White
    Write-Host "  [2] Malwarebytes AdwCleaner (Cleaning)" -ForegroundColor White
    Write-Host "  [3] Snappy Driver Installer Origin (Drivers)" -ForegroundColor White
    
    $sel = Read-Host "`nSelect tool to launch (or Enter to cancel)"
    
    switch ($sel) {
        "1" { Invoke-WinDebloat7ShutUp10 }
        "2" { Invoke-WinDebloat7AdwCleaner }
        "3" { Update-WinDebloat7SDIO }
    }
    if ($sel) { Read-Host "Press Enter..." }
}

Export-ModuleMember -Function Show-MainMenu
