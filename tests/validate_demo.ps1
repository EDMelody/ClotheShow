$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$demoPath = Join-Path $repositoryRoot 'demo\index.html'

if (-not (Test-Path -LiteralPath $demoPath -PathType Leaf)) {
    throw 'demo/index.html 不存在。'
}

$content = Get-Content -LiteralPath $demoPath -Raw -Encoding UTF8
$requiredContent = @(
    '<!doctype html>',
    'lang="zh-CN"',
    'name="viewport"',
    '童装 3D 展示 Demo',
    'data-open-scanner',
    'id="productGrid"',
    'id="detailScreen"',
    'id="favoriteScreen"',
    'prefers-reduced-motion'
)

foreach ($item in $requiredContent) {
    if (-not $content.Contains($item)) {
        throw "HTML Demo 缺少必要内容：$item"
    }
}

if ($content -match '<script\s+[^>]*src=["'']https?://' -or $content -match '<link\s+[^>]*href=["'']https?://') {
    throw 'HTML Demo 不应依赖外部脚本或样式。'
}

foreach ($pwaFile in @('manifest.webmanifest', 'service-worker.js', 'icons\icon-180.png', 'icons\icon-512.png')) {
    if (-not (Test-Path -LiteralPath (Join-Path (Split-Path $demoPath) $pwaFile))) {
        throw "HTML Demo 缺少 PWA 文件：$pwaFile"
    }
}

$productCount = ([regex]::Matches($content, "\{ id: \d+, name:")).Count
if ($productCount -lt 6) {
    throw "HTML Demo 示例商品不足：$productCount"
}

Write-Output 'demo/index.html validation passed.'
