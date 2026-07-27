# Generate RimWorld-style PNG sprites for Narcotics mod
Add-Type -AssemblyName System.Drawing

$root = "C:\Users\jeffr\Projects\Narcotics\Textures"
$size = 128

function New-Bitmap {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $bmp.SetResolution(96, 96)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::Transparent)
  return @{ Bmp = $bmp; G = $g }
}

function Save-Bmp($bmp, $path) {
  $dir = Split-Path $path -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Draw-Oval($g, $brush, $pen, $x, $y, $w, $h) {
  $g.FillEllipse($brush, $x, $y, $w, $h)
  if ($pen) { $g.DrawEllipse($pen, $x, $y, $w, $h) }
}

function Draw-RoundRect($g, $brush, $pen, $x, $y, $w, $h, $r) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddArc($x, $y, $r, $r, 180, 90)
  $path.AddArc($x + $w - $r, $y, $r, $r, 270, 90)
  $path.AddArc($x + $w - $r, $y + $h - $r, $r, $r, 0, 90)
  $path.AddArc($x, $y + $h - $r, $r, $r, 90, 90)
  $path.CloseFigure()
  $g.FillPath($brush, $path)
  if ($pen) { $g.DrawPath($pen, $path) }
  $path.Dispose()
}

function New-Brush($r, $g, $b, $a = 255) {
  New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($a, $r, $g, $b))
}

function New-PenC($r, $g, $b, $width = 1.5) {
  $p = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, $r, $g, $b), $width)
  return $p
}

# --- Percocet: amber blister with white pills ---
function Draw-Percocet($tier) {
  $o = New-Bitmap; $g = $o.G; $bmp = $o.Bmp
  $amber = New-Brush 210 140 55
  $amberDark = New-Brush 160 95 30
  $amberLite = New-Brush 235 185 110
  $white = New-Brush 245 245 240
  $outline = New-PenC 90 55 20 2
  $count = switch ($tier) { 'a' { 1 } 'b' { 3 } 'c' { 6 } }
  $cols = if ($tier -eq 'c') { 3 } else { [Math]::Min($count, 2) }
  $i = 0
  for ($row = 0; $row -lt 3 -and $i -lt $count; $row++) {
    for ($col = 0; $col -lt $cols -and $i -lt $count; $col++) {
      $ox = 18 + $col * 36 + $(if ($tier -eq 'c') { 4 } else { 10 })
      $oy = 22 + $row * 34
      Draw-RoundRect $g $amber $outline $ox $oy 32 28 6
      $g.FillRectangle($amberLite, $ox + 4, $oy + 3, 24, 6)
      Draw-Oval $g $white $null ($ox + 8) ($oy + 10) 16 12
      $i++
    }
  }
  $g.Dispose(); Save-Bmp $bmp "$root\Things\Item\Drug\Percocet_$tier.png"; $bmp.Dispose()
}

# --- Xanax: blue scored bars ---
function Draw-Xanax($tier) {
  $o = New-Bitmap; $g = $o.G; $bmp = $o.Bmp
  $blue = New-Brush 170 185 230
  $blueDark = New-Brush 110 125 180
  $pack = New-Brush 220 225 240
  $outline = New-PenC 60 70 110 2
  $score = New-PenC 90 100 150 1.2
  $count = switch ($tier) { 'a' { 1 } 'b' { 3 } 'c' { 7 } }
  for ($i = 0; $i -lt $count; $i++) {
    $ox = 20 + ($i % 3) * 30 + $(if ($tier -eq 'a') { 20 } else { 0 })
    $oy = 30 + [Math]::Floor($i / 3) * 28 + $(if ($tier -eq 'a') { 15 } else { 0 })
    Draw-RoundRect $g $pack $outline ($ox - 2) ($oy - 2) 34 22 4
    Draw-RoundRect $g $blue $outline $ox $oy 30 18 3
    $g.DrawLine($score, $ox + 15, $oy + 2, $ox + 15, $oy + 16)
    $g.FillRectangle($blueDark, $ox + 3, $oy + 3, 8, 3)
  }
  $g.Dispose(); Save-Bmp $bmp "$root\Things\Item\Drug\Xanax_$tier.png"; $bmp.Dispose()
}

