$packageName = 'win-debloat7'
$version     = '1.2.0'
$url = "https://github.com/tomytate/Win-Debloat7/releases/download/v$version/Win-Debloat7-v$version-Standard.zip"
$installDir = Join-Path $env:ProgramData "Win-Debloat7"
$checksum    = "2A0E1772486FAC4CB7C4B2D9916BA0E91DDDBF0013AEC9088586393E0EAC7138" # Will be updated by build script

$packageArgs = @{
    packageName   = $packageName
    unzipLocation = $installDir
    url           = $url
    softwareName  = 'Win-Debloat7'
    checksum      = $checksum
    checksumType  = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

# Create CLI Shim
$shimPath = Join-Path $installDir "Win-Debloat7.ps1"
Install-BinFile -Name "win-debloat7" -Path $shimPath

# Create Start Menu Shortcut
$shortcutPath = Join-Path ([Environment]::GetFolderPath("CommonPrograms")) "Win-Debloat7.lnk"
Install-ChocolateyShortcut -ShortcutFilePath $shortcutPath `
    -TargetPath "pwsh.exe" `
    -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$shimPath`"" `
    -IconLocation "$installDir\assets\icon.ico" `
    -Description "Launch Win-Debloat7"

Write-Host "Win-Debloat7 installed to $installDir"
