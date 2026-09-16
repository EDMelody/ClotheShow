$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$requiredFiles = @(
    'project.yml', 'TongShang\Info.plist', 'TongShang\TongShangApp.swift',
    'TongShang\Resources\products.json', 'TongShang\Resources\Viewer\index.html',
    'TongShang\Resources\Viewer\viewer.bundle.js', 'TongShangTests\ProductTests.swift',
    '.github\workflows\ios.yml', 'scripts\install-apple-prerequisites.ps1',
    'scripts\run-apple-prerequisite-installer.cmd'
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
foreach ($required in @('payload.url === loadingURL', 'generation !== loadGeneration', 'disposeModel(model)', 'function frameModel(root)')) {
    if (-not $viewerSource.Contains($required)) { throw "3D 查看器缺少稳定性保护：$required" }
}
if ($viewerSource.Contains('material.clone()')) { throw '3D 查看器不应在每次颜色更新时克隆材质。' }

$viewerBridge = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'TongShang\Viewer\ThreeDViewer.swift')
foreach ($required in @('lastSentCommand', 'dismantleUIView', 'webViewWebContentProcessDidTerminate')) {
    if (-not $viewerBridge.Contains($required)) { throw "iOS 3D 桥接缺少生命周期保护：$required" }
}
if (-not $viewerBridge.Contains('window.loadProduct(\(json)); null;')) {
    throw 'iOS 3D 桥接必须丢弃异步 Promise，避免 WKWebView 误报返回值错误。'
}

$arQuickLook = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'TongShang\Viewer\ARQuickLookView.swift')
foreach ($required in @('UINavigationController', 'UIBarButtonItem', 'title: "返回"', '@objc func close()', 'isPresented = false')) {
    if (-not $arQuickLook.Contains($required)) { throw "AR 预览缺少可见的返回能力：$required" }
}

$homeView = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'TongShang\Views\HomeView.swift')
if (-not $homeView.Contains('.aspectRatio(1, contentMode: .fit)') -or -not $homeView.Contains('.padding(.bottom, 28)')) {
    throw '首页商品卡片比例或底部安全间距未固定。'
}
$detailView = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'TongShang\Views\ProductDetailView.swift')
if ($detailView.Contains('.ignoresSafeArea(edges: .top)') -or -not $detailView.Contains('Label("返回"')) {
    throw '详情页顶部安全区或中文返回按钮配置不正确。'
}

$scanner = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'TongShang\Scanner\ScannerScreen.swift')
if (-not $scanner.Contains('DataScannerViewController') -or -not $scanner.Contains('SKUResolver')) { throw '扫码模块未接入 VisionKit 或 SKU Resolver。' }

$workflow = Get-Content -Raw -Encoding UTF8 (Join-Path $root '.github\workflows\ios.yml')
foreach ($required in @(
    'runs-on: macos-15', 'xcodegen generate', 'xcodebuild', 'CODE_SIGNING_ALLOWED=NO',
    "-destination 'generic/platform=iOS'", 'Release-iphoneos/TongShang.app',
    'TongShang-unsigned.ipa', 'name: TongShang-unsigned-ipa', 'ipa-entries.txt',
    'Payload/TongShang.app/products.json', 'Payload/TongShang.app/zh-Hans.lproj/InfoPlist.strings',
    'Payload/TongShang.app/Viewer/index.html',
    "'^Payload/TongShang.app/Models/.+\.glb`$'", "'^Payload/TongShang.app/Models/.+\.usdz`$'"
)) {
    if (-not $workflow.Contains($required)) { throw "iOS 云构建工作流缺少：$required" }
}

$projectSpec = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'project.yml')
foreach ($required in @(
    'buildPhase: resources', 'destination: resources', 'subpath: Viewer', 'subpath: Models',
    'CFBundleDisplayName: TongShang', 'CFBundleName: TongShang',
    'CFBundleShortVersionString: 1.0.2', 'CFBundleVersion: 3',
    'PRODUCT_BUNDLE_IDENTIFIER: com.edmelody.tongshang.viewer', 'TongShang/Resources/zh-Hans.lproj',
    'MARKETING_VERSION: 1.0.2', 'CURRENT_PROJECT_VERSION: 3'
)) {
    if (-not $projectSpec.Contains($required)) { throw "XcodeGen 工程未正确声明打包资源：$required" }
}
if ($projectSpec -notmatch '(?ms)TongShang:\s+type: application.*?settings:\s+base:.*?MARKETING_VERSION: 1\.0\.2\s+CURRENT_PROJECT_VERSION: 3') {
    throw '应用 target 未配置 1.0.2 (3) 版本号。'
}
$localizedInfo = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'TongShang\Resources\zh-Hans.lproj\InfoPlist.strings')
if (-not $localizedInfo.Contains('"CFBundleDisplayName" = "童裳";')) {
    throw '简体中文桌面名称本地化缺失。'
}

$launcher = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scripts\run-apple-prerequisite-installer.cmd')
foreach ($required in @('fltmc', '-Verb RunAs', 'install-apple-prerequisites.ps1', 'E:\iTunes', 'E:\iCloud')) {
    if (-not $launcher.Contains($required)) { throw "Apple 安装启动器缺少：$required" }
}

$appleInstaller = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scripts\install-apple-prerequisites.ps1')
foreach ($required in @(
    'ConvertTo-MsiArgument', "-ArgumentList (`$arguments -join ' ')", 'Write-Host "Installing',
    'AppleApplicationSupport.msi', 'AppleApplicationSupport64.msi', 'Bonjour64.msi',
    'PendingFileRenameOperations', 'restart Windows and run this installer again'
)) {
    if (-not $appleInstaller.Contains($required)) { throw "Apple 安装脚本缺少安全参数处理或进度提示：$required" }
}
if ($appleInstaller.Contains("Join-Path `$icloudInstaller 'Bonjour.msi'")) {
    throw 'Apple 安装脚本不应在 64 位 Windows 上运行仅适用于 32 位系统的 Bonjour.msi。'
}

Write-Output "iOS project validation passed ($($manifest.products.Count) products, $($manifest.products.Count * 2) 3D/AR assets)."