# --- Weed: green buds ---
function Draw-Weed($tier) {
  $o = New-Bitmap; $g = $o.G; $bmp = $o.Bmp
  $green = New-Brush 70 130 55
  $greenLite = New-Brush 110 170 80
  $greenDark = New-Brush 40 90 35
  $bag = New-Brush 200 185 140
  $outline = New-PenC 30 60 25 1.8
  $count = switch ($tier) { 'a' { 1 } 'b' { 3 } 'c' { 8 } }
  if ($tier -ne 'a') {
    Draw-RoundRect $g $bag $outline 24 40 80 70 10
  }
  for ($i = 0; $i -lt $count; $i++) {
    $ox = 28 + ($i % 4) * 20 + $(if ($tier -eq 'a') { 25 } else { 0 })
    $oy = 28 + [Math]::Floor($i / 4) * 22 + $(if ($tier -eq 'a') { 30 } else { 10 })
    Draw-Oval $g $green $outline $ox $oy 22 26
    Draw-Oval $g $greenLite $null ($ox + 5) ($oy + 4) 10 8
    $g.FillPolygon($greenDark, @(
      (New-Object System.Drawing.Point ($ox + 11), ($oy + 2)),
      (New-Object System.Drawing.Point ($ox + 8), ($oy + 14)),
      (New-Object System.Drawing.Point ($ox + 14), ($oy + 14))
    ))
  }
  $g.Dispose(); Save-Bmp $bmp "$root\Things\Item\Drug\Weed_$tier.png"; $bmp.Dispose()
}

# --- Cocaine: white powder pouch ---
function Draw-Cocaine($tier) {
  $o = New-Bitmap; $g = $o.G; $bmp = $o.Bmp
  $pouch = New-Brush 235 235 230
  $pouchDark = New-Brush 190 190 185
  $powder = New-Brush 250 250 252
  $outline = New-PenC 100 100 105 2
  $count = switch ($tier) { 'a' { 1 } 'b' { 2 } 'c' { 5 } }
  for ($i = 0; $i -lt $count; $i++) {
    $ox = 22 + ($i % 3) * 32 + $(if ($tier -eq 'a') { 22 } else { 0 })
    $oy = 30 + [Math]::Floor($i / 3) * 36 + $(if ($tier -eq 'a') { 18 } else { 0 })
    Draw-RoundRect $g $pouch $outline $ox $oy 36 42 8
    $g.FillRectangle($pouchDark, $ox + 4, $oy + 4, 28, 8)
    Draw-Oval $g $powder $outline ($ox + 8) ($oy + 18) 20 16
    $g.FillEllipse((New-Brush 255 255 255 180), $ox + 12, $oy + 20, 8, 6)
  }
  $g.Dispose(); Save-Bmp $bmp "$root\Things\Item\Drug\Cocaine_$tier.png"; $bmp.Dispose()
}

# --- Coca leaves ---
function Draw-CocaLeaves($tier) {
  $o = New-Bitmap; $g = $o.G; $bmp = $o.Bmp
  $leaf = New-Brush 55 120 50
  $leafLite = New-Brush 90 150 70
  $outline = New-PenC 30 70 30 1.5
  $count = switch ($tier) { 'a' { 2 } 'b' { 5 } 'c' { 12 } }
  $rng = New-Object System.Random 42
  for ($i = 0; $i -lt $count; $i++) {
    $ox = 20 + $rng.Next(0, 70)
    $oy = 25 + $rng.Next(0, 60)
    $pts = @(
      (New-Object System.Drawing.Point ($ox + 12), $oy),
      (New-Object System.Drawing.Point ($ox + 22), ($oy + 18)),
      (New-Object System.Drawing.Point ($ox + 12), ($oy + 30)),
      (New-Object System.Drawing.Point $ox, ($oy + 18))
    )
    $g.FillPolygon($leaf, $pts)
    $g.DrawPolygon($outline, $pts)
    $g.DrawLine((New-PenC 40 90 40 1), ($ox + 12), ($oy + 2), ($ox + 12), ($oy + 28))
  }
  $g.Dispose(); Save-Bmp $bmp "$root\Things\Item\Resource\PlantFoodRaw\CocaLeaves_$tier.png"; $bmp.Dispose()
}

