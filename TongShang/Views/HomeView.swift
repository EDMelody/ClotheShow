import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @State private var category = "全部"
    @State private var scannerPresented = false
    @State private var scannedProduct: Product?

    private var categories: [String] { ["全部"] + Array(Set(store.products.map(\.category))).sorted() }
    private var visibleProducts: [Product] { category == "全部" ? store.products : store.products.filter { $0.category == category } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("NEW SEASON").font(.caption.bold()).tracking(2).foregroundStyle(Theme.coral)
                    Text("发现孩子的\n今日穿搭").font(.largeTitle.bold()).foregroundStyle(Theme.ink)
                }
                ScanHero { scannerPresented = true }
                Text("精选童装").font(.title3.bold())
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(categories, id: \.self) { item in
                            Button(item) { category = item }
                                .buttonStyle(.borderedProminent)
                                .tint(category == item ? Theme.ink : Color(.systemGray5))
                                .foregroundStyle(category == item ? .white : Theme.ink)
                                .clipShape(Capsule())
                        }
                    }
                }
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 18) {
                    ForEach(visibleProducts) { product in
                        NavigationLink(value: product) { ProductCard(product: product) }
                            .buttonStyle(.plain)
                    }
                }
            }.padding()
        }
        .background(Theme.cream.opacity(0.35))
        .navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
        .sheet(isPresented: $scannerPresented) {
            ScannerScreen { product in scannerPresented = false; scannedProduct = product }
        }
        .sheet(item: $scannedProduct) { product in NavigationStack { ProductDetailView(product: product) } }
    }
}

private struct ScanHero: View {
    let action: () -> Void
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("一扫即见\n立体新装").font(.title2.bold())
                Text("对准吊牌二维码，立即查看对应童装模型。").font(.caption).foregroundStyle(.white.opacity(0.7))
                Button("开始扫描  →", action: action).buttonStyle(.borderedProminent).tint(.white).foregroundStyle(Theme.ink)
            }
            Spacer()
            Image(systemName: "tshirt.fill").font(.system(size: 74)).foregroundStyle(Color(hex: "#F2CD72"))
        }
        .padding(22).foregroundStyle(.white).background(Theme.ink, in: RoundedRectangle(cornerRadius: 28))
    }
}

struct ProductCard: View {
    @EnvironmentObject private var store: AppStore
    let product: Product
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 24).fill(Color(hex: product.primaryColor.hex).opacity(0.18)).aspectRatio(0.86, contentMode: .fit)
                Image(systemName: product.category == "裤装" ? "figure.walk" : "tshirt.fill")
                    .resizable().scaledToFit().padding(34).foregroundStyle(Color(hex: product.primaryColor.hex))
                Button { store.toggleFavorite(product) } label: {
                    Image(systemName: store.isFavorite(product) ? "heart.fill" : "heart").padding(10).background(.thinMaterial, in: Circle())
                }.padding(8).foregroundStyle(Theme.coral)
            }
            Text(product.name).font(.subheadline.bold()).lineLimit(1)
            Text("\(product.sizes.first ?? "")–\(product.sizes.last ?? "") cm · \(product.material)").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
    }
}
