import Foundation

enum ProductRepositoryError: LocalizedError {
    case missingManifest, duplicateSKU(String), invalidSKU(String), emptyCatalog

    var errorDescription: String? {
        switch self {
        case .missingManifest: return "内置商品清单缺失。"
        case .duplicateSKU(let sku): return "商品清单包含重复 SKU：\(sku)"
        case .invalidSKU(let sku): return "商品 SKU 格式无效：\(sku)"
        case .emptyCatalog: return "商品清单为空。"
        }
    }
}

struct ProductRepository {
    private let bundle: Bundle
    init(bundle: Bundle = .main) { self.bundle = bundle }

    func loadBundledProducts() throws -> [Product] {
        guard let url = bundle.url(forResource: "products", withExtension: "json") else {
            throw ProductRepositoryError.missingManifest
        }
        let manifest = try JSONDecoder().decode(ProductManifest.self, from: Data(contentsOf: url))
        guard !manifest.products.isEmpty else { throw ProductRepositoryError.emptyCatalog }
        var seen = Set<String>()
        for product in manifest.products {
            guard SKUResolver.normalize(product.sku) != nil else { throw ProductRepositoryError.invalidSKU(product.sku) }
            guard seen.insert(product.sku).inserted else { throw ProductRepositoryError.duplicateSKU(product.sku) }
        }
        return manifest.products
    }
}
