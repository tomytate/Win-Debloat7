
$ErrorActionPreference = "Continue"

Write-Host "Starting Win-Debloat7 Test Suite" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# 1. Run Core Tests
Write-Host "`n[1/2] Running Core Tests..." -ForegroundColor Yellow
$coreRes = Invoke-Pester -Path "$PSScriptRoot\Core.Tests.ps1" -PassThru -Output Minimal

# Cleanup
Remove-Module Win-Debloat7* -ErrorAction SilentlyContinue
[System.GC]::Collect()

# 2. Run Module Tests 
Write-Host "`n[2/2] Running Module Tests..." -ForegroundColor Yellow
$modRes = Invoke-Pester -Path "$PSScriptRoot\Modules.Tests.ps1" -PassThru -Output Minimal

# 3. Aggregate
$totalPassed = $coreRes.PassedCount + $modRes.PassedCount
$totalFailed = $coreRes.FailedCount + $modRes.FailedCount
$totalCount = $coreRes.TotalCount + $modRes.TotalCount

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "FINAL SUMMARY" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Total Tests: $totalCount"
Write-Host "PASSED:      $totalPassed" -ForegroundColor Green
Write-Host "FAILED:      $totalFailed" -ForegroundColor $(if ($totalFailed -gt 0) { "Red" } else { "Green" })

if ($totalFailed -eq 0) {
    Write-Host "`nSUCCESS: All tests passed." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`nFAILURE: Some tests failed." -ForegroundColor Red
    exit 1
}
