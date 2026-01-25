param(
    [string]$InputPng,
    [string]$OutputIco
)

Add-Type -AssemblyName System.Drawing

try {
    $InputPng = Resolve-Path $InputPng
    Write-Host "Generating Multi-Size ICO from $InputPng..." -ForegroundColor Cyan

    $srcImg = [System.Drawing.Image]::FromFile($InputPng)
    
    # Standard Windows Icon Sizes
    $sizes = @(256, 128, 64, 48, 32, 16)
    
    # We need to store:
    # 1. The resized image data (bytes)
    # 2. The directory entry for that image
    $imagesData = @()
    $headersData = @()
    $offset = 6 + ($sizes.Count * 16) # Initial offset after Header (6) + All Dir Entries (16 * count)

    foreach ($size in $sizes) {
        # Create square canvas
        $bmp = New-Object System.Drawing.Bitmap $size, $size
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

        # Calculate aspect ratio scaling
        $ratio = [Math]::Min($size / $srcImg.Width, $size / $srcImg.Height)
        $w = [int]($srcImg.Width * $ratio)
        $h = [int]($srcImg.Height * $ratio)
        $x = [int](($size - $w) / 2)
        $y = [int](($size - $h) / 2)

        $g.DrawImage($srcImg, $x, $y, $w, $h)
        $g.Dispose()

        # Save to memory stream as PNG
        $ms = New-Object System.IO.MemoryStream
        $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $bytes = $ms.ToArray()
        $ms.Dispose()
        $bmp.Dispose()
        
        $imagesData += , $bytes

        # Create Entry (16 bytes)
        $entry = New-Object byte[] 16
        $entry[0] = if ($size -eq 256) { 0 } else { $size } # Width
        $entry[1] = if ($size -eq 256) { 0 } else { $size } # Height
        $entry[2] = 0 # Colors
        $entry[3] = 0 # Res
        $entry[4] = 1 # Planes
        $entry[5] = 0
        $entry[6] = 32 # BPP
        $entry[7] = 0
        
        # Size (4 bytes)
        [System.BitConverter]::GetBytes([int]$bytes.Length).CopyTo($entry, 8)
        
        # Offset (4 bytes)
        [System.BitConverter]::GetBytes([int]$offset).CopyTo($entry, 12)
        
        $headersData += , $entry
        $offset += $bytes.Length
    }
    
    $srcImg.Dispose()

    # Write Final ICO File
    $fs = [System.IO.File]::Create($OutputIco)
    
    # Header (6 bytes)
    # 0-1: Reserved (0)
    # 2-3: Type (1 = ICO)
    # 4-5: Count
    $fs.WriteByte(0); $fs.WriteByte(0)
    $fs.WriteByte(1); $fs.WriteByte(0)
    # Count (Little Endian)
    $fs.WriteByte([byte]$sizes.Count); $fs.WriteByte(0)
    
    # Write entries
    foreach ($entry in $headersData) {
        $fs.Write($entry, 0, $entry.Length)
    }
    
    # Write image data
    foreach ($data in $imagesData) {
        $fs.Write($data, 0, $data.Length)
    }
    
    $fs.Close()

    Write-Host "✅ Multi-Size ICON generated: $OutputIco" -ForegroundColor Green
}
catch {
    Write-Error "Failed to convert icon: $_"
    exit 1
}
