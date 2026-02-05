$repair = "$PSScriptRoot/../../src/modules/Repair/Repair.psm1"
$features = "$PSScriptRoot/../../src/modules/Features/Features.psm1"
$security = "$PSScriptRoot/../../src/modules/Security/Security.psm1"

# Mock Logs
function Write-Log { param($Message, $Level) }

Import-Module $repair -Force
Import-Module $features -Force
Import-Module $security -Force

# Stub missing cmdlets for test environment if needed
if (-not (Get-Command Set-MpPreference -ErrorAction SilentlyContinue)) { function global:Set-MpPreference { } }
if (-not (Get-Command Get-WindowsOptionalFeature -ErrorAction SilentlyContinue)) { function global:Get-WindowsOptionalFeature { } }
if (-not (Get-Command Disable-WindowsOptionalFeature -ErrorAction SilentlyContinue)) { function global:Disable-WindowsOptionalFeature { } }
if (-not (Get-Command Enable-WindowsOptionalFeature -ErrorAction SilentlyContinue)) { function global:Enable-WindowsOptionalFeature { } }

Describe "Gems Master Integration" {
    
    Context "Repair Module" {
        It "Reset-WinDebloat7Network should invoke netsh commands" {
            Mock Start-Process { return $true } -ModuleName Repair
            Reset-WinDebloat7Network -Confirm:$false
            Assert-MockCalled Start-Process -Times 5 -ModuleName Repair
        }
    }
    
    Context "Features Module" {
        It "Set-WinDebloat7OptionalFeatures should disable features by default" {
            # Return an object that has 'State' property equal to 'Enabled' to trigger the Disable logic
            Mock Get-WindowsOptionalFeature { return [PSCustomObject]@{ State = "Enabled"; FeatureName = $FeatureName } } -ModuleName Features
            Mock Disable-WindowsOptionalFeature { } -Verifiable -ModuleName Features
            
            Set-WinDebloat7OptionalFeatures -Features @("FaxServicesClientPackage") -Confirm:$false
            
            Assert-MockCalled Disable-WindowsOptionalFeature -ModuleName Features
        }

        It "Set-WinDebloat7OptionalFeatures -Enable should enable features" {
            Mock Get-WindowsOptionalFeature { return [PSCustomObject]@{ State = "Disabled"; FeatureName = $FeatureName } } -ModuleName Features
            Mock Enable-WindowsOptionalFeature { } -Verifiable -ModuleName Features
            
            Set-WinDebloat7OptionalFeatures -Features @("FaxServicesClientPackage") -Enable -Confirm:$false
            
            Assert-MockCalled Enable-WindowsOptionalFeature -ModuleName Features
        }
    }
    
    Context "Security Module" {
        It "Enable-WinDebloat7PUAProtection should call Set-MpPreference" {
            Mock Get-Command { return $true } -ModuleName Security
            Mock Set-MpPreference { } -Verifiable -ModuleName Security
            
            Enable-WinDebloat7PUAProtection -Confirm:$false
            
            Assert-MockCalled Set-MpPreference -ModuleName Security
        }
    }
}
