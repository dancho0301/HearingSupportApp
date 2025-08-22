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
            
            let image = scan.imageOfPage(at: 0)
            recognizeText(from: image)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isPresented = false
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.isPresented = false
        }
        
        private func recognizeText(from image: UIImage) {
            guard let cgImage = image.cgImage else {
                parent.isPresented = false
                return
            }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { [weak self] request, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.parent.isPresented = false
                    
                    if let error = error {
                        print("OCR Error: \(error)")
                        return
                    }
                    
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        return
                    }
                    
                    let recognizedStrings = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }
                    
                    self.parent.recognizedText = recognizedStrings.joined(separator: "\n")
                }
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ja", "en"]
            
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.parent.isPresented = false
                    print("OCR Request Error: \(error)")
                }
            }
        }
    }
}