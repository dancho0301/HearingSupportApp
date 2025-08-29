//
//  TestResultInputView.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/06/01.
//


import SwiftUI

struct TestResultInputView: View {
    @Binding var result: TestResultInput
    @State private var showingCamera = false
    @State private var recognizedText = ""
    @State private var showingOCRResult = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Picker("耳", selection: $result.ear) {
                    ForEach(result.earOptions, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                Picker("条件", selection: $result.condition) {
                    ForEach(result.conditionOptions, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
            }
            
            /*
            .alert("OCR認識結果", isPresented: $showingOCRResult) {
                Button("OK") { recognizedText = "" }
            } message: {
                Text("認識されたテキスト:\n\(recognizedText)")
            }
            */
            if result.ear == "右耳のみ" {
                ForEach(0..<result.freqs.count, id: \.self) { i in
                    HStack {
                        Text(result.freqs[i])
                            .frame(width: 60, alignment: .leading)
                        VStack(alignment: .leading) {
                            Slider(
                                value: Binding(
                                    get: { Double(result.thresholdsRight[i] ?? 0) },
                                    set: { result.thresholdsRight[i] = Int($0) }
                                ),
                                in: 0...120, step: 5
                            )
                            Text("\(result.thresholdsRight[i] ?? 0) dB")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            } else if result.ear == "左耳のみ" {
                ForEach(0..<result.freqs.count, id: \.self) { i in
                    HStack {
                        Text(result.freqs[i])
                            .frame(width: 60, alignment: .leading)
                        VStack(alignment: .leading) {
                            Slider(
                                value: Binding(
                                    get: { Double(result.thresholdsLeft[i] ?? 0) },
                                    set: { result.thresholdsLeft[i] = Int($0) }
                                ),
                                in: 0...120, step: 5
                            )
                            Text("\(result.thresholdsLeft[i] ?? 0) dB")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
            } else {
                // 両耳時は1本のみ
                ForEach(0..<result.freqs.count, id: \.self) { i in
                    HStack {
                        Text(result.freqs[i])
                            .frame(width: 60, alignment: .leading)
                        VStack(alignment: .leading) {
                            Slider(
                                value: Binding(
                                    get: { Double(result.thresholdsBoth[i] ?? 0) },
                                    set: { result.thresholdsBoth[i] = Int($0) }
                                ),
                                in: 0...120, step: 5
                            )
                            Text("\(result.thresholdsBoth[i] ?? 0) dB")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            Divider()
        }
        .padding(.vertical, 5)
    }
    
    private func parseOCRResult(_ text: String) {
        if let parsedResult = HearingTestParser.parseOCRText(text) {
            result.ear = parsedResult.ear
            result.condition = parsedResult.condition
            result.thresholdsRight = parsedResult.thresholdsRight
            result.thresholdsLeft = parsedResult.thresholdsLeft
            result.thresholdsBoth = parsedResult.thresholdsBoth
        }
    }
}
