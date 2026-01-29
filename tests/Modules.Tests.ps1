
Describe "Modules.Windows11.VersionDetection" {
    BeforeAll {
        $src = "w:\Documents\Win-Debloat7\src"
        Import-Module "$src\core\Logger.psm1" -ErrorAction SilentlyContinue
        Import-Module "$src\core\Registry.psm1" -ErrorAction SilentlyContinue
        Import-Module "$src\modules\Windows11\Version-Detection.psm1" -ErrorAction Stop
    }

    It "Exports Get-WindowsVersionInfo" {
        $cmd = Get-Command "Get-WindowsVersionInfo" -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
    }

    It "Exports Test-Windows11Version" {
        $cmd = Get-Command "Test-Windows11Version" -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
    }
}

Describe "Modules.Bloatware" {
    BeforeAll {
        $src = "w:\Documents\Win-Debloat7\src"
        Import-Module "$src\core\Logger.psm1" -ErrorAction SilentlyContinue
        Import-Module "$src\core\Config.psm1" -ErrorAction SilentlyContinue
        Import-Module "$src\modules\Bloatware\Bloatware.psm1" -ErrorAction Stop
    }

    It "Includes Critical 25H2 Bloatware Apps" {
        $list = Get-WinDebloat7BloatwareList
        $list.Count | Should -BeGreaterThan 0
    }
}

Describe "Modules.Privacy" {
    BeforeAll {
        $src = "w:\Documents\Win-Debloat7\src"
        Import-Module "$src\core\Logger.psm1" -ErrorAction SilentlyContinue
        Import-Module "$src\modules\Privacy\Privacy.psm1" -ErrorAction Stop
    }
    
    It "Exports Centralized AI Function" {
        $cmd = Get-Command "Disable-WinDebloat7AIandAds" -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
    }
}

Describe "Modules.Performance" {
    BeforeAll {
        $src = "w:\Documents\Win-Debloat7\src"
        Import-Module "$src\core\Logger.psm1" -ErrorAction SilentlyContinue
        Import-Module "$src\modules\Performance\Benchmark.psm1" -ErrorAction Stop
    }

    It "Exports Measure-WinDebloat7System" {
        $cmd = Get-Command "Measure-WinDebloat7System" -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
    }
}