# --- Plants (folder for Graphic_Random) ---
function Draw-PlantWeed($variant) {
  $o = New-Bitmap; $g = $o.G; $bmp = $o.Bmp
  $stem = New-PenC 50 90 40 3
  $leaf = New-Brush 65 140 55
  $leaf2 = New-Brush 85 160 70
  $outline = New-PenC 35 80 30 1.5
  $g.DrawLine($stem, 64, 110, 64, 40)
  $offsets = @(
    @(-28, 50, 30, 22), @(8, 45, 32, 24), @(-20, 70, 28, 20), @(12, 68, 26, 18), @(-8, 30, 24, 28)
  )
  $shift = ($variant - 1) * 3
  for ($i = 0; $i -lt $offsets.Count; $i++) {
    $o2 = $offsets[$i]
    $brush = if (($i + $shift) % 2 -eq 0) { $leaf } else { $leaf2 }
    Draw-Oval $g $brush $outline (64 + $o2[0]) $o2[1] $o2[2] $o2[3]
  }
  # bud clusters
  Draw-Oval $g (New-Brush 90 160 60) $outline 52 22 24 28
  Draw-Oval $g (New-Brush 70 130 50) $null 58 28 12 14
  $g.Dispose()
  $dir = "$root\Things\Plant\WeedPlant"
  Save-Bmp $bmp "$dir\WeedPlant$variant.png"; $bmp.Dispose()
}

function Draw-PlantCoca($variant) {
  $o = New-Bitmap; $g = $o.G; $bmp = $o.Bmp
  $stem = New-PenC 60 100 45 2.5
  $leaf = New-Brush 45 110 55
  $leaf2 = New-Brush 70 135 70
  $outline = New-PenC 25 70 35 1.4
  $g.DrawLine($stem, 64, 115, 64, 35)
  $g.DrawLine($stem, 64, 70, 40, 50)
  $g.DrawLine($stem, 64, 70, 88, 50)
  $g.DrawLine($stem, 64, 55, 45, 35)
  $g.DrawLine($stem, 64, 55, 83, 35)
  $leafPts = @(
    @(30, 40), @(78, 38), @(38, 58), @(72, 56), @(48, 28), @(68, 26), @(52, 75), @(60, 72)
  )
  $shift = ($variant - 1) * 2
  for ($i = 0; $i -lt $leafPts.Count; $i++) {
    $p = $leafPts[($i + $shift) % $leafPts.Count]
    $brush = if ($i % 2 -eq 0) { $leaf } else { $leaf2 }
    $pts = @(
      (New-Object System.Drawing.Point ($p[0] + 10), $p[1]),
      (New-Object System.Drawing.Point ($p[0] + 20), ($p[1] + 14)),
      (New-Object System.Drawing.Point ($p[0] + 10), ($p[1] + 26)),
      (New-Object System.Drawing.Point $p[0], ($p[1] + 14))
    )
    $g.FillPolygon($brush, $pts)
    $g.DrawPolygon($outline, $pts)
  }
  $g.Dispose()
  $dir = "$root\Things\Plant\CocaPlant"
  Save-Bmp $bmp "$dir\CocaPlant$variant.png"; $bmp.Dispose()
}

foreach ($t in @('a','b','c')) {
  Draw-Percocet $t
  Draw-Xanax $t
  Draw-Weed $t
  Draw-Cocaine $t
  Draw-CocaLeaves $t
}
1..3 | ForEach-Object { Draw-PlantWeed $_; Draw-PlantCoca $_ }

Write-Output "Art generated."
Get-ChildItem $root -Recurse -Filter *.png | Select-Object FullName, Length
