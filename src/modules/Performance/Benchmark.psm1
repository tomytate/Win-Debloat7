<#
.SYNOPSIS
    Captures current system performance metrics.
    
.NOTES
    Module: Win-Debloat7.Modules.Performance.Benchmark
    Version: 1.2.3
#>
#Requires -Version 7.5

function Measure-WinDebloat7System {
    <#
    .OUTPUTS
        [pscustomobject] Containing RAM, Process count, etc.
    #>
    [CmdletBinding()]
    param()

    $os = Get-CimInstance Win32_OperatingSystem
    $freeRamMB = [math]::Round($os.FreePhysicalMemory / 1KB, 0)
    $totalRamMB = [math]::Round($os.TotalVisibleMemorySize / 1KB, 0)
    $usedRamMB = $totalRamMB - $freeRamMB
    
    $procs = (Get-Process).Count
    $services = (Get-Service -ErrorAction SilentlyContinue | Where-Object Status -eq 'Running').Count
    
    return [pscustomobject]@{
        Timestamp   = Get-Date
        UsedRAM_MB  = $usedRamMB
        FreeRAM_MB  = $freeRamMB
        Processes   = $procs
        Services    = $services
        DiskFree_GB = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
        LastBoot    = $os.LastBootUpTime
    }
}

function Compare-WinDebloat7Benchmarks {
    <#
    .SYNOPSIS
        Compares two benchmark objects and generates a report.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Reference,
        [Parameter(Mandatory)] $Difference,
        [string]$ReportPath = "$env:USERPROFILE\Desktop\Win-Debloat7_Benchmark_Report.md"
    )

    $ramDiff = $Reference.UsedRAM_MB - $Difference.UsedRAM_MB
    $procDiff = $Reference.Processes - $Difference.Processes
    $servDiff = $Reference.Services - $Difference.Services
    $diskDiff = $Difference.DiskFree_GB - $Reference.DiskFree_GB

    # Generate Report
    $sb = [System.Text.StringBuilder]::new()
    $sb.AppendLine("# Win-Debloat7 Optimization Report") | Out-Null
    $sb.AppendLine("Generated on $(Get-Date)") | Out-Null
    $sb.AppendLine("") | Out-Null
    
    $sb.AppendLine("| Metric | Before | After | Improvement |") | Out-Null
    $sb.AppendLine("| :--- | :--- | :--- | :--- |") | Out-Null
    $sb.AppendLine("| **Used RAM** | $($Reference.UsedRAM_MB) MB | $($Difference.UsedRAM_MB) MB | **$($ramDiff) MB** freed |") | Out-Null
    $sb.AppendLine("| **Processes** | $($Reference.Processes) | $($Difference.Processes) | **$($procDiff)** fewer |") | Out-Null
    $sb.AppendLine("| **Running Services** | $($Reference.Services) | $($Difference.Services) | **$($servDiff)** disabled |") | Out-Null
    $sb.AppendLine("| **Free Disk (C:)** | $($Reference.DiskFree_GB) GB | $($Difference.DiskFree_GB) GB | **$($diskDiff) GB** reclaimed |") | Out-Null
    
    $report = $sb.ToString()
    
    try {
        $report | Set-Content -Path $ReportPath -Encoding UTF8
        Write-Log -Message "Benchmark report saved to $ReportPath" -Level Success
    }
    catch {
        Write-Log -Message "Could not save benchmark report: $($_.Exception.Message)" -Level Warning
    }

    return $report
}

Export-ModuleMember -Function Measure-WinDebloat7System, Compare-WinDebloat7Benchmarks
