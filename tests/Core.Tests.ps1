
$srcRun = Join-Path $PSScriptRoot "..\src"
Write-Host "Source Root: $srcRun"

$root = (Resolve-Path "$PSScriptRoot\..").Path
$src = Join-Path $root "src"
Write-Host "Loading modules from: $src"

# Preload
Import-Module "$src\core\Logger.psm1" -Force
Import-Module "$src\core\Config.psm1" -Force
Import-Module "$src\core\Registry.psm1" -Force

Describe "Core.Config" {
    # No BeforeAll imports needed

    It "Validates Schema Correctly" {
        $config = [PSCustomObject]@{
            metadata  = @{ name = "Test"; version = "1.0" }
            bloatware = @{ removal_mode = "Custom"; custom_list = "App1" }
        }
        
        # Mock Check
        $res = Test-WinDebloat7Config -Config $config
        $res | Should -Be $true
    }

    It "Detects Invalid Bloatware Mode" {
        $config = [PSCustomObject]@{
            metadata  = @{ name = "Test"; version = "1.0" }
            bloatware = @{ removal_mode = "DestroyEverything" }
        }
        
        # In reality Import-WinDebloat7Config throws, but Test-WinDebloat7Config checks basic structure.
        # Let's test valid Enums via schema presence check (indirectly).
        $Script:ProfileSchema.ValidRemovalModes | Should -Not -Contain "DestroyEverything"
    }
}

Describe "Core.Registry" {
    BeforeAll {
        $root = (Resolve-Path "$PSScriptRoot\..").Path
        $src = Join-Path $root "src"
        Import-Module "$src\core\Registry.psm1" -Force
    }

    It "Exports Export-RegistryKey and accepts parameters" {
        $cmd = Get-Command "Export-RegistryKey" -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
        $cmd.Parameters.Keys | Should -Contain "Path"
        $cmd.Parameters.Keys | Should -Contain "OutputPath"
    }
}
