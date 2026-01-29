<#
.SYNOPSIS
    WPF GUI Controller for Win-Debloat7 (Premium Edition)
    
.DESCRIPTION
    Loads the XAML interface with sidebar navigation, binds event handlers,
    and bridges GUI actions to backend PowerShell modules.
    
.NOTES
    Module: Win-Debloat7.UI.GUI
    Version: 1.2.3
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
Import-Module "$scriptRoot\..\..\modules\Drivers\Drivers.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Tweaks\UI.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Software\Software.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Network\Network.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Privacy\Tasks.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Privacy\Hosts.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Windows11\Version-Detection.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Repair\Repair.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Features\Features.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Security\Security.psm1" -Force -ErrorAction SilentlyContinue

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
        # ═══════════════════════════════════════════════════════════════════════════════
        # SIDEBAR NAVIGATION
        # ═══════════════════════════════════════════════════════════════════════════════
        $views = @{
            'navDashboard'    = 'viewDashboard'
            'navSystemTweaks' = 'viewSystemTweaks'
            'navSoftware'     = 'viewSoftware'
            'navBackups'      = 'viewBackups'
            'navTools'        = 'viewTools'
            'navSettings'     = 'viewSettings'
        }
        
        foreach ($navName in $views.Keys) {
            $nav = & $getCtrl $navName
            if ($nav) {
                $nav.Add_Checked({
                        param($s, $e)
                        # Hide all views
                        foreach ($vn in $views.Values) {
                            $v = $window.FindName($vn)
                            if ($v) { $v.Visibility = 'Collapsed' }
                        }
                        # Show selected view
                        $targetViewName = $views[$s.Name]
                        $targetView = $window.FindName($targetViewName)
                        if ($targetView) { $targetView.Visibility = 'Visible' }
                    })
            }
        }
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # POPULATE DASHBOARD - Fixed version detection and counting
        # ═══════════════════════════════════════════════════════════════════════════════
        
        # Helper to force UI update (fixes freezing feeling) and run safely
        $updateGui = {
            [System.Windows.Threading.DispatcherFrame]$frame = [System.Windows.Threading.DispatcherFrame]::new()
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
                [System.Windows.Threading.DispatcherPriority]::Background,
                [Action[System.Windows.Threading.DispatcherFrame]] { param($f) $f.Continue = $false },
                $frame
            ) | Out-Null
            [System.Windows.Threading.Dispatcher]::PushFrame($frame)
        }

        try {
            # OS Info - Robust Version Detection
            $os = Get-CimInstance Win32_OperatingSystem
            $build = [int]$os.BuildNumber
            
            # Detect Windows version based on build number
            $verName = switch ($build) {
                { $_ -ge 26200 } { "25H2"; break }
                { $_ -ge 26100 } { "24H2"; break }
                { $_ -ge 22631 } { "23H2"; break }
                { $_ -ge 22621 } { "22H2"; break }
                { $_ -ge 22000 } { "21H2"; break }
                { $_ -ge 19045 } { "22H2"; break } # Win10
                { $_ -ge 19044 } { "21H2"; break } # Win10
                default { "" }
            }
            
            $osNameStr = $os.Caption -replace "Microsoft\s+", ""
            if ($build -ge 22000 -and $osNameStr -notmatch "11") { $osNameStr = "Windows 11" } # Force 11 labels if CIM is stale
            
            (& $getCtrl "txtOSName").Text = $osNameStr
            (& $getCtrl "txtOSVersion").Text = "Build $build $verName"
            
            # RAM Display (Updated format)
            $connStats = (Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue).Count
            $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
            (& $getCtrl "txtRAM").Text = "$ram GB | $connStats Active Conns"
            
            # Bloatware count - Expanded Patterns
            $bloatwarePatterns = @(
                '*3DBuilder*', '*BingNews*', '*BingWeather*', '*Clipchamp*', '*Disney*',
                '*Duolingo*', '*Facebook*', '*Flipboard*', '*Spotify*', '*Twitter*',
                '*TikTok*', '*CandyCrush*', '*BubbleWitch*', '*MarchofEmpires*',
                '*Solitaire*', '*OfficeHub*', '*OneConnect*', '*People*', '*Skype*',
                '*Zune*', '*MixedReality*', '*Copilot*', '*LinkedIn*', '*Cortana*',
                '*FeedbackHub*', '*GetHelp*', '*Maps*', '*Messaging*', '*YourPhone*'
            )
            $apps = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            $bloatCount = 0
            foreach ($pattern in $bloatwarePatterns) {
                $bloatCount += ($apps | Where-Object { $_.Name -like $pattern }).Count
            }
            (& $getCtrl "txtBloatwareCount").Text = $bloatCount.ToString()
            
            # Privacy score calculation
            $sysState = Get-WinDebloat7SystemState
            
            $privacyScore = 100
            if ($sysState.Telemetry) { $privacyScore -= 25 }
            if ($sysState.Copilot) { $privacyScore -= 15 }
            if ($sysState.Recall) { $privacyScore -= 15 }
            if ($sysState.ActivityHistory) { $privacyScore -= 10 }
            if ($sysState.Location) { $privacyScore -= 10 }
            if ($sysState.AdvertisingId) { $privacyScore -= 10 } # Assuming exists
            
            $privacyScore = [Math]::Max(0, [Math]::Min(100, $privacyScore))

            # Update score text
            (& $getCtrl "txtPrivacyScore").Text = "$privacyScore"
            
            # Update status indicators (Safe / Warning)
            (& $getCtrl "txtTelemetryStatus").Text = if ($sysState.Telemetry) { "Enabled" } else { "Disabled" }
            (& $getCtrl "indicatorTelemetry").Fill = if ($sysState.Telemetry) { [System.Windows.Media.Brushes]::Orange } else { [System.Windows.Media.Brushes]::LimeGreen }
            
            (& $getCtrl "txtCopilotStatus").Text = if ($sysState.Copilot) { "Enabled" } else { "Disabled" }
            (& $getCtrl "indicatorCopilot").Fill = if ($sysState.Copilot) { [System.Windows.Media.Brushes]::Orange } else { [System.Windows.Media.Brushes]::LimeGreen }
            
            (& $getCtrl "txtRecallStatus").Text = if ($sysState.Recall) { "Enabled" } else { "Disabled" }
            (& $getCtrl "indicatorRecall").Fill = if ($sysState.Recall) { [System.Windows.Media.Brushes]::Orange } else { [System.Windows.Media.Brushes]::LimeGreen }
            
        }
        catch {
            Write-Warning "Dashboard Population Error: $($_.Exception.Message)"
        }
        
        # 3.1 Real-time Monitoring Timer
        $timer = [System.Windows.Threading.DispatcherTimer]::new()
        $timer.Interval = [TimeSpan]::FromSeconds(5)
        $timer.Add_Tick({
                try {
                    # Update Connections & Privacy Score (Background Check)
                    $sysState = Get-WinDebloat7SystemState
                
                    # Update RAM & Connections (Using Format requested)
                    $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
                    $conn = (Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue).Count
                    (& $getCtrl "txtRAM").Text = "$ram GB | $conn Active Conns"
                
                    # Re-calculate score/status
                    $pScore = 100
                    if ($sysState.Telemetry) { $pScore -= 25 }
                    if ($sysState.Copilot) { $pScore -= 15 }
                    if ($sysState.Recall) { $pScore -= 15 }
                    
                    (& $getCtrl "txtPrivacyScore").Text = "$pScore"
                
                    (& $getCtrl "txtTelemetryStatus").Text = if ($sysState.Telemetry) { "Enabled" } else { "Disabled" }
                    (& $getCtrl "indicatorTelemetry").Fill = if ($sysState.Telemetry) { [System.Windows.Media.Brushes]::Orange } else { [System.Windows.Media.Brushes]::LimeGreen }
                    
                    (& $getCtrl "txtCopilotStatus").Text = if ($sysState.Copilot) { "Enabled" } else { "Disabled" }
                    (& $getCtrl "indicatorCopilot").Fill = if ($sysState.Copilot) { [System.Windows.Media.Brushes]::Orange } else { [System.Windows.Media.Brushes]::LimeGreen }
                    
                    (& $getCtrl "txtRecallStatus").Text = if ($sysState.Recall) { "Enabled" } else { "Disabled" }
                    (& $getCtrl "indicatorRecall").Fill = if ($sysState.Recall) { [System.Windows.Media.Brushes]::Orange } else { [System.Windows.Media.Brushes]::LimeGreen }
                }
                catch { }
            })
        $timer.Start()
        
        # Stop timer on close
        $window.Add_Closed({ $timer.Stop() })
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # DASHBOARD BUTTONS
        # ═══════════════════════════════════════════════════════════════════════════════
        (& $getCtrl "btnQuickOptimize").Add_Click({
                $txtStatus.Text = "Creating Safety Snapshot..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
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
                finally {
                    [System.Windows.Input.Mouse]::OverrideCursor = $null
                }
            })
        
        (& $getCtrl "btnRemoveBloatware").Add_Click({
                $txtStatus.Text = "Removing Bloatware..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    $config = [pscustomobject]@{ bloatware = @{ removal_mode = "Moderate" } }
                    Remove-WinDebloat7Bloatware -Config $config -Confirm:$false
                    $txtStatus.Text = "Bloatware Removed!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
                finally {
                    [System.Windows.Input.Mouse]::OverrideCursor = $null
                }
            })
        
        (& $getCtrl "btnInstallEssentials").Add_Click({
                (& $getCtrl "navSoftware").IsChecked = $true
            })
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # TWEAKS BUTTONS - GENERAL & PRIVACY
        # ═══════════════════════════════════════════════════════════════════════════════
        (& $getCtrl "btnApplyTweaks").Add_Click({
                $txtStatus.Text = "Applying System Tweaks..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    # 1. Dark Theme
                    $useDark = (& $getCtrl "chkDarkTheme").IsChecked
                    $themeVal = if ($useDark) { 0 } else { 1 }
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value $themeVal -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value $themeVal -Force -ErrorAction SilentlyContinue

                    # 2. Hibernate
                    if ((& $getCtrl "chkHibernate").IsChecked) { powercfg /h on } else { powercfg /h off }

                    # 3. Clipboard History
                    $clipVal = if ((& $getCtrl "chkClipboardHistory").IsChecked) { 1 } else { 0 }
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Clipboard" -Name "EnableClipboardHistory" -Value $clipVal -Force -ErrorAction SilentlyContinue

                    # 4. Activity History & Location (Privacy Module)
                    $disableActivity = -not (& $getCtrl "chkActivityHistory").IsChecked
                    $disableLocation = -not (& $getCtrl "chkLocation").IsChecked
                    $disableCopilot = -not (& $getCtrl "chkCopilot").IsChecked
                    $disableRecall = -not (& $getCtrl "chkRecall").IsChecked
                    
                    $config = [pscustomobject]@{
                        privacy = [pscustomobject]@{
                            disable_activity_history  = $disableActivity
                            disable_location_tracking = $disableLocation
                            disable_copilot           = $disableCopilot
                            disable_recall            = $disableRecall
                        }
                    }
                    Set-WinDebloat7Privacy -Config $config -Confirm:$false

                    # 5. Background Apps (Performance Module)
                    if ((& $getCtrl "chkBackgroundApps").IsChecked) {
                        # Checked = Enabled (Allow Background Apps)
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 0 -Force -ErrorAction SilentlyContinue
                    }
                    else {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Force -ErrorAction SilentlyContinue
                    }
                    
                    # 6. Automatic Updates
                    if ((& $getCtrl "chkWindowsUpdate").IsChecked) {
                        # Enabled
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    }
                    else {
                        # Disabled
                        if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
                            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
                        }
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                    }

                    $txtStatus.Text = "General Tweaks Applied!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
                finally {
                    [System.Windows.Input.Mouse]::OverrideCursor = $null
                }
            })
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # PERFORMANCE BUTTONS
        # ═══════════════════════════════════════════════════════════════════════════════
        $btnApplyPerf = $window.FindName("btnApplyPerformance")
        if ($btnApplyPerf) {
            $btnApplyPerf.Add_Click({
                    $txtStatus.Text = "Applying Performance Settings..."
                    & $updateGui
                    [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                    try {
                        # Power Plan
                        if ((& $getCtrl "radHighPerf").IsChecked) { cmd /c "powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" }
                        elseif ((& $getCtrl "radUltimate").IsChecked) { cmd /c "powercfg /s e9a42b02-d5df-448d-aa00-03f14749eb61" }
                        else { cmd /c "powercfg /s 381b4222-f694-41f0-9685-ff5bb260df2e" } # Balanced

                        # Gaming Tweaks
                        if ((& $getCtrl "chkGamingNetwork").IsChecked) {
                            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -Name "TcpAckFrequency" -Value 1 -Force -ErrorAction SilentlyContinue
                            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -Name "TCPNoDelay" -Value 1 -Force -ErrorAction SilentlyContinue
                        }
                        
                        if ((& $getCtrl "chkGamingInput").IsChecked) {
                            # Disable Mouse Acceleration
                            # This usually requires SPI_SETMOUSE but registry key is often enough for restart
                            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Force -ErrorAction SilentlyContinue
                            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -Force -ErrorAction SilentlyContinue
                            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -Force -ErrorAction SilentlyContinue
                        }
                        
                        if ((& $getCtrl "chkGamingMMCSS").IsChecked) {
                            # System Responsiveness & Priority
                            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Value 8 -Type DWord -Force -ErrorAction SilentlyContinue
                            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Value 6 -Type DWord -Force -ErrorAction SilentlyContinue
                        }
                    
                        if ((& $getCtrl "chkUltimatePlan").IsChecked) {
                            # Duplicate Ultimate Plan attempt
                            cmd /c "powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61" | Out-Null
                        }

                        $txtStatus.Text = "Performance Optimized!"
                    }
                    catch {
                        $txtStatus.Text = "Error: $($_.Exception.Message)"
                    }
                    finally {
                        [System.Windows.Input.Mouse]::OverrideCursor = $null
                    }
                })
        }

        # ═══════════════════════════════════════════════════════════════════════════════
        # PRIVACY BUTTONS
        # ═══════════════════════════════════════════════════════════════════════════════
        (& $getCtrl "btnBlockTelemetry").Add_Click({
                $txtStatus.Text = "Blocking Telemetry..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    Add-WinDebloat7HostsBlock -Confirm:$false
                    $txtStatus.Text = "Telemetry Blocked!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
                finally {
                    [System.Windows.Input.Mouse]::OverrideCursor = $null
                }
            })
        
        (& $getCtrl "btnDisableTasks").Add_Click({
                $txtStatus.Text = "Disabling Tasks (Safe)..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    Disable-WinDebloat7TelemetryTasks -Mode Safe -Confirm:$false
                    $txtStatus.Text = "Safe Tasks Disabled!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
                finally {
                    [System.Windows.Input.Mouse]::OverrideCursor = $null
                }
            })
        
        (& $getCtrl "btnAggressiveTasks").Add_Click({
                $txtStatus.Text = "Disabling Tasks (Aggressive)..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    Disable-WinDebloat7TelemetryTasks -Mode Aggressive -Confirm:$false
                    $txtStatus.Text = "Aggressive Tasks Disabled!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
                finally {
                    [System.Windows.Input.Mouse]::OverrideCursor = $null
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
        
        # Select/Deselect All
        $btnSelectAll = $window.FindName("btnSelectAllApps")
        if ($btnSelectAll) {
            $btnSelectAll.Add_Click({
                    foreach ($cat in $icSoftware.ItemsSource) {
                        foreach ($app in $cat.Apps) { $app.IsSelected = $true }
                    }
                    # Force refresh hack
                    $icSoftware.ItemsSource = $null
                    $icSoftware.ItemsSource = $categoriesList
                })
        }
        
        $btnDeselectAll = $window.FindName("btnDeselectAllApps")
        if ($btnDeselectAll) {
            $btnDeselectAll.Add_Click({
                    foreach ($cat in $icSoftware.ItemsSource) {
                        foreach ($app in $cat.Apps) { $app.IsSelected = $false }
                    }
                    $icSoftware.ItemsSource = $null
                    $icSoftware.ItemsSource = $categoriesList
                })
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
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    Install-WinDebloat7Software -Packages $selectedApps.ToArray() -Quiet
                    $txtStatus.Text = "Installation Complete!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
                finally {
                    [System.Windows.Input.Mouse]::OverrideCursor = $null
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
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
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
                finally {
                    [System.Windows.Input.Mouse]::OverrideCursor = $null
                }
            })
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # SNAPSHOTS TAB
        # ═══════════════════════════════════════════════════════════════════════════════
        (& $getCtrl "btnCreateSnapshot").Add_Click({
                $txtStatus.Text = "Creating Snapshot..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    New-WinDebloat7Snapshot -Name "GUI-Snapshot" -Description "Created via GUI"
                    $txtStatus.Text = "Snapshot Created!"
                
                    # Refresh list
                    $lstSnapshots = $window.FindName("lstSnapshots")
                    $snaps = Get-WinDebloat7Snapshot
                    $lstSnapshots.Items.Clear()
                    foreach ($snap in $snaps) {
                        $lstSnapshots.Items.Add("$($snap.Timestamp) - $($snap.Name) [$($snap.Id)]")
                    }
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
                finally {
                    [System.Windows.Input.Mouse]::OverrideCursor = $null
                }
            })
            
        $btnRestore = $window.FindName("btnRestoreSnapshot")
        if ($btnRestore) {
            $btnRestore.Add_Click({
                    $lstSnapshots = $window.FindName("lstSnapshots")
                    if ($lstSnapshots.SelectedItem) {
                        $txtStatus.Text = "Restoring Snapshot..."
                        & $updateGui
                        try {
                            [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                            try {
                                # Extract ID from "Timestamp - Name [ID]" string
                                if ($lstSnapshots.SelectedItem -match '\[(.*?)\]$') {
                                    $snapId = $matches[1]
                                    Restore-WinDebloat7Snapshot -SnapshotId $snapId -Confirm:$false
                                    $txtStatus.Text = "System Restored Successfully!"
                                }
                            }
                            catch {
                                $txtStatus.Text = "Error: $($_.Exception.Message)"
                            }
                            finally {
                                [System.Windows.Input.Mouse]::OverrideCursor = $null
                            }
                        }
                        catch { $txtStatus.Text = "Error: $($_.Exception.Message)" } # This catch handles errors from setting cursor or the inner try/finally block
                    }
                })
        }
        
        # ═══════════════════════════════════════════════════════════════════════════════
        # TOOLS TAB
        # ═══════════════════════════════════════════════════════════════════════════════
        
        # 1. Interface Tweaks
        (& $getCtrl "btnApplyUITweaks").Add_Click({
                $txtStatus.Text = "Applying UI Tweaks..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    # Taskbar
                    $align = if ((& $getCtrl "radTaskbarLeft").IsChecked) { "Left" } else { "Center" }
                    Set-WinDebloat7TaskbarAlignment -Alignment $align -Confirm:$false
                    
                    # Context Menu
                    $ctx = if ((& $getCtrl "radCtxClassic").IsChecked) { "Classic" } else { "Modern" }
                    Set-WinDebloat7ContextMenu -Style $ctx -Confirm:$false
                    
                    # Explorer
                    $hideGallery = (& $getCtrl "chkHideGallery").IsChecked
                    $hideHome = (& $getCtrl "chkHideHome").IsChecked
                    Set-WinDebloat7Explorer -HideGallery:$hideGallery -HideHome:$hideHome -Confirm:$false
                    
                    $txtStatus.Text = "UI Tweaks Applied! Restart Explorer to see changes."
                }
                catch { $txtStatus.Text = "Error: $($_.Exception.Message)" }
                finally { [System.Windows.Input.Mouse]::OverrideCursor = $null }
            })
            
        # 2. Maintenance Tools
        (& $getCtrl "btnUpdateDrivers").Add_Click({
                $txtStatus.Text = "Running System Repair (SFC + DISM)..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -Command Repair-WinDebloat7System -Confirm:$false" -Verb RunAs -Wait
                    $txtStatus.Text = "System Repair Initiated!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
                finally {
                    [System.Windows.Input.Mouse]::OverrideCursor = $null
                }
            })
            
        (& $getCtrl "btnRepairSystem").Add_Click({
                $txtStatus.Text = "Running System Repair (SFC). Please wait..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    Repair-WinDebloat7System -Confirm:$false
                    $txtStatus.Text = "Repair Complete!"
                }
                catch { $txtStatus.Text = "Error: $($_.Exception.Message)" }
                finally { [System.Windows.Input.Mouse]::OverrideCursor = $null }
            })
            
        (& $getCtrl "btnResetNetwork").Add_Click({
                $txtStatus.Text = "Resetting Network Stack..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    Reset-WinDebloat7Network -Confirm:$false
                    $txtStatus.Text = "Network Reset Complete!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
                finally {
                    [System.Windows.Input.Mouse]::OverrideCursor = $null
                }
            })
            
        (& $getCtrl "btnWinUpdateReset").Add_Click({
                $txtStatus.Text = "Resetting Update Components..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    Reset-WinDebloat7Update -Confirm:$false
                    $txtStatus.Text = "Update Components Reset!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
                finally {
                    [System.Windows.Input.Mouse]::OverrideCursor = $null
                }
            })
            
        # 3. Analysis (Benchmark)
        (& $getCtrl "btnRunBenchmark").Add_Click({
                $txtStatus.Text = "Running System Benchmark..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    $metrics = Measure-WinDebloat7System
                    
                    # Save report to desktop
                    $reportPath = "$env:USERPROFILE\Desktop\Win-Debloat7_Benchmark_$(Get-Date -Format 'yyyyMMdd-HHmm').txt"
                    $metrics | Out-File $reportPath
                    
                    $txtStatus.Text = "Benchmark Saved to Desktop!"
                    
                    # Optionally show simpler alert/dialog in future
                    Start-Process "notepad.exe" $reportPath
                }
                catch { $txtStatus.Text = "Error: $($_.Exception.Message)" }
                finally { [System.Windows.Input.Mouse]::OverrideCursor = $null }
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
            
        # Hook up status bar show log button too
        $btnShowLog = $window.FindName("btnShowLog")
        if ($btnShowLog) {
            $btnShowLog.Add_Click({
                    $logPath = "$env:ProgramData\Win-Debloat7\Logs" 
                    if (Test-Path $logPath) { Start-Process "explorer.exe" -ArgumentList $logPath }
                })
        }
        
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
