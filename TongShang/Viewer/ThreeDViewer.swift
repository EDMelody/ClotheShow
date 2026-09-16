import SwiftUI
import WebKit

enum ViewerState: Equatable { case loading, ready, failed(String) }

struct ThreeDViewer: UIViewRepresentable {
    let product: Product
    let color: ProductColor
    let autoRotate: Bool
    @Binding var state: ViewerState

    func makeCoordinator() -> Coordinator { Coordinator(state: $state) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "viewer")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false; webView.backgroundColor = .clear; webView.scrollView.isScrollEnabled = false
        context.coordinator.webView = webView
        webView.navigationDelegate = context.coordinator
        if let page = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Viewer") {
            context.coordinator.pageURL = page
            webView.loadFileURL(page, allowingReadAccessTo: Bundle.main.bundleURL)
        } else { context.coordinator.setState(.failed("3D 查看器资源缺失")) }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(product: product, color: color, autoRotate: autoRotate)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "viewer")
        coordinator.invalidate()
    }

    private struct ViewerCommand: Equatable {
        let url: String
        let productId: String
        let assetVersion: Int
        let color: String
        let autoRotate: Bool

        var payload: [String: Any] {
            ["url": url, "productId": productId, "assetVersion": assetVersion, "color": color, "autoRotate": autoRotate]
        }
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        @Binding var state: ViewerState
        weak var webView: WKWebView?
        var pageURL: URL?
        var ready = false
        private var pendingCommand: ViewerCommand?
        private var lastSentCommand: ViewerCommand?
        private var recoveryAttempts = 0
        private var isActive = true

        init(state: Binding<ViewerState>) { _state = state }

        func update(product: Product, color: ProductColor, autoRotate: Bool) {
            let modelName = (product.modelGLB as NSString).deletingPathExtension
            guard let url = Bundle.main.url(forResource: modelName, withExtension: "glb", subdirectory: "Models") else {
                setState(.failed("该商品 3D 模型未安装")); return
            }
            pendingCommand = ViewerCommand(
                url: url.absoluteString,
                productId: product.id,
                assetVersion: product.assetVersion,
                color: color.hex,
                autoRotate: autoRotate
            )
            sendPending()
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any], let event = body["event"] as? String else { return }
            DispatchQueue.main.async {
                guard self.isActive else { return }
                switch event {
                case "viewerReady": self.ready = true; self.sendPending()
                case "modelLoadStarted": self.setState(.loading)
                case "modelLoadSucceeded": self.setState(.ready)
                case "modelLoadFailed": self.setState(.failed("模型加载失败，请返回后重试。"))
                default: break
                }
            }
        }

        func sendPending() {
            guard isActive, ready, let command = pendingCommand, command != lastSentCommand else { return }
            guard let data = try? JSONSerialization.data(withJSONObject: command.payload),
                  let json = String(data: data, encoding: .utf8) else { return }
            lastSentCommand = command
            // Discard the async function's Promise so WKWebView only has to bridge a null result.
            webView?.evaluateJavaScript("window.loadProduct(\(json)); null;") { [weak self] _, error in
                guard let self, let error else { return }
                self.lastSentCommand = nil
                self.setState(.failed("3D 查看器暂时不可用：\(error.localizedDescription)"))
            }
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            ready = false
            lastSentCommand = nil
            guard recoveryAttempts == 0, let pageURL else {
                setState(.failed("3D 查看器已停止，请返回后重试。")); return
            }
            recoveryAttempts += 1
            setState(.loading)
            webView.loadFileURL(pageURL, allowingReadAccessTo: Bundle.main.bundleURL)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            setState(.failed("3D 查看器页面加载失败。"))
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            setState(.failed("3D 查看器页面加载失败。"))
        }

        func setState(_ newState: ViewerState) {
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isActive, self.state != newState else { return }
                self.state = newState
            }
        }

        func invalidate() {
            isActive = false
            ready = false
            pendingCommand = nil
            lastSentCommand = nil
            webView = nil
        }
    }
}
