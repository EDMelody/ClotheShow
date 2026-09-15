$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$requiredFiles = @(
    'project.yml', 'TongShang\Info.plist', 'TongShang\TongShangApp.swift',
    'TongShang\Resources\products.json', 'TongShang\Resources\Viewer\index.html',
    'TongShang\Resources\Viewer\viewer.bundle.js', 'TongShangTests\ProductTests.swift',
    '.github\workflows\ios.yml'
)
foreach ($relative in $requiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) { throw "缺少 iOS 工程文件：$relative" }
}

$manifest = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'TongShang\Resources\products.json') | ConvertFrom-Json
if ($manifest.products.Count -lt 6 -or $manifest.products.Count -gt 10) { throw "示例商品数量应为 6～10，当前为 $($manifest.products.Count)" }
$skus = @{}
foreach ($product in $manifest.products) {
    if ($product.sku -notmatch '^CLOTHE-\d{4}$') { throw "SKU 格式无效：$($product.sku)" }
    if ($skus.ContainsKey($product.sku)) { throw "SKU 重复：$($product.sku)" }
    $skus[$product.sku] = $true
    foreach ($field in @('id','name','category','thumbnail','modelGLB','modelUSDZ')) {
        if ([string]::IsNullOrWhiteSpace($product.$field)) { throw "商品 $($product.id) 缺少字段：$field" }
    }
    $glb = Join-Path $root "TongShang\Resources\Models\$($product.modelGLB)"
    $usdz = Join-Path $root "TongShang\Resources\Models\$($product.modelUSDZ)"
    if (-not (Test-Path $glb) -or -not (Test-Path $usdz)) { throw "商品 $($product.id) 缺少 GLB 或 USDZ" }
    $glbBytes = [System.IO.File]::ReadAllBytes($glb)
    if ([Text.Encoding]::ASCII.GetString($glbBytes, 0, 4) -ne 'glTF') { throw "GLB 文件头无效：$glb" }
    $usdzBytes = [System.IO.File]::ReadAllBytes($usdz)
    if ($usdzBytes[0] -ne 0x50 -or $usdzBytes[1] -ne 0x4B) { throw "USDZ 文件头无效：$usdz" }
}

$viewerSource = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'web-src\viewer.js')
if ($viewerSource -match 'https?://') { throw '3D 查看器不应在运行时加载远程脚本或模型。' }
if (-not $viewerSource.Contains("/^file:/i") -or -not $viewerSource.Contains('productId')) { throw '3D 查看器缺少资源与商品 ID 白名单校验。' }

$scanner = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'TongShang\Scanner\ScannerScreen.swift')
if (-not $scanner.Contains('DataScannerViewController') -or -not $scanner.Contains('SKUResolver')) { throw '扫码模块未接入 VisionKit 或 SKU Resolver。' }

$workflow = Get-Content -Raw -Encoding UTF8 (Join-Path $root '.github\workflows\ios.yml')
foreach ($required in @('runs-on: macos-15', 'xcodegen generate', 'xcodebuild', 'CODE_SIGNING_ALLOWED=NO')) {
    if (-not $workflow.Contains($required)) { throw "iOS 云构建工作流缺少：$required" }
}

Write-Output "iOS project validation passed ($($manifest.products.Count) products, $($manifest.products.Count * 2) 3D/AR assets)."
