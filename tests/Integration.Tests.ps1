
Describe "Integration: Safety Systems" {
    BeforeAll {
        $src = "$PSScriptRoot\..\src"
        Import-Module "$src\core\Logger.psm1" -ErrorAction SilentlyContinue
        Import-Module "$src\core\Registry.psm1" -ErrorAction Stop
        Import-Module "$src\core\State.psm1" -ErrorAction Stop
        
        # Setup Test Environment
        $TestPath = "HKCU:\Software\WinDebloat7_Test"
        if (Test-Path $TestPath) { Remove-Item $TestPath -Force -Recurse }
        New-Item -Path $TestPath -Force | Out-Null
        Set-ItemProperty -Path $TestPath -Name "SafetyCheck" -Value 1
    }

    AfterAll {
        # Cleanup ProgramData Snapshots
        $snapDir = "$env:ProgramData\Win-Debloat7\Snapshots"
        if (Test-Path $snapDir) { Remove-Item "$snapDir\TestSnapshot_*" -Force }
    }

    It "Should create a system snapshot" {
        $snap = New-WinDebloat7Snapshot -Name "TestSnapshot"
        $snap | Should -Not -BeNullOrEmpty
        
        $snapFile = "$env:ProgramData\Win-Debloat7\Snapshots\$($snap.Id)\snapshot.clixml" 
        Test-Path $snapFile | Should -Be $true
    }

    It "Should restore registry state from snapshot (AdvertisingInfo)" {
        $TestPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (-not (Test-Path $TestPath)) { New-Item $TestPath -Force | Out-Null }
        
        # 0. Ensure known state
        Set-ItemProperty -Path $TestPath -Name "Enabled" -Value 0
        
        # 1. Take Snapshot (Captures Enabled=0)
        $snap = New-WinDebloat7Snapshot -Name "PreRestoreParams"
        
        # 2. Modify State (Enabled=1)
        Set-ItemProperty -Path $TestPath -Name "Enabled" -Value 1
        (Get-ItemPropertyValue -Path $TestPath -Name "Enabled") | Should -Be 1
        
        # 3. Restore
        Restore-WinDebloat7Snapshot -SnapshotId $snap.Id -Confirm:$false
        
        # 4. Verify Restoration (Should be 0)
        $val = Get-ItemPropertyValue -Path $TestPath -Name "Enabled"
        $val | Should -Be 0
    }
}
