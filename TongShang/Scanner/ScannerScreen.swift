import AVFoundation
import SwiftUI
import UIKit
import VisionKit

struct ScannerScreen: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let onResolved: (Product) -> Void
    @State private var permission: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var manualSKU = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                scannerContent
                VStack(spacing: 10) {
                    TextField("手动输入，例如 CLOTHE-0001", text: $manualSKU)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled().textFieldStyle(.roundedBorder)
                    Button("查找商品") { resolve(manualSKU) }.buttonStyle(.borderedProminent).tint(Theme.coral).frame(maxWidth: .infinity)
                }.padding(.horizontal)
                if let errorMessage { Text(errorMessage).font(.footnote).foregroundStyle(.red) }
            }
            .navigationTitle("扫描童装吊牌")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("关闭") { dismiss() } }
            .task { await requestPermissionIfNeeded() }
        }
    }

    @ViewBuilder private var scannerContent: some View {
        if DataScannerViewController.isSupported && DataScannerViewController.isAvailable && permission == .authorized {
            DataScannerView(onCode: resolve)
                .clipShape(RoundedRectangle(cornerRadius: 24)).padding().overlay { RoundedRectangle(cornerRadius: 24).stroke(Theme.coral, lineWidth: 3).padding(42) }
        } else if permission == .denied || permission == .restricted {
            VStack(spacing: 14) {
                ContentUnavailableView("无法使用相机", systemImage: "camera.fill", description: Text("请在系统设置中允许相机权限，或在下方手动输入 SKU。"))
                Button("打开系统设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }.buttonStyle(.bordered)
            }.frame(maxHeight: .infinity)
        } else {
            ContentUnavailableView("此设备不支持实时扫码", systemImage: "viewfinder", description: Text("你仍可在下方手动输入 SKU。"))
                .frame(maxHeight: .infinity)
        }
    }

    private func resolve(_ value: String) {
        guard let product = store.product(for: value) else {
            errorMessage = SKUResolver.normalize(value) == nil ? "请输入 CLOTHE-0001 格式的商品编码。" : "没有找到对应商品，请重新扫描或检查编码。"
            return
        }
        onResolved(product)
    }

    private func requestPermissionIfNeeded() async {
        guard permission == .notDetermined else { return }
        _ = await AVCaptureDevice.requestAccess(for: .video)
        permission = AVCaptureDevice.authorizationStatus(for: .video)
    }
}

private struct DataScannerView: UIViewControllerRepresentable {
    let onCode: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr, .ean13, .ean8, .code128])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        try? controller.startScanning()
        return controller
    }
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) { uiViewController.stopScanning() }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCode: (String) -> Void
        private var delivered = false
        init(onCode: @escaping (String) -> Void) { self.onCode = onCode }
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !delivered else { return }
            for item in addedItems {
                if case .barcode(let barcode) = item, let value = barcode.payloadStringValue {
                    delivered = true; onCode(value); return
                }
            }
        }
    }
}
