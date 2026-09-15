$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$output = Join-Path $PSScriptRoot '..\demo\icons'
New-Item -ItemType Directory -Force -Path $output | Out-Null
foreach ($size in @(180, 512)) {
    $bitmap = [System.Drawing.Bitmap]::new($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::FromArgb(247, 243, 236))
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(237, 107, 78))
    $padding = [int]($size * 0.16)
    $graphics.FillEllipse($brush, $padding, $padding, $size - 2 * $padding, $size - 2 * $padding)
    $font = [System.Drawing.Font]::new('Microsoft YaHei UI', [single]($size * 0.29), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $graphics.DrawString('裳', $font, [System.Drawing.Brushes]::White, [System.Drawing.RectangleF]::new(0, 0, $size, $size), $format)
    $bitmap.Save((Join-Path $output "icon-$size.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $format.Dispose(); $font.Dispose(); $brush.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
}
Write-Output 'Generated PWA icons.'
