# 童裳 iOS

“扫描 SKU → 商品详情 → Three.js 3D → AR Quick Look”的可运行首版。工程内置 6 件示例商品及对应 GLB/USDZ，收藏与最近浏览只保存在本机，摄像头画面不保存、不上传。

## 立即在 iPhone 查看（免开发者账号）

1. Windows 与 iPhone 连接同一 Wi-Fi。
2. 在本目录运行 `powershell -ExecutionPolicy Bypass -File scripts/preview.ps1`。
3. 用 iPhone Safari 打开终端显示的地址。
4. 点 Safari 的“分享”→“添加到主屏幕”。

这是可添加到主屏幕的交互体验版，不能直接双击 HTML 安装。局域网 HTTP 适合快速查看；要启用 Service Worker 离线缓存，应把 `demo` 目录发布到 HTTPS 静态站点后再添加到主屏幕。

## 安装原生版到 iPhone

原生 iOS 签名和真机安装必须在 macOS + Xcode 上完成：

1. 安装 Xcode 16 与 XcodeGen（`brew install xcodegen`）。
2. 将本仓库复制或克隆到 Mac，进入目录后运行 `xcodegen generate`。
3. 打开 `TongShang.xcodeproj`，在 TongShang target 的 Signing & Capabilities 中选择你的 Team，并按需修改唯一 Bundle Identifier。
4. 用数据线连接 iPhone，解锁并信任电脑；在 Xcode 顶部选择该 iPhone，点击 Run。
5. 免费 Apple ID 签名通常需在手机的“设置 → 通用 → VPN 与设备管理”中信任开发者，且构建有效期有限；付费开发者账号可用于 TestFlight 或正式分发。

### 先用 GitHub 云端验证构建

仓库包含 `.github/workflows/ios.yml`。将代码推送到 GitHub 后，打开仓库的 **Actions → iOS Build → Run workflow**。该步骤使用 GitHub 的 macOS 15 + Xcode 16.4 环境生成工程、编译并运行单元测试，不需要 Apple 签名。构建通过后，再配置证书和 provisioning profile 生成真机 IPA。

## 构建与验证

```powershell
npm install
npm run build:assets
npm run test:web
powershell -ExecutionPolicy Bypass -File tests/validate_ios_project.ps1
```

在 Mac 上再执行：

```bash
xcodegen generate
xcodebuild -scheme TongShang -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

示例模型是用于验证流程的低多边形占位资产。正式发布前请按 `docs/TECHNICAL_PLAN.md` 的规格替换为品牌建模资产，并在目标真机验证比例、材质、加载速度和内存。
