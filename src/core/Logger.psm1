<#
.SYNOPSIS
    Centralized logging module for Win-Debloat7
    
.DESCRIPTION
    Provides structured logging to console and file with Win-Debloat7 branding colors.
    Includes log rotation and size management (SEC-008 fix).
    
.NOTES
    Module: Win-Debloat7.Core.Logger
    Version: 1.2.0
    
.LINK
    https://learn.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-75
#>

#Requires -Version 7.5

using namespace System.Management.Automation

class LogEntry {
    [datetime]$Timestamp
    [string]$Level
    [string]$Message
    [string]$Component
}

# Define Branding Colors
$Script:LogColors = @{
    Info    = "Gray"
    Success = "Green"
    Warning = "Yellow"
    Error   = "Red"
    Debug   = "DarkGray"
    Header  = "Blue"
}

$Script:LogFile = $null
$Script:MaxLogSizeBytes = 10MB
$Script:MaxLogFiles = 5

<#
.SYNOPSIS
    Initializes the logging system.
    
.PARAMETER Path
    Directory path for log files.
    
.PARAMETER MaxSizeBytes
    Maximum log file size before rotation. Default: 10MB.
    
.PARAMETER MaxFiles
    Maximum number of rotated log files to keep. Default: 5.
#>
function Start-WD7Logging {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Path = "$env:ProgramData\Win-Debloat7\Logs",
        
        [int]$MaxSizeBytes = 10MB,
        
        [int]$MaxFiles = 5
    )
    
    $Script:MaxLogSizeBytes = $MaxSizeBytes
    $Script:MaxLogFiles = $MaxFiles
    
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $Script:LogFile = "$Path\Win-Debloat7-$timestamp.log"
    
    # Clean old logs (SEC-008 fix: Log rotation)
    try {
        $existingLogs = Get-ChildItem -Path $Path -Filter "Win-Debloat7-*.log" -ErrorAction Stop | 
        Sort-Object CreationTime -Descending
        
        if ($existingLogs.Count -gt $Script:MaxLogFiles) {
            $toDelete = $existingLogs | Select-Object -Skip $Script:MaxLogFiles
            $toDelete | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        # Non-fatal - continue without cleanup
        Write-Verbose "Log cleanup skipped: $($_.Exception.Message)"
    }
    
    Write-Log -Message "Logging started: $Script:LogFile" -Level Info
}

<#
.SYNOPSIS
    Writes a log message to console and file.
    
.PARAMETER Message
    The message to log.
    
.PARAMETER Level
    Log level: Info, Success, Warning, Error, Debug.
    
.PARAMETER Component
    Optional component name for categorization.
#>
function Write-Log {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        
        [ValidateSet("Info", "Success", "Warning", "Error", "Debug")]
        [string]$Level = "Info",
        
        [string]$Component
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = $Script:LogColors[$Level]
    
    # Console Output
    $prefix = "[$timestamp] [$Level]"
    if ($Component) { $prefix += " [$Component]" }
    
    Write-Host "$prefix " -NoNewline -ForegroundColor DarkGray
    Write-Host $Message -ForegroundColor $color
    
    # File Output
    if ($Script:LogFile) {
        # Check file size and rotate if needed (SEC-008 fix)
        if (Test-Path $Script:LogFile) {
            $fileInfo = Get-Item $Script:LogFile
            if ($fileInfo.Length -gt $Script:MaxLogSizeBytes) {
                $basePath = Split-Path $Script:LogFile -Parent
                $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                $Script:LogFile = "$basePath\Win-Debloat7-$timestamp.log"
            }
        }
        
        try {
            "$timestamp [$Level] $Message" | Out-File -FilePath $Script:LogFile -Append -Encoding utf8
        }
        catch {
            # Silent fail for log writes - don't disrupt main operation
            Write-Verbose "Log write failed: $($_.Exception.Message)"
        }
    }
}

<#
.SYNOPSIS
    Gets the current log file path.
#>
function Get-WD7LogPath {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    return $Script:LogFile
}

Export-ModuleMember -Function Start-WD7Logging, Write-Log, Get-WD7LogPath
