$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = "$here/../../src/modules/Tweaks/UI.psm1"

# Mock Core Dependencies
function Write-Log { param($Message, $Level) }
function Set-RegistryKey { param($Path, $Name, $Value, $Type) return $true }

Import-Module $sut -Force

Describe "Tweaks Module" {
    
    InModuleScope "UI" {
    
        Context "Set-WinDebloat7TaskbarAlignment" {
            It "Should set alignment to Left (0)" {
                Mock Set-RegistryKey { return $true } -Verifiable -ParameterFilter { 
                    $Path -eq "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -and 
                    $Name -eq "TaskbarAl" -and 
                    $Value -eq 0 
                }
                
                Set-WinDebloat7TaskbarAlignment -Alignment Left
                Assert-MockCalled Set-RegistryKey
            }
            
            It "Should set alignment to Center (1)" {
                Mock Set-RegistryKey { return $true } -Verifiable -ParameterFilter { 
                    $Value -eq 1 
                }
                Set-WinDebloat7TaskbarAlignment -Alignment Center
                Assert-MockCalled Set-RegistryKey
            }
        }
        
        Context "Set-WinDebloat7StartMenu" {
            It "Should disable recommended section" {
                Mock Set-RegistryKey { return $true } -Verifiable -ParameterFilter {
                    $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -and
                    $Name -eq "HideRecommendedSection" -and
                    $Value -eq 1
                }
                
                Set-WinDebloat7StartMenu -DisableRecommended
                Assert-MockCalled Set-RegistryKey
            }
        }
    }
}
