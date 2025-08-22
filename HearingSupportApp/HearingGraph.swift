//
//  HearingGraph.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/06/01.
//

import SwiftUI

struct HearingGraph: View {
    let testResults: [TestResult]
    
    var body: some View {
        VStack(spacing: 8) {
            // 統合されたグラフ
            GeometryReader { geo in
                ZStack {
                    // Y軸のスケール線（0dB, 20dB, 40dB, 60dB, 80dB, 100dB, 120dB）
                    ForEach(0...6, id: \.self) { level in
                        let y = geo.size.height * CGFloat(level) / 6.0
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        }
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    }
                    
                    // X軸のスケール線（各周波数）
                    ForEach(0..<7, id: \.self) { freqIndex in
                        let x = geo.size.width * CGFloat(freqIndex) / 6.0
                        Path { path in
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        }
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    }
                    
                    // 各検査結果のライン
                    ForEach(testResults, id: \.id) { result in
                        if let graphData = result.graphData {
                            SingleLineGraph(
                                freqs: result.freqs,
                                values: graphData,
                                color: result.displayColor,
                                geometrySize: geo.size
                            )
                        }
                    }
                }
            }
            .frame(height: 120)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            // Y軸ラベル
            HStack {
                Text("0dB")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Spacer()
                Text("120dB")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            // X軸ラベル（周波数）
            if let freqs = testResults.first?.freqs {
                HStack {
                    ForEach(freqs, id: \.self) { freq in
                        Text(freq)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        if freq != freqs.last {
                            Spacer()
                        }
                    }
                }
            }
            
            // 凡例
            GraphLegend(testResults: testResults)
        }
    }
}

struct SingleLineGraph: View {
    let freqs: [String]
    let values: [Int?]
    let color: Color
    let geometrySize: CGSize
    
    var body: some View {
        let points = values.enumerated()
            .compactMap { (i, v) -> CGPoint? in
                guard let v = v else { return nil }
                let x = geometrySize.width * CGFloat(i) / CGFloat(freqs.count - 1)
                let y = geometrySize.height * CGFloat(v) / 120.0
                return CGPoint(x: x, y: y)
            }
        
        ZStack {
            // ライン
            Path { path in
                if let first = points.first {
                    path.move(to: first)
                    for p in points.dropFirst() {
                        path.addLine(to: p)
                    }
                }
            }
            .stroke(color, lineWidth: 2)
            
            // ポイント
            ForEach(0..<points.count, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .position(points[safe: i] ?? .zero)
            }
        }
    }
}

struct GraphLegend: View {
    let testResults: [TestResult]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 4) {
            ForEach(testResults, id: \.id) { result in
                HStack(spacing: 4) {
                    Circle()
                        .fill(result.displayColor)
                        .frame(width: 8, height: 8)
                    Text(result.displayLabel)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
    }
}

// 安全な配列参照用
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}