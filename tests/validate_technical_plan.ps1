$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$documentPath = Join-Path $repositoryRoot 'docs\TECHNICAL_PLAN.md'

if (-not (Test-Path -LiteralPath $documentPath -PathType Leaf)) {
    throw 'docs/TECHNICAL_PLAN.md 不存在。'
}

$content = Get-Content -LiteralPath $documentPath -Raw -Encoding UTF8
$requiredSections = @(
    '# 童装 3D 展示 iOS App 首版技术方案',
    '## 2. 首版技术边界',
    '## 3. 总体架构',
    '## 5. SKU 与商品数据设计',
    '## 7. 核心数据流程',
    '## 10. 隐私与安全',
    '## 11. 测试与验证',
    '## 12. 实施阶段'
)

foreach ($section in $requiredSections) {
    if (-not $content.Contains($section)) {
        throw "技术方案缺少必要章节：$section"
    }
}

$requiredTerms = @(
    'Three.js',
    'VisionKit',
    'AR Quick Look',
    'CLOTHE-0001',
    'modelGLB',
    'modelUSDZ',
    '不保存、不上传摄像头画面'
)

foreach ($term in $requiredTerms) {
    if (-not $content.Contains($term)) {
        throw "技术方案缺少必要内容：$term"
    }
}

if ($content -match 'TODO|TBD|待补充') {
    throw '技术方案仍包含未完成占位内容。'
}

Write-Output 'docs/TECHNICAL_PLAN.md validation passed.'
