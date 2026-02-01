<#
.SYNOPSIS
    Premium color scheme and branding for Win-Debloat7 TUI (Cyber-Minimalist Edition)
    
.DESCRIPTION
    Defines the "Neon Cyber" color palette with TrueColor (RGB) support for PowerShell 7+.
    
.NOTES
    Module: Win-Debloat7.UI.Colors
    Version: 1.3.0
#>

#Requires -Version 7.5

# Premium Color Scheme - Neon Cyber Palette
$Script:WD7Theme = @{
    # Hex Colors for Modern Terminals
    Colors   = @{
        Primary   = "#00D4FF" # Cyan Neon
        Secondary = "#7B2CBF" # Purple Neon
        Success   = "#00FF88" # Green Neon
        Warning   = "#FFB800" # Orange Neon
        Error     = "#FF3366" # Red/Pink Neon
        Info      = "#A0A0B0" # Gray Blue
        Dark      = "#606070" # Muted
        White     = "#FFFFFF" # Pure White
    }
    
    # Fallback for Legacy Consoles
    Fallback = @{
        Primary   = "Cyan"
        Secondary = "Magenta"
        Success   = "Green"
        Warning   = "Yellow"
        Error     = "Red"
        Info      = "Gray"
        Dark      = "DarkGray"
        White     = "White"
    }
}

# Original Classic ASCII Header (Restored)
$Script:WD7Header = @"
╔═════════════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                                 ║
║  ██╗    ██╗██╗███╗   ██╗      ██████╗ ███████╗██████╗ ██╗      ██████╗  █████╗ ████████╗███████╗║
║  ██║    ██║██║████╗  ██║      ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗██╔══██╗╚══██╔══╝╚════██║║
║  ██║ █╗ ██║██║██╔██╗ ██║█████╗██║  ██║█████╗  ██████╔╝██║     ██║   ██║███████║   ██║       ██╔╝║
║  ██║███╗██║██║██║╚██╗██║╚════╝██║  ██║██╔══╝  ██╔══██╗██║     ██║   ██║██╔══██║   ██║      ██╔╝ ║
║  ╚███╔███╔╝██║██║ ╚████║      ██████╔╝███████╗██████╔╝███████╗╚██████╔╝██║  ██║   ██║      ██║  ║
║   ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝      ╚═════╝ ╚══════╝╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝      ╚═╝  ║
║                                                                                                 ║
║                          Ultimate System Optimizer v1.2.6                                       ║
║                       PowerShell 7.5+ | Windows 11 25H2 Ready                                   ║
╚═════════════════════════════════════════════════════════════════════════════════════════════════╝
"@

$Script:WD7HeaderCompact = @"
╔══════════════════════════════════════════════════════════════╗
║            ▄▀▀▀▀▄ Win-Debloat7 ▄▀▀▀▀▄                        ║
║              Ultimate System Optimizer                       ║
╚══════════════════════════════════════════════════════════════╝
"@

function Get-WD7AnsiColor {
    param([string]$Hex)
    
    if (-not $Hex -match "^#([0-9a-fA-F]{6})$") { return "" }
    
    $r = [Convert]::ToByte($Hex.Substring(1, 2), 16)
    $g = [Convert]::ToByte($Hex.Substring(3, 2), 16)
    $b = [Convert]::ToByte($Hex.Substring(5, 2), 16)
    
    # Return ANSI sequence
    return "$([char]27)[38;2;$r;$g;${b}m"
}

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
    
    # Check for RGB Support ($PSStyle exists in PS 7.2+)
    $useRgb = $null -ne $PSStyle
    $ansi = ""
    $reset = ""
    
    if ($useRgb) {
        $hex = $Script:WD7Theme.Colors[$Color]
        $ansi = Get-WD7AnsiColor -Hex $hex
        $reset = "$([char]27)[0m"
        
        if ($Bold) {
            $ansi += "$([char]27)[1m"
        }
        
        # Write directly to host to strict control
        if ($NoNewline) {
            Write-Host "$ansi$Message$reset" -NoNewline
        }
        else {
            Write-Host "$ansi$Message$reset"
        }
    }
    else {
        # Fallback to ConsoleColor
        $consoleColor = $Script:WD7Theme.Fallback[$Color]
        if ($NoNewline) {
            Write-Host $Message -ForegroundColor $consoleColor -NoNewline
        }
        else {
            Write-Host $Message -ForegroundColor $consoleColor
        }
    }
}

function Show-WD7Header {
    [CmdletBinding()]
    param(
        [switch]$Compact
    )
    
    Clear-Host
    
    if ($Compact) {
        # Compact Art
        $lines = $Script:WD7HeaderCompact -split "`n"
        foreach ($line in $lines) { Write-WD7Host $line -Color Primary }
    }
    else {
        $lines = $Script:WD7Header -split "`n"
        
        # Original gradient logic (approximate mapping)
        # Top border -> Primary
        # Logos -> Primary to Secondary gradient
        # Bottom -> White/Info
        
        $i = 0
        foreach ($line in $lines) {
            if ($i -eq 0) { Write-WD7Host $line -Color Info } # Top Border
            elseif ($i -lt 5) { Write-WD7Host $line -Color Primary } # Top half logo
            elseif ($i -lt 9) { Write-WD7Host $line -Color Secondary } # Bottom half logo
            elseif ($i -lt 11) { Write-WD7Host $line -Color White } # Text
            else { Write-WD7Host $line -Color Info } # Bottom Border
            $i++
        }
    }
    
    Write-Host ""
}

function Show-WD7Separator {
    [CmdletBinding()]
    param(
        [string]$Title = "",
        [string]$Color = "Info"
    )
    
    $width = 99 # Match header width roughly
    $lineChar = "─"
    
    if ([string]::IsNullOrEmpty($Title)) {
        Write-WD7Host (" " * 2 + $lineChar * ($width - 4)) -Color $Color
    }
    else {
        # Centered visual separator
        $padLen = [math]::Max(0, ($width - $Title.Length - 6) / 2)
        $padding = $lineChar * $padLen
        Write-WD7Host (" " * 2 + "$padding $Title $padding") -Color $Color
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
    
    # Modern progress block
    $bar = "█" * $filled + "░" * $empty 
    $display = "$Label [$bar] $Percent%"
    
    # Clear line (CR) and write
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
        "Success" { "✔" }
        "Warning" { "⚠" }
        "Error" { "✖" }
        "Info" { "ℹ" }
    }
    
    Write-WD7Host "  $icon " -Color $Status -NoNewline
    Write-WD7Host $Label -Color White
}

Export-ModuleMember -Function Write-WD7Host, Show-WD7Header, Show-WD7Separator, Show-WD7Progress, Show-WD7StatusBadge
