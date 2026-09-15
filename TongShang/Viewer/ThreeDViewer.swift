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
        if let page = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Viewer") {
            webView.loadFileURL(page, allowingReadAccessTo: Bundle.main.bundleURL)
        } else { state = .failed("3D 查看器资源缺失") }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.pending = (product, color, autoRotate)
        guard context.coordinator.ready else { return }
        context.coordinator.sendPending()
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        @Binding var state: ViewerState
        weak var webView: WKWebView?
        var ready = false
        var pending: (Product, ProductColor, Bool)?
        init(state: Binding<ViewerState>) { _state = state }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any], let event = body["event"] as? String else { return }
            DispatchQueue.main.async {
                switch event {
                case "viewerReady": self.ready = true; self.sendPending()
                case "modelLoadStarted": self.state = .loading
                case "modelLoadSucceeded": self.state = .ready
                case "modelLoadFailed": self.state = .failed("模型加载失败，已显示商品图片替代。")
                default: break
                }
            }
        }

        func sendPending() {
            guard let (product, color, autoRotate) = pending else { return }
            let modelName = (product.modelGLB as NSString).deletingPathExtension
            guard let url = Bundle.main.url(forResource: modelName, withExtension: "glb", subdirectory: "Models") else {
                state = .failed("该商品 3D 模型未安装"); return
            }
            let payload: [String: Any] = ["url": url.absoluteString, "productId": product.id, "assetVersion": product.assetVersion, "color": color.hex, "autoRotate": autoRotate]
            guard let data = try? JSONSerialization.data(withJSONObject: payload), let json = String(data: data, encoding: .utf8) else { return }
            webView?.evaluateJavaScript("window.loadProduct(\(json))")
        }
    }
}
