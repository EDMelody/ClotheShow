import Foundation

struct ProductManifest: Codable {
    let manifestVersion: Int
    let products: [Product]
}

struct Product: Codable, Identifiable, Hashable {
    let id: String
    let sku: String
    let name: String
    let category: String
    let summary: String
    let material: String
    let colors: [ProductColor]
    let sizes: [String]
    let thumbnail: String
    let modelGLB: String
    let modelUSDZ: String
    let assetVersion: Int
    let price: Int

    var sizeText: String { sizes.joined(separator: " / ") }
    var primaryColor: ProductColor { colors.first ?? .init(id: "default", name: "默认", hex: "#8AA59D") }
}

struct ProductColor: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let hex: String
}

enum SKUResolver {
    private static let pattern = /^CLOTHE-\d{4}$/

    static func normalize(_ raw: String) -> String? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return value.wholeMatch(of: pattern) == nil ? nil : value
    }

    static func resolve(_ raw: String, in products: [Product]) -> Product? {
        guard let sku = normalize(raw) else { return nil }
        return products.first { $0.sku == sku }
    }
}
