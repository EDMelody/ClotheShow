import XCTest
@testable import TongShang

final class ProductTests: XCTestCase {
    private let json = """
    {"manifestVersion":1,"products":[{"id":"coat-001","sku":"CLOTHE-0001","name":"外套","category":"外套","summary":"简介","material":"棉","colors":[{"id":"blue","name":"蓝","hex":"#7FA5BD"}],"sizes":["90","100"],"thumbnail":"coat.svg","modelGLB":"coat.glb","modelUSDZ":"coat.usdz","assetVersion":1,"price":299}]}
    """

    func testManifestDecodesRequiredFields() throws {
        let manifest = try JSONDecoder().decode(ProductManifest.self, from: Data(json.utf8))
        XCTAssertEqual(manifest.manifestVersion, 1)
        XCTAssertEqual(manifest.products.first?.sku, "CLOTHE-0001")
        XCTAssertEqual(manifest.products.first?.modelUSDZ, "coat.usdz")
    }

    func testSKUNormalizationAndResolution() throws {
        let products = try JSONDecoder().decode(ProductManifest.self, from: Data(json.utf8)).products
        XCTAssertEqual(SKUResolver.normalize(" clothe-0001\n"), "CLOTHE-0001")
        XCTAssertEqual(SKUResolver.resolve("CLOTHE-0001", in: products)?.id, "coat-001")
        XCTAssertNil(SKUResolver.normalize("https://example.com"))
        XCTAssertNil(SKUResolver.normalize("CLOTHE-1"))
    }
}
