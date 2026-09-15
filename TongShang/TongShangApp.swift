import SwiftUI

@main
struct TongShangApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .task { await store.loadProducts() }
        }
    }
}
