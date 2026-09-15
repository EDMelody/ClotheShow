import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selection = 0
    @State private var scannerPresented = false
    @State private var scannedProduct: Product?

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { HomeView() }
                .tabItem { Label("首页", systemImage: "house") }.tag(0)
            Color.clear
                .tabItem { Label("扫一扫", systemImage: "viewfinder") }.tag(1)
            NavigationStack { FavoritesView() }
                .tabItem { Label("收藏", systemImage: "heart") }.tag(2)
        }
        .tint(Theme.coral)
        .onChange(of: selection) { _, value in
            if value == 1 { scannerPresented = true; selection = 0 }
        }
        .sheet(isPresented: $scannerPresented) {
            ScannerScreen { product in
                scannerPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { scannedProduct = product }
            }
        }
        .sheet(item: $scannedProduct) { product in
            NavigationStack { ProductDetailView(product: product) }
        }
        .overlay {
            if let error = store.loadError {
                ContentUnavailableView("商品加载失败", systemImage: "exclamationmark.triangle", description: Text(error))
                    .padding().background(.regularMaterial)
            }
        }
    }
}

enum Theme {
    static let ink = Color(red: 0.12, green: 0.17, blue: 0.16)
    static let coral = Color(red: 0.93, green: 0.42, blue: 0.31)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.91)
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted), radix: 16) ?? 0x8AA59D
        self.init(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
    }
}
