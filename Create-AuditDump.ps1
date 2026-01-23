$rootPath = "w:\Documents\Win-Debloat-Tools-main"
$outputFile = Join-Path $rootPath "Win-Debloat7-FullSource-Audit.txt"
$headerLine = "=" * 80

# Clean up old file
if (Test-Path $outputFile) { Remove-Item $outputFile -Force }

# Define extensions to include
$extensions = @("*.ps1", "*.psm1", "*.psd1", "*.xaml", "*.yaml", "*.md", "LICENSE")

Write-Host "Gathering files..." -ForegroundColor Cyan

# Get files
$files = Get-ChildItem -Path $rootPath -Recurse -Include $extensions -Exclude ".git" | 
Where-Object { $_.FullName -ne $outputFile -and $_.Name -ne "Create-AuditDump.ps1" }

$totalFiles = $files.Count
$current = 0

foreach ($file in $files) {
    $current++
    $relativePath = $file.FullName.Replace($rootPath + "\", "")
    
    Write-Progress -Activity "Creating Audit Dump" -Status "Adding $relativePath" -PercentComplete (($current / $totalFiles) * 100)
    
    # Write Header
    Add-Content -Path $outputFile -Value "`n$headerLine"
    Add-Content -Path $outputFile -Value "FILE: $relativePath"
    Add-Content -Path $outputFile -Value "$headerLine`n"
    
    # Write Content
    try {
        $content = Get-Content -Path $file.FullName -Raw
        Add-Content -Path $outputFile -Value $content
    }
    catch {
        Add-Content -Path $outputFile -Value "[ERROR READING FILE]"
    }
}

Write-Host "Audit dump created at: $outputFile" -ForegroundColor Green
Write-Host "Total Files: $totalFiles" -ForegroundColor Gray
