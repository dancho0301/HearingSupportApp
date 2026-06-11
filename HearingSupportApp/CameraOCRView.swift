//
//  CameraOCRView.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/08/20.
//

import SwiftUI
import VisionKit
import Vision

struct CameraOCRView: UIViewControllerRepresentable {
    @Binding var recognizedText: String
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
                var pageTexts: [String] = []

                for image in images {
                    guard let cgImage = image.cgImage else { continue }

                    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    let request = VNRecognizeTextRequest()
                    request.recognitionLevel = .accurate
                    request.recognitionLanguages = ["ja", "en"]

                    do {
                        try requestHandler.perform([request])
                        if let observations = request.results {
                            let recognizedStrings = observations.compactMap { observation in
                                observation.topCandidates(1).first?.string
                            }
                            if !recognizedStrings.isEmpty {
                                pageTexts.append(recognizedStrings.joined(separator: "\n"))
                            }
                        }
                    } catch {
                        print("OCR Request Error: \(error)")
                    }
                }

                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.parent.isPresented = false
                    self.parent.recognizedText = pageTexts.joined(separator: "\n")
                }
            }
        }
    }
}