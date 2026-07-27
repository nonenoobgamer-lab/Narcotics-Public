# Process AI-generated sprites into RimWorld 128x128 stack frames
Add-Type -AssemblyName System.Drawing

$assets = "C:\Users\jeffr\.cursor\projects\c-Users-jeffr-Projects-Narcotics\assets"
$tex = "C:\Users\jeffr\Projects\Narcotics\Textures"
$size = 128

function Make-Transparent([System.Drawing.Bitmap]$src) {
  $dst = New-Object System.Drawing.Bitmap $src.Width, $src.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  for ($y = 0; $y -lt $src.Height; $y++) {
    for ($x = 0; $x -lt $src.Width; $x++) {
      $c = $src.GetPixel($x, $y)
      # Remove pale/white/cream studio backgrounds
      $bright = ($c.R + $c.G + $c.B) / 3
      $sat = [Math]::Max($c.R, [Math]::Max($c.G, $c.B)) - [Math]::Min($c.R, [Math]::Min($c.G, $c.B))
      if ($bright -gt 210 -and $sat -lt 40) {
        $dst.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
      } elseif ($bright -gt 235) {
        $dst.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
      } else {
        $dst.SetPixel($x, $y, $c)
      }
    }
  }
  return $dst
}

function Get-ContentBounds([System.Drawing.Bitmap]$bmp) {
  $minX = $bmp.Width; $minY = $bmp.Height; $maxX = 0; $maxY = 0
  for ($y = 0; $y -lt $bmp.Height; $y++) {
    for ($x = 0; $x -lt $bmp.Width; $x++) {
      if ($bmp.GetPixel($x, $y).A -gt 16) {
        if ($x -lt $minX) { $minX = $x }
        if ($y -lt $minY) { $minY = $y }
        if ($x -gt $maxX) { $maxX = $x }
        if ($y -gt $maxY) { $maxY = $y }
      }
    }
  }
  if ($maxX -lt $minX) { return [System.Drawing.Rectangle]::new(0,0,$bmp.Width,$bmp.Height) }
  $pad = 4
  $minX = [Math]::Max(0, $minX - $pad)
  $minY = [Math]::Max(0, $minY - $pad)
  $maxX = [Math]::Min($bmp.Width - 1, $maxX + $pad)
  $maxY = [Math]::Min($bmp.Height - 1, $maxY + $pad)
  return [System.Drawing.Rectangle]::new($minX, $minY, $maxX - $minX + 1, $maxY - $minY + 1)
}

function Fit-Square([System.Drawing.Bitmap]$src, [int]$outSize) {
  $bounds = Get-ContentBounds $src
  $cropped = $src.Clone($bounds, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $out = New-Object System.Drawing.Bitmap $outSize, $outSize, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($out)
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $scale = [Math]::Min(($outSize - 8) / [double]$cropped.Width, ($outSize - 8) / [double]$cropped.Height)
  $w = [int]($cropped.Width * $scale)
  $h = [int]($cropped.Height * $scale)
  $x = ($outSize - $w) / 2
  $y = ($outSize - $h) / 2
  $g.DrawImage($cropped, $x, $y, $w, $h)
  $g.Dispose(); $cropped.Dispose()
  return $out
}

function Save-Png([System.Drawing.Bitmap]$bmp, [string]$path) {
  $dir = Split-Path $path -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Make-StackFrames([System.Drawing.Bitmap]$single, [string]$folderPath) {
  if (-not (Test-Path $folderPath)) { New-Item -ItemType Directory -Force -Path $folderPath | Out-Null }
  Save-Png $single (Join-Path $folderPath "a.png")

  $b = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $gb = [System.Drawing.Graphics]::FromImage($b)
  $gb.Clear([System.Drawing.Color]::Transparent)
  $gb.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $s = 72
  $gb.DrawImage($single, 8, 40, $s, $s)
  $gb.DrawImage($single, 48, 20, $s, $s)
  $gb.DrawImage($single, 28, 8, $s, $s)
  $gb.Dispose(); Save-Png $b (Join-Path $folderPath "b.png"); $b.Dispose()

  $c = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $gc = [System.Drawing.Graphics]::FromImage($c)
  $gc.Clear([System.Drawing.Color]::Transparent)
  $gc.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $s2 = 56
  $positions = @(
    @(4,60), @(36,55), @(68,50),
    @(16,30), @(48,25), @(70,20),
    @(32,4), @(55,8)
  )
  foreach ($p in $positions) {
    $gc.DrawImage($single, $p[0], $p[1], $s2, $s2)
  }
  $gc.Dispose(); Save-Png $c (Join-Path $folderPath "c.png"); $c.Dispose()
}

function Load-Downscaled([string]$srcPath, [int]$maxDim = 256) {
  $raw = [System.Drawing.Image]::FromFile($srcPath)
  $scale = [Math]::Min(1.0, $maxDim / [double][Math]::Max($raw.Width, $raw.Height))
  $w = [Math]::Max(1, [int]($raw.Width * $scale))
  $h = [Math]::Max(1, [int]($raw.Height * $scale))
  $small = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($small)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.DrawImage($raw, 0, 0, $w, $h)
  $g.Dispose(); $raw.Dispose()
  return $small
}

function Process-Item([string]$name, [string]$relDir) {
  $srcPath = Join-Path $assets "${name}_a.png"
  Write-Output "Processing $srcPath"
  $bmp = Load-Downscaled $srcPath 256
  $trans = Make-Transparent $bmp
  $bmp.Dispose()
  $fit = Fit-Square $trans $size
  $trans.Dispose()
  $outFolder = Join-Path $tex (Join-Path $relDir $name)
  Make-StackFrames $fit $outFolder
  $fit.Dispose()
}

function Process-Plant([string]$srcName, [string]$folderName) {
  $srcPath = Join-Path $assets $srcName
  Write-Output "Processing plant $srcPath"
  $bmp = Load-Downscaled $srcPath 256
  $trans = Make-Transparent $bmp
  $bmp.Dispose()
  $fit = Fit-Square $trans $size
  $trans.Dispose()
  $dir = Join-Path $tex "Things\Plant\$folderName"
  Save-Png $fit (Join-Path $dir "${folderName}1.png")

  for ($v = 2; $v -le 3; $v++) {
    $var = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($var)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.TranslateTransform($size/2, $size/2)
    if ($v -eq 2) { $g.ScaleTransform(-1, 1) }
    else { $g.ScaleTransform(0.95, 1.05) }
    $g.TranslateTransform(-$size/2, -$size/2)
    $g.DrawImage($fit, 0, 0, $size, $size)
    $g.Dispose()
    Save-Png $var (Join-Path $dir "${folderName}$v.png")
    $var.Dispose()
  }
  $fit.Dispose()
}

Process-Item "Percocet" "Things\Item\Drug"
Process-Item "Xanax" "Things\Item\Drug"
Process-Item "Weed" "Things\Item\Drug"
Process-Item "Cocaine" "Things\Item\Drug"
Process-Item "CocaLeaves" "Things\Item\Resource\PlantFoodRaw"
Process-Plant "WeedPlant1.png" "WeedPlant"
Process-Plant "CocaPlant1.png" "CocaPlant"

Write-Output "Done."
Get-ChildItem $tex -Recurse -Filter *.png | ForEach-Object { "$($_.FullName.Replace($tex,'')) $($_.Length)" }
