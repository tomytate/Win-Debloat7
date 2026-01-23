<#
.SYNOPSIS
    WPF GUI Controller for Win-Debloat7 (Premium Edition)
    
.DESCRIPTION
    Loads the XAML interface with sidebar navigation, binds event handlers,
    and bridges GUI actions to backend PowerShell modules.
    
.NOTES
    Module: Win-Debloat7.UI.GUI
    Version: 2.0.2 (Fixed version detection, Show Log, telemetry status)
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

# Import Backend Modules
$scriptRoot = $PSScriptRoot
Import-Module "$scriptRoot\..\..\core\Logger.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\core\SystemState.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\core\State.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Bloatware\Bloatware.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Privacy\Privacy.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Performance\Performance.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Performance\Gaming.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Software\Software.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Network\Network.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Privacy\Tasks.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Privacy\Hosts.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Windows11\Version-Detection.psm1" -Force -ErrorAction SilentlyContinue

function Show-WinDebloat7GUI {
    [CmdletBinding()]
    param()
    
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    
    $xamlPath = Join-Path $PSScriptRoot "MainWindow.xaml"
    if (-not (Test-Path $xamlPath)) { 
        Write-Warning "MainWindow.xaml not found at $xamlPath"
        return 
    }
    
    try {
        [xml]$xaml = Get-Content $xamlPath -Raw
        $reader = (New-Object System.Xml.XmlNodeReader $xaml)
        $window = [Windows.Markup.XamlReader]::Load($reader)
        
        # Helper to get controls
        $getCtrl = { param($name) $window.FindName($name) }
        
        # Get controls
        $txtStatus = & $getCtrl "txtStatus"
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # SIDEBAR NAVIGATION
        # ═══════════════════════════════════════════════════════════════════════════════
        $views = @{
            'navDashboard'   = 'viewDashboard'
            'navTweaks'      = 'viewTweaks'
            'navPrivacy'     = 'viewPrivacy'
            'navPerformance' = 'viewPerformance'
            'navSoftware'    = 'viewSoftware'
            'navNetwork'     = 'viewNetwork'
            'navSnapshots'   = 'viewSnapshots'
            'navSettings'    = 'viewSettings'
        }
        
        foreach ($navName in $views.Keys) {
            $nav = & $getCtrl $navName
            if ($nav) {
                # Removed unused viewName variable
                $nav.Add_Checked({
                        param($s, $e)
                        # Hide all views
                        foreach ($vn in @('viewDashboard', 'viewTweaks', 'viewPrivacy', 'viewPerformance', 'viewSoftware', 'viewNetwork', 'viewSnapshots', 'viewSettings')) {
                            $v = $window.FindName($vn)
                            if ($v) { $v.Visibility = 'Collapsed' }
                        }
                        # Show selected view
                        $targetMap = @{
                            'navDashboard' = 'viewDashboard'; 'navTweaks' = 'viewTweaks'; 'navPrivacy' = 'viewPrivacy';
                            'navPerformance' = 'viewPerformance'; 'navSoftware' = 'viewSoftware'; 'navNetwork' = 'viewNetwork';
                            'navSnapshots' = 'viewSnapshots'; 'navSettings' = 'viewSettings'
                        }
                        $targetView = $window.FindName($targetMap[$s.Name])
                        if ($targetView) { $targetView.Visibility = 'Visible' }
                    })
            }
        }
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # POPULATE DASHBOARD - Fixed version detection
        # ═══════════════════════════════════════════════════════════════════════════════
        try {
            # OS Info - Auto-detect version
            $os = Get-CimInstance Win32_OperatingSystem
            $build = [int]$os.BuildNumber
            
            # Detect Windows version based on build number
            $verName = switch ($build) {
                { $_ -ge 26100 } { "24H2"; break }
                { $_ -ge 22631 } { "23H2"; break }
                { $_ -ge 22621 } { "22H2"; break }
                { $_ -ge 22000 } { "21H2"; break }
                { $_ -ge 19045 } { "22H2 (Win10)"; break }
                { $_ -ge 19044 } { "21H2 (Win10)"; break }
                default { "Build $build" }
            }
            
            $osName = if ($build -ge 22000) { "Windows 11" } else { "Windows 10" }
            
            (& $getCtrl "txtOSName").Text = $osName
            (& $getCtrl "txtOSVersion").Text = "$verName (Build $build)"
            
            # RAM
            $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
            (& $getCtrl "txtRAM").Text = $ram.ToString()
            
            # Bloatware count - count known bloatware apps
            $bloatwarePatterns = @(
                '*3DBuilder*', '*BingNews*', '*BingWeather*', '*Clipchamp*', '*Disney*',
                '*Duolingo*', '*Facebook*', '*Flipboard*', '*Spotify*', '*Twitter*',
                '*TikTok*', '*CandyCrush*', '*BubbleWitch*', '*MarchofEmpires*',
                '*Solitaire*', '*OfficeHub*', '*OneConnect*', '*People*', '*Skype*',
                '*Zune*', '*MixedReality*', '*Copilot*', '*LinkedInforWindows*'
            )
            $apps = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            $bloatCount = 0
            foreach ($pattern in $bloatwarePatterns) {
                $bloatCount += ($apps | Where-Object { $_.Name -like $pattern }).Count
            }
            (& $getCtrl "txtBloatwareCount").Text = $bloatCount.ToString()
            
            # Privacy score calculation
            $privacyScore = 100
            
            # Check telemetry
            $telemetryEnabled = $true
            try {
                $telemetryValue = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
                if ($telemetryValue -eq 0) { $telemetryEnabled = $false }
            }
            catch { }
            
            # Check Copilot
            $copilotEnabled = $true
            # Check Copilot (Check both User and Machine policies)
            $copilotEnabled = $true
            try {
                $cpUser = Get-ItemPropertyValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -ErrorAction SilentlyContinue
                $cpMachine = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -ErrorAction SilentlyContinue
                
                # If either policy is set to 1 (Disabled), then it's disabled
                if (($cpUser -eq 1) -or ($cpMachine -eq 1)) { 
                    $copilotEnabled = $false 
                }
            }
            catch { }
            
            # Check Recall
            $recallEnabled = $true
            try {
                $recallValue = Get-ItemPropertyValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -ErrorAction SilentlyContinue
                if ($recallValue -eq 1) { $recallEnabled = $false }
            }
            catch { }

            # Calculate Health Score & status
            if (-not $telemetryEnabled) { $privacyScore += 0 } else { $privacyScore -= 25 }
            if (-not $copilotEnabled) { $privacyScore += 0 } else { $privacyScore -= 15 }
            if (-not $recallEnabled) { $privacyScore += 0 } else { $privacyScore -= 10 }
            $privacyScore = [Math]::Max(0, [Math]::Min(100, $privacyScore))

            # Update score text
            (& $getCtrl "txtPrivacyScore").Text = "$privacyScore%"
            
            # Update health status text/color if it exists (assuming txtSystemStatus exists or we repurpose score label)
            # For now, we stick to updating the score prominently

            
            # Update status indicators
            (& $getCtrl "txtTelemetryStatus").Text = if ($telemetryEnabled) { "Enabled" } else { "Disabled" }
            (& $getCtrl "indicatorTelemetry").Fill = if ($telemetryEnabled) { 
                [System.Windows.Media.Brushes]::Orange 
            }
            else { 
                [System.Windows.Media.Brushes]::LimeGreen 
            }
            
            (& $getCtrl "txtCopilotStatus").Text = if ($copilotEnabled) { "Enabled" } else { "Disabled" }
            (& $getCtrl "indicatorCopilot").Fill = if ($copilotEnabled) { 
                [System.Windows.Media.Brushes]::Orange 
            }
            else { 
                [System.Windows.Media.Brushes]::LimeGreen 
            }
            
            (& $getCtrl "txtRecallStatus").Text = if ($recallEnabled) { "Enabled" } else { "Disabled" }
            (& $getCtrl "indicatorRecall").Fill = if ($recallEnabled) { 
                [System.Windows.Media.Brushes]::Orange 
            }
            else { 
                [System.Windows.Media.Brushes]::LimeGreen 
            }
            
        }
        catch {
            # Ignore dashboard population errors
        }
        
        # Helper to force UI update (fixes freezing feeling)
        $updateGui = {
            [System.Windows.Threading.DispatcherFrame]$frame = [System.Windows.Threading.DispatcherFrame]::new()
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
                [System.Windows.Threading.DispatcherPriority]::Background,
                [Action[System.Windows.Threading.DispatcherFrame]] { param($f) $f.Continue = $false },
                $frame
            ) | Out-Null
            [System.Windows.Threading.Dispatcher]::PushFrame($frame)
        }
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # DASHBOARD BUTTONS
        # ═══════════════════════════════════════════════════════════════════════════════
        (& $getCtrl "btnQuickOptimize").Add_Click({
                $txtStatus.Text = "Creating Safety Snapshot..."
                & $updateGui
                try {
                    # 1. Safety Snapshot
                    New-WinDebloat7Snapshot -Name "Auto-QuickOptimize" -Description "Created before Quick Optimize"
                    
                    # 2. Apply Profile
                    $txtStatus.Text = "Applying Optimization Profile..."
                    & $updateGui
                    
                    $profilePath = Join-Path $scriptRoot "..\..\..\profiles\moderate.yaml"
                    if (Test-Path $profilePath) {
                        $config = Import-WinDebloat7Config -Path $profilePath -SkipDependencyCheck
                        Remove-WinDebloat7Bloatware -Config $config -Confirm:$false
                        Set-WinDebloat7Privacy -Config $config -Confirm:$false
                        Set-WinDebloat7Performance -Config $config -Confirm:$false
                    }
                    $txtStatus.Text = "Quick Optimization Complete!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
            })
        
        (& $getCtrl "btnRemoveBloatware").Add_Click({
                $txtStatus.Text = "Removing Bloatware..."
                & $updateGui
                try {
                    $config = [pscustomobject]@{ bloatware = @{ removal_mode = "Moderate" } }
                    Remove-WinDebloat7Bloatware -Config $config -Confirm:$false
                    $txtStatus.Text = "Bloatware Removed!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
            })
        
        (& $getCtrl "btnInstallEssentials").Add_Click({
                (& $getCtrl "navSoftware").IsChecked = $true
            })
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # TWEAKS BUTTONS
        # ═══════════════════════════════════════════════════════════════════════════════
        (& $getCtrl "btnApplyTweaks").Add_Click({
                $txtStatus.Text = "Applying Tweaks..."
                & $updateGui
                try {
                    $config = [pscustomobject]@{
                        privacy     = [pscustomobject]@{
                            telemetry_level           = "Security"
                            disable_activity_history  = $true
                            disable_location_tracking = $true
                            disable_copilot           = $true
                            disable_recall            = $true
                            disable_advertising_id    = $true
                        }
                        performance = [pscustomobject]@{
                            power_plan              = "HighPerformance"
                            disable_background_apps = $true
                        }
                    }
                    Set-WinDebloat7Privacy -Config $config -Confirm:$false
                    Set-WinDebloat7Performance -Config $config -Confirm:$false
                    $txtStatus.Text = "Tweaks Applied!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
            })
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # PRIVACY BUTTONS
        # ═══════════════════════════════════════════════════════════════════════════════
        (& $getCtrl "btnBlockTelemetry").Add_Click({
                $txtStatus.Text = "Blocking Telemetry..."
                & $updateGui
                try {
                    Add-WinDebloat7HostsBlock -Confirm:$false
                    $txtStatus.Text = "Telemetry Blocked!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
            })
        
        (& $getCtrl "btnDisableTasks").Add_Click({
                $txtStatus.Text = "Disabling Tasks (Safe)..."
                & $updateGui
                try {
                    Disable-WinDebloat7TelemetryTasks -Mode Safe -Confirm:$false
                    $txtStatus.Text = "Safe Tasks Disabled!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
            })
        
        (& $getCtrl "btnAggressiveTasks").Add_Click({
                $txtStatus.Text = "Disabling Tasks (Aggressive)..."
                & $updateGui
                try {
                    Disable-WinDebloat7TelemetryTasks -Mode Aggressive -Confirm:$false
                    $txtStatus.Text = "Aggressive Tasks Disabled!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
            })
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # SOFTWARE TAB
        # ═══════════════════════════════════════════════════════════════════════════════
        try {
            $icSoftware = & $getCtrl "icSoftwareCategories"
            $essentials = Get-WinDebloat7EssentialsList
            $categoriesList = [System.Collections.ArrayList]@()
            
            foreach ($catKey in $essentials.Keys) {
                $appsList = [System.Collections.ArrayList]@()
                foreach ($appDef in $essentials[$catKey].Apps) {
                    $appsList.Add([pscustomobject]@{
                            Name       = $appDef.Name
                            PackageId  = $appDef.Winget
                            IsSelected = $false 
                        }) | Out-Null
                }
                $categoriesList.Add([pscustomobject]@{
                        CategoryName = $essentials[$catKey].DisplayName
                        Apps         = $appsList 
                    }) | Out-Null
            }
            $icSoftware.ItemsSource = $categoriesList
        }
        catch {
            # Software list failed to load
        }
        
        (& $getCtrl "btnInstallSoftware").Add_Click({
                $icSoftware = $window.FindName("icSoftwareCategories")
                $selectedApps = [System.Collections.Generic.List[string]]::new()
                foreach ($cat in $icSoftware.ItemsSource) {
                    foreach ($app in $cat.Apps) {
                        if ($app.IsSelected) { $selectedApps.Add($app.PackageId) }
                    }
                }
            
                if ($selectedApps.Count -eq 0) {
                    $txtStatus.Text = "No apps selected."
                    return
                }
            
                $txtStatus.Text = "Installing $($selectedApps.Count) apps..."
                & $updateGui
                try {
                    Install-WinDebloat7Software -Packages $selectedApps.ToArray() -Quiet
                    $txtStatus.Text = "Installation Complete!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
            })
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # NETWORK TAB
        # ═══════════════════════════════════════════════════════════════════════════════
        (& $getCtrl "btnApplyDNS").Add_Click({
                $cmbDns = $window.FindName("cmbDnsProvider")
                $provider = switch ($cmbDns.SelectedIndex) {
                    0 { "Reset" }
                    1 { "Cloudflare" }
                    2 { "Google" }
                    3 { "Quad9" }
                    4 { "AdGuard" }
                    5 { "OpenDNS" }
                    default { "Reset" }
                }
            
                $txtStatus.Text = "Applying DNS: $provider..."
                & $updateGui
                try {
                    Set-WinDebloat7DNS -Provider $provider
                
                    $chkIPv6 = $window.FindName("chkDisableIPv6")
                    if ($chkIPv6.IsChecked) {
                        Disable-WinDebloat7IPv6 -Confirm:$false
                    }
                    $txtStatus.Text = "DNS Settings Applied!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
            })
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # SNAPSHOTS TAB
        # ═══════════════════════════════════════════════════════════════════════════════
        (& $getCtrl "btnCreateSnapshot").Add_Click({
                $txtStatus.Text = "Creating Snapshot..."
                & $updateGui
                try {
                    New-WinDebloat7Snapshot -Name "GUI-Snapshot" -Description "Created via GUI"
                    $txtStatus.Text = "Snapshot Created!"
                
                    # Refresh list
                    $lstSnapshots = $window.FindName("lstSnapshots")
                    $snaps = Get-WinDebloat7Snapshot
                    $lstSnapshots.Items.Clear()
                    foreach ($snap in $snaps) {
                        $lstSnapshots.Items.Add("$($snap.Timestamp) - $($snap.Name)")
                    }
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
            })
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # SETTINGS TAB - Fixed Show Log
        # ═══════════════════════════════════════════════════════════════════════════════
        (& $getCtrl "btnViewLogs").Add_Click({
                $logPath = "$env:ProgramData\Win-Debloat7\Logs"
            
                # Create logs directory if it doesn't exist
                if (-not (Test-Path $logPath)) {
                    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
                    $txtStatus.Text = "Log directory created: $logPath"
                }
            
                # Try to open the folder
                try {
                    Start-Process "explorer.exe" -ArgumentList $logPath
                    $txtStatus.Text = "Opened log folder"
                }
                catch {
                    $txtStatus.Text = "Error opening logs: $($_.Exception.Message)"
                }
            })
        
        (& $getCtrl "btnCheckUpdates").Add_Click({
                $txtStatus.Text = "Checking for updates..."
                try {
                    Start-Process "https://github.com/tomytate/Win-Debloat7/releases"
                    $txtStatus.Text = "Opened releases page"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
            })
        
        # Show window
        $window.ShowDialog() | Out-Null
    }
    catch {
        Write-Warning "Failed to load GUI: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Show-WinDebloat7GUI
