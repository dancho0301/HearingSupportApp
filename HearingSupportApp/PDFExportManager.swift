import UIKit
import SwiftUI
import UniformTypeIdentifiers

class PDFExportManager: NSObject {
    static let shared = PDFExportManager()
    
    private override init() {
        super.init()
    }
    
    func exportRecordAsPDF(_ record: Record) {
        // PDF用のビューを生成
        let pdfView = PrintableRecordView(record: record)
        let hostingController = UIHostingController(rootView: pdfView)
        
        // ビューのサイズを設定（A4サイズ）
        let pageSize = CGSize(width: 595, height: 842)
        hostingController.view.frame = CGRect(origin: .zero, size: pageSize)
        
        // ビューを強制的にレイアウト
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        // 背景色を白に設定
        hostingController.view.backgroundColor = UIColor.white
        
        // PDFデータを生成
        guard let pdfData = generatePDFData(from: hostingController.view, size: pageSize) else {
            print("PDF生成に失敗しました")
            return
        }
        
        // ファイル名を生成
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: record.date)
        let fileName = "聴力検査記録_\(record.title)_\(dateString).pdf"
        
        // PDFを共有
        sharePDF(data: pdfData, fileName: fileName)
    }
    
    private func generatePDFData(from view: UIView, size: CGSize) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "おみみ手帳",
            kCGPDFContextTitle: "聴力検査記録"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // A4サイズのPDFレンダラーを作成
        let pageRect = CGRect(origin: .zero, size: size)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            // 背景を白で塗りつぶし
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(pageRect)
            
            // ビューを描画前に再度レンダリング
            view.drawHierarchy(in: pageRect, afterScreenUpdates: true)
        }
    }
    
    private func sharePDF(data: Data, fileName: String) {
        // 一時ファイルを作成
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            
            // UIActivityViewControllerで共有
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            // メインスレッドで実行
            DispatchQueue.main.async {
                // 現在のウィンドウシーンを取得
                guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                      let window = windowScene.windows.first(where: \.isKeyWindow),
                      let rootViewController = window.rootViewController else {
                    print("ビューコントローラーが見つかりません")
                    return
                }
                
                // 最上位のビューコントローラーを取得
                var topViewController = rootViewController
                while let presentedViewController = topViewController.presentedViewController {
                    topViewController = presentedViewController
                }
                
                // iPadでの表示設定
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = topViewController.view
                    popover.sourceRect = CGRect(x: topViewController.view.bounds.midX, y: topViewController.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                // アクティビティ完了後の処理
                activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                    if let error = error {
                        print("PDF共有エラー: \(error.localizedDescription)")
                    } else if completed {
                        print("PDF共有完了")
                    }
                    
                    // 一時ファイルを削除
                    try? FileManager.default.removeItem(at: tempURL)
                }
                
                // 共有ダイアログを表示
                topViewController.present(activityVC, animated: true)
            }
            
        } catch {
            print("PDF保存エラー: \(error.localizedDescription)")
        }
    }
}