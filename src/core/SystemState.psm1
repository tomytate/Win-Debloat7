<#
.SYNOPSIS
    System State Inspection Module
    
.DESCRIPTION
    Reads current system configuration to determine the state of various tweaks.
    Used by the GUI to synchronize checkboxes with actual system state.
    
.NOTES
    Module: Win-Debloat7.Core.SystemState
    Version: 1.2.5
#>

#Requires -Version 7.5
#Requires -RunAsAdministrator

using namespace System.Management.Automation

Import-Module "$PSScriptRoot\Registry.psm1" -Force

function Get-WinDebloat7SystemState {
    [CmdletBinding()]
    [OutputType([psobject])]
    param()
    
    $state = [pscustomobject]@{
        # Customization
        DarkTheme         = (Get-RegistryKey "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme") -eq 0
        ActivityHistory   = (Get-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities") -ne 0
        BackgroundApps    = (Get-RegistryKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled") -ne 1
        ClipboardHistory  = (Get-RegistryKey "HKCU:\Software\Microsoft\Clipboard" "EnableClipboardHistory") -eq 1
        Hibernate         = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -ErrorAction SilentlyContinue).HibernateEnabled -eq 1
        
        # Privacy
        Telemetry         = (Get-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry") -ne 0
        Location          = (Get-RegistryKey "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value") -ne "Deny"
        Copilot           = ((Get-RegistryKey "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot") -ne 1) -and ((Get-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot") -ne 1)
        Recall            = ((Get-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis") -ne 1) -or 
        ((Get-Service "AIFabric*" -ErrorAction SilentlyContinue).Status -eq 'Running')
        
        # Performance / Gaming
        GameMode          = (Get-RegistryKey "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode") -ne 0
        GameBar           = (Get-RegistryKey "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled") -ne 0
        
        # Gaming Optimizations
        GamingNetwork     = (Get-RegistryKey "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters" "TCPNoDelay") -eq 1
        GamingInput       = (Get-RegistryKey "HKCU:\Control Panel\Mouse" "MouseSpeed") -eq "0"
        GamingMMCSS       = (Get-RegistryKey "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness") -eq 0
        UltimatePlan      = (powercfg /getactivescheme) -match "e9a42b02-d5df-448d-aa00-03f14749eb61"
        
        # Updates
        WindowsUpdate     = (Get-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoUpdate") -ne 1
        IPv6              = (Get-RegistryKey "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" "DisabledComponents") -ne 255
        
        # Real-time Stats
        ActiveConnections = (Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue).Count
    }
    
    return $state
}

Export-ModuleMember -Function Get-WinDebloat7SystemState
