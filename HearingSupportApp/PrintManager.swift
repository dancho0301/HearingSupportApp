import UIKit
import SwiftUI

class PrintManager: NSObject, UIPrintInteractionControllerDelegate {
    static let shared = PrintManager()
    
    private override init() {
        super.init()
    }
    
    func printRecord(_ record: Record) {
        let printController = UIPrintInteractionController.shared
        
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = "聴力検査記録 - \(record.title)"
        printController.printInfo = printInfo
        
        // 印刷用のビューを生成
        let printView = PrintableRecordView(record: record)
        let hostingController = UIHostingController(rootView: printView)
        
        // ビューのサイズを設定
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 595, height: 842) // A4サイズ
        
        printController.printingItem = hostingController.view.asImage()
        printController.delegate = self
        
        // 印刷ダイアログを表示
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let _ = windowScene.windows.first {
            printController.present(animated: true) { controller, completed, error in
                if let error = error {
                    print("印刷エラー: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - UIPrintInteractionControllerDelegate
    
    func printInteractionControllerParentViewController(_ printInteractionController: UIPrintInteractionController) -> UIViewController? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }
}