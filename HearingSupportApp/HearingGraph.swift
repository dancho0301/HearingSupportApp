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
            // Y軸ラベル付きグラフ
            HStack(alignment: .top, spacing: 8) {
                // Y軸ラベル（左側に縦配置）
                GeometryReader { labelGeo in
                    ZStack {
                        ForEach(0...6, id: \.self) { level in
                            let dbValue = level * 20
                            let y = labelGeo.size.height * CGFloat(level) / 6.0
                            Text("\(dbValue)dB")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .position(x: labelGeo.size.width / 2, y: y)
                        }
                    }
                }
                .frame(width: 35, height: 120)
                
                // グラフエリア
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
            }
            
            // X軸ラベル（周波数）
            if let freqs = testResults.first?.freqs {
                HStack(spacing: 8) {
                    // Y軸ラベルの幅と合わせるためのスペーサー
                    Spacer()
                        .frame(width: 35)
                    
                    // 周波数ラベル
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
            }
            
            // 数値データ表
            TestResultsTable(testResults: testResults)
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

struct TestResultsTable: View {
    let testResults: [TestResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 表形式で検査結果を表示
            if !testResults.isEmpty, let freqs = testResults.first?.freqs {
                VStack(spacing: 0) {
                    // ヘッダー行
                    HStack(spacing: 0) {
                        Text("検査条件")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 70, alignment: .center)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray2))
                        
                        ForEach(freqs, id: \.self) { freq in
                            Text(freq)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(minWidth: 40, alignment: .center)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray2))
                        }
                    }
                    
                    // データ行
                    ForEach(testResults, id: \.id) { result in
                        HStack(spacing: 0) {
                            // 検査条件ラベル
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(result.displayColor)
                                    .frame(width: 6, height: 6)
                                Text(result.displayLabel)
                                    .font(.caption2)
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                            }
                            .frame(width: 70, alignment: .center)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6).opacity(0.5))
                            
                            // データ値
                            if let graphData = result.graphData {
                                ForEach(0..<freqs.count, id: \.self) { index in
                                    Text({
                                        if let optionalValue = graphData[safe: index], let value = optionalValue {
                                            return "\(value)"
                                        } else {
                                            return "-"
                                        }
                                    }())
                                        .font(.caption)
                                        .foregroundColor(.black)
                                        .frame(minWidth: 40, alignment: .center)
                                        .padding(.vertical, 4)
                                        .background(Color.white)
                                }
                            } else {
                                ForEach(freqs, id: \.self) { _ in
                                    Text("-")
                                        .font(.caption)
                                        .foregroundColor(.black)
                                        .frame(minWidth: 40, alignment: .center)
                                        .padding(.vertical, 4)
                                        .background(Color.white)
                                }
                            }
                        }
                    }
                }
                .overlay(
                    Rectangle()
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .cornerRadius(8)
                .clipped()
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