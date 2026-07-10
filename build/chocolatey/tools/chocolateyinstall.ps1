$packageName = 'win-debloat7'
$version     = '1.4.0'
$url = "https://github.com/tomytate/Win-Debloat7/releases/download/v$version/Win-Debloat7.exe"
$checksum    = "EF3A1D115EA5326AFBDAA58DAEAAF14FFE9270C482B95404B24826FB5A970A86" 
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$exePath = Join-Path $toolsDir "Win-Debloat7.exe"

$packageArgs = @{
    packageName  = $packageName
    fileType     = 'exe'
    url          = $url
    checksum     = $checksum
    checksumType = 'sha256'
    FileFullPath = $exePath
}

Get-ChocolateyWebFile @packageArgs

# Chocolatey auto-shims EXEs in tools/; also register a lowercase alias
Install-BinFile -Name "win-debloat7" -Path $exePath

# Create Start Menu Shortcut
$shortcutDir = Join-Path ([Environment]::GetFolderPath("CommonPrograms")) "Win-Debloat7"
if (! (Test-Path $shortcutDir)) { New-Item $shortcutDir -ItemType Directory -Force | Out-Null }
$shortcutPath = Join-Path $shortcutDir "Win-Debloat7.lnk"

Install-ChocolateyShortcut -ShortcutFilePath $shortcutPath `
    -TargetPath "$exePath" `
    -Description "Launch Win-Debloat7" `
    -WindowStyle Maximize

Write-Host "Win-Debloat7 installed to $toolsDir"
