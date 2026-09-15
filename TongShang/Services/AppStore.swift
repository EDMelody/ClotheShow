import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var favoriteIDs: Set<String>
    @Published private(set) var recentIDs: [String]
    @Published var loadError: String?

    private let defaults: UserDefaults
    private let repository: ProductRepository
    private let favoriteKey = "favoriteProductIDs"
    private let recentKey = "recentProductIDs"

    init(defaults: UserDefaults = .standard, repository: ProductRepository = .init()) {
        self.defaults = defaults
        self.repository = repository
        favoriteIDs = Set(defaults.stringArray(forKey: favoriteKey) ?? [])
        recentIDs = defaults.stringArray(forKey: recentKey) ?? []
    }

    func loadProducts() async {
        do { products = try repository.loadBundledProducts(); loadError = nil }
        catch { loadError = error.localizedDescription }
    }

    func product(for rawSKU: String) -> Product? { SKUResolver.resolve(rawSKU, in: products) }
    func isFavorite(_ product: Product) -> Bool { favoriteIDs.contains(product.id) }

    func toggleFavorite(_ product: Product) {
        if favoriteIDs.contains(product.id) { favoriteIDs.remove(product.id) }
        else { favoriteIDs.insert(product.id) }
        defaults.set(Array(favoriteIDs).sorted(), forKey: favoriteKey)
    }

    func recordVisit(_ product: Product) {
        recentIDs.removeAll { $0 == product.id }
        recentIDs.insert(product.id, at: 0)
        recentIDs = Array(recentIDs.prefix(12))
        defaults.set(recentIDs, forKey: recentKey)
    }

    var favorites: [Product] { products.filter { favoriteIDs.contains($0.id) } }
    var recents: [Product] { recentIDs.compactMap { id in products.first { $0.id == id } } }

    func clearPersonalData() {
        favoriteIDs.removeAll(); recentIDs.removeAll()
        defaults.removeObject(forKey: favoriteKey); defaults.removeObject(forKey: recentKey)
    }
}
