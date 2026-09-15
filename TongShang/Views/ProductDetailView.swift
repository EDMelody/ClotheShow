import SwiftUI

struct ProductDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let product: Product
    @State private var selectedColor: ProductColor
    @State private var autoRotate = true
    @State private var viewerState: ViewerState = .loading
    @State private var showAR = false
    @State private var arError: String?

    init(product: Product) {
        self.product = product
        _selectedColor = State(initialValue: product.primaryColor)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ZStack(alignment: .bottom) {
                    ThreeDViewer(product: product, color: selectedColor, autoRotate: autoRotate, state: $viewerState)
                        .frame(height: 390)
                        .background(Color(hex: selectedColor.hex).opacity(0.12))
                    viewerOverlay
                    HStack {
                        Label("拖动旋转 · 双指缩放", systemImage: "hand.draw").font(.caption)
                        Spacer()
                        Button { autoRotate.toggle() } label: { Image(systemName: autoRotate ? "pause.fill" : "arrow.clockwise") }
                    }.padding(12).background(.thinMaterial)
                }
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading) {
                            Text(product.name).font(.title.bold())
                            Text(product.summary).foregroundStyle(.secondary)
                        }
                        Spacer(); Text("¥\(product.price)").font(.title3.bold()).foregroundStyle(Theme.coral)
                    }
                    Text("颜色").font(.headline)
                    HStack {
                        ForEach(product.colors) { color in
                            Button { selectedColor = color } label: {
                                Circle().fill(Color(hex: color.hex)).frame(width: 34, height: 34)
                                    .overlay(Circle().stroke(Theme.ink, lineWidth: selectedColor == color ? 3 : 0).padding(-4))
                                    .accessibilityLabel(color.name)
                            }.padding(5)
                        }
                    }
                    LabeledContent("尺码", value: product.sizeText)
                    LabeledContent("材质", value: product.material)
                    Button { openAR() } label: { Label("在现实环境中查看", systemImage: "arkit").frame(maxWidth: .infinity) }
                        .buttonStyle(.borderedProminent).controlSize(.large).tint(Theme.coral)
                }.padding(.horizontal)
            }
        }
        .ignoresSafeArea(edges: .top)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { store.toggleFavorite(product) } label: { Image(systemName: store.isFavorite(product) ? "heart.fill" : "heart") }
            }
        }
        .onAppear { store.recordVisit(product) }
        .sheet(isPresented: $showAR) { ARQuickLookView(fileURL: arURL) }
        .alert("AR 预览不可用", isPresented: Binding(get: { arError != nil }, set: { if !$0 { arError = nil } })) {
            Button("知道了") { arError = nil }
        } message: { Text(arError ?? "请继续使用普通 3D 预览。") }
    }

    @ViewBuilder private var viewerOverlay: some View {
        switch viewerState {
        case .loading: ProgressView("正在加载 3D 模型…").padding().background(.regularMaterial, in: Capsule())
        case .failed(let message):
            VStack { Image(systemName: "tshirt.fill").font(.system(size: 80)); Text(message).font(.caption) }
                .foregroundStyle(Color(hex: selectedColor.hex))
        case .ready: EmptyView()
        }
    }

    private var arURL: URL? {
        let name = (product.modelUSDZ as NSString).deletingPathExtension
        return Bundle.main.url(forResource: name, withExtension: "usdz", subdirectory: "Models")
    }

    private func openAR() {
        guard arURL != nil else { arError = "该商品的 AR 模型尚未随应用安装。"; return }
        showAR = true
    }
}
