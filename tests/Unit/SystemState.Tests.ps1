$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = "$here/../../src/core/SystemState.psm1"

# Mock Get-RegistryKey since it's used internally
function Get-RegistryKey { param($Path, $Name) return 1 }

Import-Module $sut -Force

Describe "SystemState Module" {
    InModuleScope "SystemState" {
        Context "Get-WinDebloat7SystemState" {
            
            It "Should return a state object with all expected properties" {
                # Mock internal dependency (normally from Utils)
                Mock Get-RegistryKey { return 1 }
                
                # Mock .NET/Cmdlet call
                Mock Get-NetTCPConnection { return @(1, 2, 3) }
                
                $state = Get-WinDebloat7SystemState
                
                $state.Telemetry | Should -Not -BeNullOrEmpty
                $state.Copilot | Should -Not -BeNullOrEmpty
                $state.ActiveConnections | Should -Be 3
            }
        }
    }
}
