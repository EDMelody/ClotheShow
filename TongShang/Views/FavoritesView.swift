import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if store.favorites.isEmpty {
                    ContentUnavailableView("还没有收藏", systemImage: "heart", description: Text("在商品卡片或详情页点击爱心，喜欢的款式会出现在这里。"))
                        .frame(maxWidth: .infinity, minHeight: 280)
                } else {
                    section("我的收藏", products: store.favorites)
                }
                if !store.recents.isEmpty { section("最近浏览", products: store.recents) }
            }.padding()
        }
        .navigationTitle("收藏")
        .toolbar { Button("设置", systemImage: "gearshape") { showSettings = true } }
        .navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    @ViewBuilder private func section(_ title: String, products: [Product]) -> some View {
        Text(title).font(.title2.bold())
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 18) {
            ForEach(products) { product in NavigationLink(value: product) { ProductCard(product: product) }.buttonStyle(.plain) }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false
    var body: some View {
        NavigationStack {
            List {
                Section("隐私") {
                    Label("扫码仅在设备本地识别", systemImage: "lock.shield")
                    Text("应用不会保存或上传摄像头画面及儿童面部数据。").font(.footnote).foregroundStyle(.secondary)
                }
                Section("本机数据") {
                    Button("清除收藏与浏览记录", role: .destructive) { confirmClear = true }
                }
                Section("关于") { LabeledContent("版本", value: "1.0.0") }
            }
            .navigationTitle("设置")
            .toolbar { Button("完成") { dismiss() } }
            .confirmationDialog("确认清除本机数据？", isPresented: $confirmClear) {
                Button("清除", role: .destructive) { store.clearPersonalData() }
            }
        }
    }
}
