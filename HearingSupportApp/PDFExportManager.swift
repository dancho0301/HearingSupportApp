import UIKit
import SwiftUI
import UniformTypeIdentifiers

class PDFExportManager: NSObject {
    static let shared = PDFExportManager()
    
    private override init() {
        super.init()
    }
    
    @MainActor
    func exportRecordAsPDF(_ record: Record) {
        // A4サイズ
        let pageSize = CGSize(width: 595, height: 842)

        // PDFデータを生成
        guard let pdfData = generatePDFData(for: record, size: pageSize) else {
            print("PDF生成に失敗しました")
            return
        }

        // ファイル名を生成（パス区切り等の不正文字を除去）
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: record.date)
        let safeTitle = Self.sanitizeFileName(record.title)
        let fileName = "聴力検査記録_\(safeTitle)_\(dateString).pdf"

        // PDFを共有
        sharePDF(data: pdfData, fileName: fileName)
    }

    /// ファイル名に使えない文字（/ : など）を除去・置換する
    private static func sanitizeFileName(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|\n\r\t")
        let cleaned = name.components(separatedBy: invalid).joined(separator: "_")
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "記録" : trimmed
    }

    @MainActor
    private func generatePDFData(for record: Record, size: CGSize) -> Data? {
        // SwiftUI ビューはウィンドウに未アタッチだと drawHierarchy(afterScreenUpdates:)
        // で白紙になることがあるため、ImageRenderer（iOS16+）でレンダリングする。
        let pdfView = PrintableRecordView(record: record)
            .frame(width: size.width, height: size.height)
            .background(Color.white)

        let renderer = ImageRenderer(content: pdfView)
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        // PDFは論理ポイント基準で出力する
        renderer.scale = 1.0

        let pdfMetaData = [
            kCGPDFContextCreator: "おみみ手帳",
            kCGPDFContextTitle: "聴力検査記録"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(origin: .zero, size: size)
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        var rendered = false
        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(pageRect)

            renderer.render { _, render in
                rendered = true
                render(context.cgContext)
            }
        }
        return rendered ? data : nil
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