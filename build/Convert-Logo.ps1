param(
    [string]$InputPng,
    [string]$OutputIco
)

try {
    $InputPng = Resolve-Path $InputPng
    Write-Host "Converting $InputPng to $OutputIco..." -ForegroundColor Cyan

    $bytes = [System.IO.File]::ReadAllBytes($InputPng)
    $img = [System.Drawing.Image]::FromFile($InputPng)
    $width = $img.Width
    $height = $img.Height
    $img.Dispose()

    # ICO Header (6 bytes)
    # Reserved (2), Type (2, 1=ICO), Count (2)
    $header = [byte[]]@(0, 0, 1, 0, 1, 0)

    # Directory Entry (16 bytes)
    # Width(1), Height(1), Colors(1), Res(1), Planes(2), Bits(2), Size(4), Offset(4)
    # Width/Height 0 = 256px
    $w = if ($width -ge 256) { 0 } else { $width }
    $h = if ($height -ge 256) { 0 } else { $height }
    
    $entry = New-Object byte[] 16
    $entry[0] = $w
    $entry[1] = $h
    $entry[2] = 0 # Palette
    $entry[3] = 0 # Res
    $entry[4] = 1 # Planes (Lo)
    $entry[5] = 0 # Planes (Hi)
    $entry[6] = 32 # BPP (Lo)
    $entry[7] = 0  # BPP (Hi)
    
    # Size of image data
    [System.BitConverter]::GetBytes([int]$bytes.Length).CopyTo($entry, 8)
    
    # Offset (Header 6 + Entry 16 = 22)
    [System.BitConverter]::GetBytes([int]22).CopyTo($entry, 12)

    # Write File
    $fs = [System.IO.File]::Create($OutputIco)
    $fs.Write($header, 0, $header.Length)
    $fs.Write($entry, 0, $entry.Length)
    $fs.Write($bytes, 0, $bytes.Length)
    $fs.Close()

    Write-Host "✅ ICON generated: $OutputIco" -ForegroundColor Green
}
catch {
    Write-Error "Failed to convert icon: $_"
    exit 1
}
