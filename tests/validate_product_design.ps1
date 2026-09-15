$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$documentPath = Join-Path $repositoryRoot 'PRODUCT_DESIGN.md'

if (-not (Test-Path -LiteralPath $documentPath -PathType Leaf)) {
    throw 'PRODUCT_DESIGN.md 不存在。'
}

$content = Get-Content -LiteralPath $documentPath -Raw -Encoding UTF8
$requiredSections = @(
    '# 童装 3D 展示 iOS App 产品设计文档',
    '## 1. 产品概述',
    '## 3. 首版核心流程',
    '## 4. 主要功能',
    '## 6. 技术方向',
    '## 7. 首版验收标准',
    '## 8. 首版暂不包含'
)

foreach ($section in $requiredSections) {
    if (-not $content.Contains($section)) {
        throw "产品设计文档缺少必要章节：$section"
    }
}

$requiredTerms = @('Three.js', 'VisionKit', 'AR Quick Look', 'GLB', 'USDZ', '不保存、不上传')
foreach ($term in $requiredTerms) {
    if (-not $content.Contains($term)) {
        throw "产品设计文档缺少必要内容：$term"
    }
}

if ($content -match 'TODO|TBD|待补充') {
    throw '产品设计文档仍包含未完成占位内容。'
}

Write-Output 'PRODUCT_DESIGN.md validation passed.'
