Add-Type -AssemblyName System.Drawing

function Save-Png([System.Drawing.Bitmap]$bmp, [string]$path) {
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

$outDir = "C:\Users\jeffr\Projects\Narcotics\Textures\Things\Building\Production"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$wood = [System.Drawing.Color]::FromArgb(255, 145, 110, 72)
$woodDark = [System.Drawing.Color]::FromArgb(255, 110, 82, 52)
$woodLight = [System.Drawing.Color]::FromArgb(255, 168, 132, 90)
$metal = [System.Drawing.Color]::FromArgb(255, 120, 125, 130)
$metalDark = [System.Drawing.Color]::FromArgb(255, 85, 90, 95)
$glass = [System.Drawing.Color]::FromArgb(180, 170, 210, 220)
$glassStroke = [System.Drawing.Color]::FromArgb(220, 90, 120, 130)
$burner = [System.Drawing.Color]::FromArgb(255, 70, 70, 75)
$flame = [System.Drawing.Color]::FromArgb(220, 230, 140, 60)
$stain = [System.Drawing.Color]::FromArgb(60, 40, 90, 50)
$shadow = [System.Drawing.Color]::FromArgb(50, 0, 0, 0)
$tubeC = [System.Drawing.Color]::FromArgb(200, 100, 140, 100)

function Draw-Flask([System.Drawing.Graphics]$g, [int]$x, [int]$y) {
  $gb = New-Object System.Drawing.SolidBrush $glass
  $pen = New-Object System.Drawing.Pen $glassStroke, 1.0
  $g.FillEllipse($gb, $x, ($y + 8), 14, 14)
  $g.FillRectangle($gb, ($x + 4), $y, 6, 12)
  $g.DrawEllipse($pen, $x, ($y + 8), 14, 14)
  $gb.Dispose(); $pen.Dispose()
}

# SOUTH
$b = New-Object System.Drawing.Bitmap 256, 128, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($b)
$g.Clear([System.Drawing.Color]::Transparent)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None

$sb = New-Object System.Drawing.SolidBrush $shadow
$g.FillEllipse($sb, 28, 98, 200, 18); $sb.Dispose()

$wd = New-Object System.Drawing.SolidBrush $woodDark
$g.FillRectangle($wd, 40, 78, 10, 28)
$g.FillRectangle($wd, 206, 78, 10, 28)
$g.FillRectangle($wd, 90, 82, 8, 22)
$g.FillRectangle($wd, 160, 82, 8, 22)

$wo = New-Object System.Drawing.SolidBrush $wood
$g.FillRectangle($wo, 32, 58, 192, 28); $wo.Dispose()
$wl = New-Object System.Drawing.SolidBrush $woodLight
$g.FillRectangle($wl, 32, 58, 192, 6); $wl.Dispose()
$g.FillRectangle($wd, 32, 82, 192, 4); $wd.Dispose()

$mb = New-Object System.Drawing.SolidBrush $metal
$g.FillRectangle($mb, 40, 64, 176, 10)
$st = New-Object System.Drawing.SolidBrush $stain
$g.FillRectangle($st, 55, 66, 40, 6)
$g.FillRectangle($st, 130, 67, 25, 5); $st.Dispose()

Draw-Flask $g 50 42
Draw-Flask $g 78 40
$penTube = New-Object System.Drawing.Pen $tubeC, 2.0
$g.DrawBezier($penTube, 64, 42, 90, 28, 120, 30, 140, 48); $penTube.Dispose()

$bb = New-Object System.Drawing.SolidBrush $burner
$g.FillRectangle($bb, 148, 52, 16, 12); $bb.Dispose()
$fb = New-Object System.Drawing.SolidBrush $flame
$g.FillEllipse($fb, 151, 44, 10, 10); $fb.Dispose()
Draw-Flask $g 170 40

$md = New-Object System.Drawing.SolidBrush $metalDark
$g.FillRectangle($md, 200, 50, 14, 16); $md.Dispose()
$g.FillRectangle($mb, 201, 51, 12, 4); $mb.Dispose()

$g.Dispose()
Save-Png $b (Join-Path $outDir "MethLab_south.png")

# NORTH flip
$north = New-Object System.Drawing.Bitmap 256, 128, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gn = [System.Drawing.Graphics]::FromImage($north)
$gn.Clear([System.Drawing.Color]::Transparent)
$gn.TranslateTransform(256, 0)
$gn.ScaleTransform(-1, 1)
$gn.DrawImage($b, 0, 0)
$gn.Dispose()
Save-Png $north (Join-Path $outDir "MethLab_north.png")
$north.Dispose(); $b.Dispose()

function Make-Side([string]$path, [bool]$flip) {
  $b = New-Object System.Drawing.Bitmap 128, 128, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($b)
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
  $sb = New-Object System.Drawing.SolidBrush $shadow
  $g.FillEllipse($sb, 30, 100, 68, 14); $sb.Dispose()
  $wd = New-Object System.Drawing.SolidBrush $woodDark
  $g.FillRectangle($wd, 48, 78, 10, 28)
  $g.FillRectangle($wd, 70, 78, 10, 28); $wd.Dispose()
  $wo = New-Object System.Drawing.SolidBrush $wood
  $g.FillRectangle($wo, 40, 58, 48, 28); $wo.Dispose()
  $wl = New-Object System.Drawing.SolidBrush $woodLight
  $g.FillRectangle($wl, 40, 58, 48, 6); $wl.Dispose()
  $mb = New-Object System.Drawing.SolidBrush $metal
  $g.FillRectangle($mb, 44, 64, 40, 8); $mb.Dispose()
  Draw-Flask $g 52 40
  $bb = New-Object System.Drawing.SolidBrush $burner
  $g.FillRectangle($bb, 72, 52, 10, 10); $bb.Dispose()
  $g.Dispose()
  if ($flip) {
    $flipped = New-Object System.Drawing.Bitmap 128, 128, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gf = [System.Drawing.Graphics]::FromImage($flipped)
    $gf.Clear([System.Drawing.Color]::Transparent)
    $gf.TranslateTransform(128, 0)
    $gf.ScaleTransform(-1, 1)
    $gf.DrawImage($b, 0, 0)
    $gf.Dispose(); $b.Dispose(); $b = $flipped
  }
  Save-Png $b $path
  $b.Dispose()
}

Make-Side (Join-Path $outDir "MethLab_east.png") $false
Make-Side (Join-Path $outDir "MethLab_west.png") $true

Get-ChildItem $outDir -Filter "MethLab_*" | Format-Table Name, Length
Write-Output "OK"
