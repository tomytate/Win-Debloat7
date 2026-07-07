<#
.SYNOPSIS
    WPF GUI Controller for Win-Debloat7 (Premium Edition)

.DESCRIPTION
    Loads the XAML interface with sidebar navigation, binds event handlers,
    and bridges GUI actions to backend PowerShell modules.

.NOTES
    Module: Win-Debloat7.UI.GUI
    Version: 1.3.1
#>

#Requires -Version 7.6
#Requires -RunAsAdministrator

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Event parameters required by signature')]


# Import Backend Modules
$scriptRoot = $PSScriptRoot
Import-Module "$scriptRoot\..\..\core\Logger.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\core\SystemState.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\core\State.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Bloatware\Bloatware.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Privacy\Privacy.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Performance\Performance.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Performance\Gaming.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Performance\Tweaks.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Performance\Services.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Drivers\Drivers.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Tweaks\UI.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Tweaks\System.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Software\Software.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Network\Network.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Privacy\Tasks.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptRoot\..\..\modules\Privacy\Firewall.psm1" -Force -ErrorAction SilentlyContinue
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
                        $null = $s; $null = $e # Suppress unused parameter warning
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

        # Total RAM is constant; capture once for the live-usage detail line
        $ramTotalGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0)

        # ── Shared live-stats refresh ────────────────────────────────────────────
        # Both the initial paint and the recurring timer call this exact block, so
        # the RAM formula and privacy-score criteria live in ONE place (previously
        # the scoring was duplicated and inconsistent between the two).
        $refreshLiveStats = {
            try {
                # Live RAM usage from OS free/total counters (KB)
                $osm = Get-CimInstance Win32_OperatingSystem
                $totalMB = $osm.TotalVisibleMemorySize / 1KB
                $freeMB = $osm.FreePhysicalMemory / 1KB
                $usedGB = [math]::Round(($totalMB - $freeMB) / 1KB, 1)
                $usedPct = if ($totalMB -gt 0) { [math]::Round((($totalMB - $freeMB) / $totalMB) * 100) } else { 0 }
                $conns = (Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue).Count
                (& $getCtrl "txtRAM").Text = "$usedPct"
                (& $getCtrl "txtRAMDetail").Text = "$usedGB / $ramTotalGB GB · $conns conns"
                (& $getCtrl "txtRAM").Foreground =
                if ($usedPct -ge 85) { [System.Windows.Media.Brushes]::OrangeRed }
                elseif ($usedPct -ge 70) { [System.Windows.Media.Brushes]::Gold }
                else { [System.Windows.Media.Brushes]::White }

                # Privacy score via the single scoring function (criteria sum to 100)
                $sysState = Get-WinDebloat7SystemState
                $ps = Get-WinDebloat7PrivacyScore -State $sysState
                $scoreBrush =
                if ($ps.Score -ge 75) { [System.Windows.Media.Brushes]::LimeGreen }
                elseif ($ps.Score -ge 40) { [System.Windows.Media.Brushes]::Gold }
                else { [System.Windows.Media.Brushes]::OrangeRed }
                (& $getCtrl "txtPrivacyScore").Text = "$($ps.Score)"
                (& $getCtrl "txtPrivacyScore").Foreground = $scoreBrush
                (& $getCtrl "txtPrivacyGrade").Text = "$($ps.Grade) · $($ps.Rating)"
                (& $getCtrl "txtPrivacyGrade").Foreground = $scoreBrush

                # Tooltip lists exactly which risks are costing points
                $active = @($ps.Breakdown | Where-Object { $_.Active })
                $tip = if ($active.Count -eq 0) { "Fully hardened - no active privacy risks." }
                else { "Points lost (hover breakdown):`n" + (($active | ForEach-Object { "  - $($_.Name):  -$($_.Weight)" }) -join "`n") }
                (& $getCtrl "txtPrivacyScore").ToolTip = $tip
                (& $getCtrl "txtPrivacyGrade").ToolTip = $tip
                (& $getCtrl "txtPrivacyLabel").ToolTip = $tip

                # Status indicators (Telemetry / Copilot / Recall)
                (& $getCtrl "txtTelemetryStatus").Text = if ($sysState.Telemetry) { "Enabled" } else { "Disabled" }
                (& $getCtrl "indicatorTelemetry").Fill = if ($sysState.Telemetry) { [System.Windows.Media.Brushes]::Orange } else { [System.Windows.Media.Brushes]::LimeGreen }
                (& $getCtrl "txtCopilotStatus").Text = if ($sysState.Copilot) { "Enabled" } else { "Disabled" }
                (& $getCtrl "indicatorCopilot").Fill = if ($sysState.Copilot) { [System.Windows.Media.Brushes]::Orange } else { [System.Windows.Media.Brushes]::LimeGreen }
                (& $getCtrl "txtRecallStatus").Text = if ($sysState.Recall) { "Enabled" } else { "Disabled" }
                (& $getCtrl "indicatorRecall").Fill = if ($sysState.Recall) { [System.Windows.Media.Brushes]::Orange } else { [System.Windows.Media.Brushes]::LimeGreen }
            }
            catch {
                Write-Verbose "Live stats refresh failed: $($_.Exception.Message)"
            }
        }

        try {
            # OS info via the shared version-detection module (single source of
            # truth; the module now returns the correct feature-update label and
            # edition, and no longer collapses every Win11 build to "21H2").
            $ver = Get-WindowsVersionInfo -Force
            (& $getCtrl "txtOSName").Text = $ver.FullName
            $ubr = if ($ver.Ubr) { ".$($ver.Ubr)" } else { "" }
            (& $getCtrl "txtOSVersion").Text = "$($ver.DisplayVersion) · Build $($ver.BuildNumber)$ubr"

            # Bloatware count - Async Implementation (Optimization)
            # Get-AppxPackage is slow, so we load a placeholder and update it in the background
            (& $getCtrl "txtBloatwareCount").Text = "..."

            $bloatwarePatterns = @(
                '*3DBuilder*', '*BingNews*', '*BingWeather*', '*Clipchamp*', '*Disney*',
                '*Duolingo*', '*Facebook*', '*Flipboard*', '*Spotify*', '*Twitter*',
                '*TikTok*', '*CandyCrush*', '*BubbleWitch*', '*MarchofEmpires*',
                '*Solitaire*', '*OfficeHub*', '*OneConnect*', '*People*', '*Skype*',
                '*Zune*', '*MixedReality*', '*Copilot*', '*LinkedIn*', '*Cortana*',
                '*FeedbackHub*', '*GetHelp*', '*Maps*', '*Messaging*', '*YourPhone*'
            )

            # Start background runspace
            $rs = [runspacefactory]::CreateRunspace()
            $rs.Open()
            $psStr = {
                param($patterns)
                try {
                    Import-Module Appx -ErrorAction SilentlyContinue
                    $apps = @(Get-AppxPackage -AllUsers -ErrorAction Stop)
                    $count = 0
                    foreach ($p in $patterns) {
                        # PS 7.6: PSWhere() intrinsic skips the pipeline (faster on large collections)
                        $count += $apps.PSWhere({ $_.Name -like $p }).Count
                    }
                    return $count
                }
                catch {
                    return -1 # Error indicator
                }
            }
            $ps = [powershell]::Create().AddScript($psStr).AddArgument($bloatwarePatterns)
            $ps.Runspace = $rs
            $handle = $ps.BeginInvoke()

            # Non-blocking check for completion using the Dispatcher
            $checkTimer = [System.Windows.Threading.DispatcherTimer]::new()
            $checkTimer.Interval = [TimeSpan]::FromMilliseconds(100)
            $checkTimer.Add_Tick({
                    if ($handle.IsCompleted) {
                        $checkTimer.Stop()
                        try {
                            $results = $ps.EndInvoke($handle)
                            $ps.Dispose()
                            $rs.Dispose()
                            
                            $finalCount = if ($results) { $results[-1] } else { 0 }
                            (& $getCtrl "txtBloatwareCount").Text = "$finalCount"
                        }
                        catch {
                            (& $getCtrl "txtBloatwareCount").Text = "?"
                        }
                    }
                })
            $checkTimer.Start()

            # Privacy score calculation
            $sysState = Get-WinDebloat7SystemState

            # Sync tweak toggles with the live system state so "Apply" is a no-op
            # unless the user actually changes something (prevents e.g. Windows
            # Update being disabled just because a checkbox defaulted to unchecked)
            $checkboxStateMap = @{
                chkDarkTheme        = $sysState.DarkTheme
                chkActivityHistory  = $sysState.ActivityHistory
                chkBackgroundApps   = $sysState.BackgroundApps
                chkClipboardHistory = $sysState.ClipboardHistory
                chkHibernate        = $sysState.Hibernate
                chkLocation         = $sysState.Location
                chkCopilot          = $sysState.Copilot
                chkRecall           = $sysState.Recall
                chkWindowsUpdate    = $sysState.WindowsUpdate
                chkTelemetry        = $sysState.Telemetry
                chkGamingNetwork    = $sysState.GamingNetwork
                chkGamingInput      = $sysState.GamingInput
                chkGamingMMCSS      = $sysState.GamingMMCSS
                chkUltimatePlan     = $sysState.UltimatePlan
            }
            foreach ($ctrlName in $checkboxStateMap.Keys) {
                $ctrl = & $getCtrl $ctrlName
                if ($ctrl) { $ctrl.IsChecked = [bool]$checkboxStateMap[$ctrlName] }
            }
            if ($sysState.UltimatePlan) {
                $radUlt = & $getCtrl "radUltimate"
                if ($radUlt) { $radUlt.IsChecked = $true }
            }

            # Paint the live stats (RAM, privacy score, indicators) via the shared block
            & $refreshLiveStats
        }
        catch {
            Write-Warning "Dashboard Population Error: $($_.Exception.Message)"
        }

        # 3.1 Real-time Monitoring Timer — reuses the shared live-stats block
        $timer = [System.Windows.Threading.DispatcherTimer]::new()
        $timer.Interval = [TimeSpan]::FromSeconds(5)
        $timer.Add_Tick({ & $refreshLiveStats })
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
                    New-WinDebloat7Snapshot -Name "Auto-QuickOptimize" -Description "Created before Quick Optimize" -Encrypt | Out-Null

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
                    if ((& $getCtrl "chkHibernate").IsChecked) { Start-Process -FilePath "powercfg.exe" -ArgumentList "/h", "on" -Wait -NoNewWindow } else { Start-Process -FilePath "powercfg.exe" -ArgumentList "/h", "off" -Wait -NoNewWindow }

                    # 3. Clipboard History
                    $clipVal = if ((& $getCtrl "chkClipboardHistory").IsChecked) { 1 } else { 0 }
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Clipboard" -Name "EnableClipboardHistory" -Value $clipVal -Force -ErrorAction SilentlyContinue

                    # 4. Activity History, Location & Telemetry (Privacy Module)
                    $disableActivity = -not (& $getCtrl "chkActivityHistory").IsChecked
                    $disableLocation = -not (& $getCtrl "chkLocation").IsChecked
                    $disableCopilot = -not (& $getCtrl "chkCopilot").IsChecked
                    $disableRecall = -not (& $getCtrl "chkRecall").IsChecked
                    # Unchecked telemetry toggle = restrict to Security level; checked = leave as-is
                    $telemetryLevel = if ((& $getCtrl "chkTelemetry").IsChecked) { $null } else { "Security" }

                    $config = [pscustomobject]@{
                        privacy = [pscustomobject]@{
                            telemetry_level           = $telemetryLevel
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
                        if ((& $getCtrl "radHighPerf").IsChecked) {
                            Start-Process -FilePath "powercfg.exe" -ArgumentList "/s", "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" -Wait -NoNewWindow
                            Write-Log -Message "Set power plan to High Performance" -Level Info
                        }
                        elseif ((& $getCtrl "radUltimate").IsChecked) {
                            # The hidden Ultimate scheme must be duplicated before activation
                            Enable-WinDebloat7UltimatePower
                        }
                        else {
                            Start-Process -FilePath "powercfg.exe" -ArgumentList "/s", "381b4222-f694-41f0-9685-ff5bb260df2e" -Wait -NoNewWindow
                            Write-Log -Message "Set power plan to Balanced" -Level Info
                        }

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
                            Enable-WinDebloat7UltimatePower
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

        # Service Optimizer preset (config/services.json)
        $btnApplyServices = $window.FindName("btnApplyServices")
        if ($btnApplyServices) {
            $btnApplyServices.Add_Click({
                    $presetItem = ($window.FindName("cmbServicePreset")).SelectedItem
                    if (-not $presetItem) {
                        $txtStatus.Text = "Select a service preset first."
                        return
                    }
                    $preset = [string]$presetItem.Content

                    $txtStatus.Text = "Applying '$preset' service preset..."
                    & $updateGui
                    [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                    try {
                        Set-WinDebloat7Services -Preset $preset -Confirm:$false
                        $txtStatus.Text = "'$preset' service preset applied!"
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
                    Add-WinDebloat7FirewallBlock -Confirm:$false
                    $txtStatus.Text = "Telemetry Blocked!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
                finally {
                    [System.Windows.Input.Mouse]::OverrideCursor = $null
                }
            })

        # System QoL tab — apply the checked one-way tweaks
        $btnApplyQoL = $window.FindName("btnApplyQoL")
        if ($btnApplyQoL) {
            $btnApplyQoL.Add_Click({
                    $txtStatus.Text = "Applying System QoL tweaks..."
                    & $updateGui
                    [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                    $applied = 0
                    try {
                        # Each checkbox maps to a one-way tweak; only checked ones run
                        if ((& $getCtrl "chkQolFastStartup").IsChecked) { Disable-WinDebloat7FastStartup -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolBitlocker").IsChecked) { Disable-WinDebloat7AutoBitLocker -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolDeliveryOpt").IsChecked) { Disable-WinDebloat7DeliveryOptimization -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolStorageSense").IsChecked) { Disable-WinDebloat7StorageSense -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolNoAutoReboot").IsChecked) { Set-WinDebloat7UpdateBehavior -NoAutoReboot -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolNoEarlyUpdates").IsChecked) { Set-WinDebloat7UpdateBehavior -NoEarlyUpdates -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolModernStandby").IsChecked) { Disable-WinDebloat7ModernStandbyNetworking -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolFindMyDevice").IsChecked) { Disable-WinDebloat7FindMyDevice -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolStickyKeys").IsChecked) { Disable-WinDebloat7StickyKeysShortcut -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolWidgets").IsChecked) { Disable-WinDebloat7Widgets -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolChat").IsChecked) { Disable-WinDebloat7ChatTaskbar -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolTransparency").IsChecked) { Disable-WinDebloat7Transparency -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolSnapAssist").IsChecked) { Disable-WinDebloat7SnapAssist -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolStartAllApps").IsChecked) { Disable-WinDebloat7StartAllApps -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolFileExt").IsChecked) { Set-WinDebloat7Explorer -ShowFileExtensions -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolHiddenFiles").IsChecked) { Set-WinDebloat7Explorer -ShowHiddenFiles -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolHideOneDrive").IsChecked) { Set-WinDebloat7Explorer -HideOneDrive -Confirm:$false; $applied++ }
                        if ((& $getCtrl "chkQolContextClean").IsChecked) { Set-WinDebloat7ContextMenuItems -HideShare -HideGiveAccessTo -HideIncludeInLibrary -Confirm:$false; $applied++ }

                        $txtStatus.Text = if ($applied -gt 0) { "$applied System QoL tweak(s) applied! Restart Explorer to see UI changes." } else { "No QoL tweaks selected." }
                    }
                    catch {
                        $txtStatus.Text = "Error: $($_.Exception.Message)"
                    }
                    finally {
                        [System.Windows.Input.Mouse]::OverrideCursor = $null
                    }
                })
        }

        (& $getCtrl "btnDebloatSearch").Add_Click({
                $txtStatus.Text = "Debloating Windows Search..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    Set-WinDebloat7Search -DisableBingSearch -DisableSearchHighlights -DisableSearchHistory -Confirm:$false
                    $txtStatus.Text = "Search debloated (Bing results, highlights, and history disabled)!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
                finally {
                    [System.Windows.Input.Mouse]::OverrideCursor = $null
                }
            })

        (& $getCtrl "btnDisableSuggestions").Add_Click({
                $txtStatus.Text = "Disabling Windows suggestions and ads..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    Disable-WinDebloat7WindowsSuggestions -Confirm:$false
                    Disable-WinDebloat7SettingsHome -Confirm:$false
                    $txtStatus.Text = "Suggestions and ad surfaces disabled!"
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

            # Sorted for a stable category order (hashtable key order is not guaranteed);
            # carry both provider IDs so Chocolatey-only apps install via fallback
            foreach ($catKey in ($essentials.Keys | Sort-Object)) {
                $appsList = [System.Collections.ArrayList]@()
                foreach ($appDef in $essentials[$catKey].Apps) {
                    $appsList.Add([pscustomobject]@{
                            Name       = $appDef.Name
                            PackageId  = $appDef.Winget
                            ChocoId    = $appDef.Choco
                            MsstoreId  = $appDef.Msstore
                            NpmId      = $appDef.Npm
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
            Write-Warning "Software list failed to load: $($_.Exception.Message)"
        }

        # Live search filter: rebuilds the visible list; selections persist because
        # filtered views reuse the same underlying app objects
        $txtSearch = $window.FindName("txtSoftwareSearch")
        if ($txtSearch) {
            $txtSearch.Add_TextChanged({
                    $filter = $txtSearch.Text
                    if ([string]::IsNullOrWhiteSpace($filter)) {
                        $icSoftware.ItemsSource = $categoriesList
                        return
                    }
                    $filtered = [System.Collections.ArrayList]@()
                    foreach ($cat in $categoriesList) {
                        $matchApps = @($cat.Apps | Where-Object { $_.Name -like "*$filter*" })
                        if ($matchApps.Count -gt 0) {
                            $filtered.Add([pscustomobject]@{
                                    CategoryName = $cat.CategoryName
                                    Apps         = $matchApps
                                }) | Out-Null
                        }
                    }
                    $icSoftware.ItemsSource = $filtered
                })
        }

        # Select/Deselect All
        $btnSelectAll = $window.FindName("btnSelectAllApps")
        if ($btnSelectAll) {
            $btnSelectAll.Add_Click({
                    # Operates on the current view (respects an active search filter)
                    $currentView = $icSoftware.ItemsSource
                    foreach ($cat in $currentView) {
                        foreach ($app in $cat.Apps) { $app.IsSelected = $true }
                    }
                    # Force refresh while preserving the filtered view
                    $icSoftware.ItemsSource = $null
                    $icSoftware.ItemsSource = $currentView
                })
        }

        $btnDeselectAll = $window.FindName("btnDeselectAllApps")
        if ($btnDeselectAll) {
            $btnDeselectAll.Add_Click({
                    $currentView = $icSoftware.ItemsSource
                    foreach ($cat in $currentView) {
                        foreach ($app in $cat.Apps) { $app.IsSelected = $false }
                    }
                    $icSoftware.ItemsSource = $null
                    $icSoftware.ItemsSource = $currentView
                })
        }

        (& $getCtrl "btnInstallSoftware").Add_Click({
                # Pass full app objects (-Apps) so winget/Chocolatey fallback works,
                # including apps that only exist on one package manager.
                # Iterate the MASTER list so selections hidden by an active search
                # filter are still included.
                $selectedApps = @()
                foreach ($cat in $categoriesList) {
                    foreach ($app in $cat.Apps) {
                        if ($app.IsSelected) {
                            $selectedApps += @{ Name = $app.Name; Winget = $app.PackageId; Choco = $app.ChocoId; Msstore = $app.MsstoreId; Npm = $app.NpmId }
                        }
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
                    $result = Install-WinDebloat7Software -Apps $selectedApps -Quiet
                    $txtStatus.Text = "Installation Complete! $($result.Successful) installed, $($result.Failed) failed."
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

        # Populate the snapshot list on startup (previously empty until a new one was created)
        try {
            $lstSnapshotsInit = & $getCtrl "lstSnapshots"
            foreach ($snap in (Get-WinDebloat7Snapshot)) {
                $lstSnapshotsInit.Items.Add("$($snap.Timestamp) - $($snap.Name) [$($snap.Id)]") | Out-Null
            }
        }
        catch {
            Write-Verbose "Could not populate snapshot list: $($_.Exception.Message)"
        }

        (& $getCtrl "btnCreateSnapshot").Add_Click({
                $txtStatus.Text = "Creating Snapshot..."
                & $updateGui
                [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
                try {
                    New-WinDebloat7Snapshot -Name "GUI-Snapshot" -Description "Created via GUI" -Encrypt | Out-Null
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
        (& $getCtrl "btnRestartExplorer").Add_Click({
                $txtStatus.Text = "Restarting Explorer..."
                & $updateGui
                try {
                    Restart-WinDebloat7Explorer -Confirm:$false
                    $txtStatus.Text = "Explorer restarted."
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
                }
            })

        (& $getCtrl "btnUpdateDrivers").Add_Click({
                $txtStatus.Text = "Launching Driver Update Center..."
                & $updateGui
                try {
                    # The spawned pwsh has no modules loaded - import the manifest first
                    $manifestPath = (Resolve-Path (Join-Path $scriptRoot "..\..\..\Win-Debloat7.psd1")).Path
                    $driverCmd = "Import-Module '$manifestPath' -Force; Update-WinDebloat7Drivers -Method Interactive"
                    Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-NoExit", "-Command", $driverCmd -Verb RunAs
                    $txtStatus.Text = "Driver Update Center Launched!"
                }
                catch {
                    $txtStatus.Text = "Error: $($_.Exception.Message)"
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
