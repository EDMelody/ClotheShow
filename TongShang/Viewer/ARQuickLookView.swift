import QuickLook
import SwiftUI

struct ARQuickLookView: UIViewControllerRepresentable {
    let fileURL: URL?
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator { Coordinator(fileURL: fileURL, isPresented: $isPresented) }

    func makeUIViewController(context: Context) -> UINavigationController {
        let preview = QLPreviewController()
        preview.dataSource = context.coordinator
        preview.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "返回",
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.close)
        )
        return UINavigationController(rootViewController: preview)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let fileURL: URL?
        @Binding private var isPresented: Bool

        init(fileURL: URL?, isPresented: Binding<Bool>) {
            self.fileURL = fileURL
            _isPresented = isPresented
        }

        @objc func close() { isPresented = false }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { fileURL == nil ? 0 : 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem { fileURL! as NSURL }
    }
}
