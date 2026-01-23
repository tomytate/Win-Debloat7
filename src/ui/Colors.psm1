<#
.SYNOPSIS
    Premium color scheme and branding for Win-Debloat7 TUI
    
.DESCRIPTION
    Defines the "Neon Cyber" color palette with premium aesthetics.
    
.NOTES
    Module: Win-Debloat7.UI.Colors
    Version: 2.0.0 (Premium Edition)
#>

#Requires -Version 7.5

# Premium Color Scheme - Neon Cyber Dark
$Script:WD7Colors = @{
    # Primary Palette
    Primary    = "Cyan"           # #00D4FF - Main accent
    Secondary  = "Magenta"        # #7B2CBF - Secondary accent
    
    # Status Colors
    Success    = "Green"          # #00FF88 - Neon Green
    Warning    = "Yellow"         # #FFB800 - Amber
    Error      = "Red"            # #FF3366 - Coral Red
    
    # Text Colors
    Info       = "Gray"           # #A0A0B0 - Secondary text
    Dark       = "DarkGray"       # #606070 - Muted text
    White      = "White"          # #FFFFFF - Primary text
    
    # Background (Console limitation - display only)
    Background = "Black"          # #0D0D0D - True dark
}

# Premium ASCII Art Header
$Script:WD7Header = @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║   ██╗    ██╗██╗███╗   ██╗      ██████╗ ███████╗██████╗ ██╗      ██████╗ ████ ║
║   ██║    ██║██║████╗  ██║      ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╔╝║
║   ██║ █╗ ██║██║██╔██╗ ██║█████╗██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ██║ ║
║   ██║███╗██║██║██║╚██╗██║╚════╝██║  ██║██╔══╝  ██╔══██╗██║     ██║   ██║ ██║ ║
║   ╚███╔███╔╝██║██║ ╚████║      ██████╔╝███████╗██████╔╝███████╗╚██████╔╝ ██║ ║
║    ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝      ╚═════╝ ╚══════╝╚═════╝ ╚══════╝ ╚═════╝  ╚═╝ ║
║                                                                               ║
║                     Ultimate System Optimizer v1.1.0                          ║
║                  PowerShell 7.5+ | Windows 11 24H2 Ready                     ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@

$Script:WD7HeaderCompact = @"
╔══════════════════════════════════════════════════════════════╗
║            ▄▀▀▀▀▄ Win-Debloat7 ▄▀▀▀▀▄                        ║
║              Ultimate System Optimizer                       ║
╚══════════════════════════════════════════════════════════════╝
"@

function Write-WD7Host {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,
        
        [ValidateSet("Primary", "Secondary", "Success", "Warning", "Error", "Info", "Dark", "White")]
        [string]$Color = "Info",
        
        [switch]$NoNewline,
        
        [switch]$Bold
    )
    
    $consoleColor = $Script:WD7Colors[$Color]
    
    # Apply formatting
    if ($Bold -and $Color -eq "Primary") {
        $consoleColor = "Cyan"
    }
    
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $consoleColor -NoNewline
    }
    else {
        Write-Host $Message -ForegroundColor $consoleColor
    }
}

function Show-WD7Header {
    [CmdletBinding()]
    param(
        [switch]$Compact
    )
    
    Clear-Host
    
    if ($Compact) {
        Write-Host $Script:WD7HeaderCompact -ForegroundColor Cyan
    }
    else {
        # Full premium header with gradient effect
        $lines = $Script:WD7Header -split "`n"
        $colors = @("DarkCyan", "Cyan", "Cyan", "Cyan", "Cyan", "Cyan", "Cyan", "Cyan", "DarkCyan", "DarkCyan", "DarkCyan", "DarkCyan")
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $c = if ($i -lt $colors.Count) { $colors[$i] } else { "DarkCyan" }
            Write-Host $lines[$i] -ForegroundColor $c
        }
    }
    
    Write-Host ""
}

function Show-WD7Separator {
    [CmdletBinding()]
    param(
        [string]$Title = "",
        [string]$Color = "Primary"
    )
    
    $consoleWidth = 60
    
    if ([string]::IsNullOrEmpty($Title)) {
        Write-WD7Host ("─" * $consoleWidth) -Color $Color
    }
    else {
        $padding = [math]::Max(0, ($consoleWidth - $Title.Length - 4) / 2)
        $line = ("─" * [int]$padding) + "[ $Title ]" + ("─" * [int]$padding)
        Write-WD7Host $line -Color $Color
    }
}

function Show-WD7Progress {
    [CmdletBinding()]
    param(
        [int]$Percent,
        [int]$Width = 40,
        [string]$Label = ""
    )
    
    $filled = [math]::Round($Width * $Percent / 100)
    $empty = $Width - $filled
    
    $bar = "█" * $filled + "░" * $empty
    $display = "[$bar] $Percent%"
    
    if ($Label) {
        $display = "$Label $display"
    }
    
    Write-Host "`r$display" -NoNewline -ForegroundColor Cyan
}

function Show-WD7StatusBadge {
    [CmdletBinding()]
    param(
        [string]$Label,
        [ValidateSet("Success", "Warning", "Error", "Info")]
        [string]$Status
    )
    
    $icon = switch ($Status) {
        "Success" { "●" }
        "Warning" { "◐" }
        "Error" { "○" }
        "Info" { "◌" }
    }
    
    Write-WD7Host "  $icon " -Color $Status -NoNewline
    Write-WD7Host $Label -Color White
}

Export-ModuleMember -Function Write-WD7Host, Show-WD7Header, Show-WD7Separator, Show-WD7Progress, Show-WD7StatusBadge -Variable WD7Colors
