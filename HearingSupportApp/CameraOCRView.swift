//
//  CameraOCRView.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/08/20.
//

import SwiftUI
import VisionKit
import Vision

// OCRで認識した単語とその位置（Vision正規化座標・原点は左下）
struct ScannedToken: Equatable {
    let text: String
    let boundingBox: CGRect
}

// 撮影した1ページ分の認識結果
struct ScannedPage: Equatable {
    let text: String
    let tokens: [ScannedToken]
}

struct CameraOCRView: UIViewControllerRepresentable {
    @Binding var scannedPages: [ScannedPage]
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let cameraViewController = VNDocumentCameraViewController()
        cameraViewController.delegate = context.coordinator
        return cameraViewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: CameraOCRView

        init(_ parent: CameraOCRView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount >= 1 else {
                parent.isPresented = false
                return
            }

            let images = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            recognizeText(from: images)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isPresented = false
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.isPresented = false
        }

        private func recognizeText(from images: [UIImage]) {
            // OCRは時間がかかるためバックグラウンドで実行する
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                var pages: [ScannedPage] = []

                for image in images {
                    guard let cgImage = image.cgImage else { continue }

                    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    let request = VNRecognizeTextRequest()
                    request.recognitionLevel = .accurate
                    request.recognitionLanguages = ["ja", "en"]

                    do {
                        try requestHandler.perform([request])
                        let observations = request.results ?? []

                        var lineTexts: [String] = []
                        var tokens: [ScannedToken] = []
                        for observation in observations {
                            guard let candidate = observation.topCandidates(1).first else { continue }
                            lineTexts.append(candidate.string)
                            tokens.append(contentsOf: Coordinator.tokens(from: candidate))
                        }
                        pages.append(ScannedPage(text: lineTexts.joined(separator: "\n"), tokens: tokens))
                    } catch {
                        print("OCR Request Error: \(error)")
                    }
                }

                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.parent.isPresented = false
                    self.parent.scannedPages = pages
                }
            }
        }

        // 認識した行を空白区切りの単語に分け、それぞれの位置を取得する
        // （オージオグラムのグラフ解析で記号や軸ラベルの座標が必要になる）
        private static func tokens(from candidate: VNRecognizedText) -> [ScannedToken] {
            let string = candidate.string
            var tokens: [ScannedToken] = []
            var index = string.startIndex

            while index < string.endIndex {
                if string[index].isWhitespace {
                    index = string.index(after: index)
                    continue
                }
                var end = index
                while end < string.endIndex && !string[end].isWhitespace {
                    end = string.index(after: end)
                }
                if let rectangle = try? candidate.boundingBox(for: index..<end) {
                    tokens.append(ScannedToken(text: String(string[index..<end]), boundingBox: rectangle.boundingBox))
                }
                index = end
            }
            return tokens
        }
    }
}
