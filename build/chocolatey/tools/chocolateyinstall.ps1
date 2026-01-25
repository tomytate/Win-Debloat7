$packageName = 'win-debloat7'
$version     = '1.2.0'
$url = "https://github.com/tomytate/Win-Debloat7/releases/download/v$version/Win-Debloat7.exe"
$checksum    = "13053EF8EDAC7B3F35F65F1B2FCFB5D8AEC376C9FB433011DF35890287154AA0" 
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$exePath = Join-Path $toolsDir "Win-Debloat7.exe"

$packageArgs = @{
    packageName  = $packageName
    fileType     = 'exe'
    url          = $url
    checksum     = $checksum
    checksumType = 'sha256'
    destination  = $toolsDir
    fileName     = "Win-Debloat7.exe"
}

Get-ChocolateyWebFile @packageArgs

# Create Shim (Chocolatey automatically shims executables in the package folder if not ignored, but let's be explicit)
# Actually, just dropping it in tools/ is enough for automatic shimming if we don't name it .ignore.
# But we might want a clean alias.
# Install-BinFile -Name "win-debloat7" -Path $exePath # Not needed if file is in tools and named right?
# Actually, the file is named Win-Debloat7.exe. Shim will be Win-Debloat7.exe. 
# We want win-debloat7 (lowercase) alias too?
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
