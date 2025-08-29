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
                        ForEach(0...12, id: \.self) { level in
                            let dbValue = -10 + level * 10
                            let y = labelGeo.size.height * CGFloat(level) / 12.0
                            Text("\(dbValue)dB")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .position(x: labelGeo.size.width / 2, y: y)
                        }
                    }
                }
                .frame(width: 35, height: 200)
                
                // グラフエリア
                GeometryReader { geo in
                    ZStack {
                        // Y軸のスケール線（-10dBから110dBまで10dB刻み）
                        ForEach(0...12, id: \.self) { level in
                            let y = geo.size.height * CGFloat(level) / 12.0
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
                                    geometrySize: geo.size,
                                    testResult: result
                                )
                            }
                        }
                    }
                }
                .frame(height: 200)
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
    let testResult: TestResult
    
    var body: some View {
        let points = values.enumerated()
            .compactMap { (i, v) -> CGPoint? in
                guard let v = v else { return nil }
                let x = geometrySize.width * CGFloat(i) / CGFloat(freqs.count - 1)
                let y = geometrySize.height * (CGFloat(v) + 10.0) / 120.0
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
                Group {
                    switch (testResult.ear, testResult.condition) {
                    case ("右耳のみ", "裸耳"):
                        // 右耳 裸耳：○（赤）
                        Circle()
                            .stroke(Color.red, lineWidth: 2)
                            .frame(width: 12, height: 12)
                    case ("右耳のみ", "補聴器"):
                        // 右耳 補聴器装用下：△（少し暗い赤）
                        Triangle(direction: .up)
                            .stroke(Color(red: 0.8, green: 0.2, blue: 0.2), lineWidth: 2)
                            .frame(width: 16, height: 16)
                    case ("左耳のみ", "裸耳"):
                        // 左耳 裸耳：×（青）
                        Cross()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: 12, height: 12)
                    case ("左耳のみ", "補聴器"):
                        // 左耳 補聴器装用下：▽（少し暗い青）
                        Triangle(direction: .down)
                            .stroke(Color(red: 0.2, green: 0.4, blue: 0.8), lineWidth: 2)
                            .frame(width: 16, height: 16)
                    case ("両耳", "裸耳"):
                        // 両耳 裸耳：△（緑）
                        Triangle(direction: .up)
                            .stroke(Color.green, lineWidth: 2)
                            .frame(width: 16, height: 16)
                    case ("両耳", "補聴器"):
                        // 両耳 補聴器装用下：▲（少し暗い緑）
                        Triangle(direction: .up)
                            .fill(Color(red: 0.2, green: 0.6, blue: 0.2))
                            .frame(width: 16, height: 16)
                    default:
                        // その他：円
                        Circle()
                            .fill(Color.black)
                            .frame(width: 8, height: 8)
                    }
                }
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
                            .frame(width: 90, alignment: .leading)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 4)
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
                            .frame(width: 90, alignment: .leading)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 4)
                            .background(Color(.systemGray6).opacity(0.5))
                            
                            // データ値
                            if let graphData = result.graphData {
                                ForEach(0..<freqs.count, id: \.self) { index in
                                    Text({
                                        if let optionalValue = graphData[safe: index], let value = optionalValue {
                                            return "\(value)dB"
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

// 三角形シェイプ（方向指定可能）
struct Triangle: Shape {
    enum Direction {
        case up, down
    }
    
    let direction: Direction
    
    init(direction: Direction = .up) {
        self.direction = direction
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch direction {
        case .up:
            // 上向き三角形 ▲
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        case .down:
            // 下向き三角形 ▽
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
        
        path.closeSubpath()
        return path
    }
}

// ×シェイプ（クロス）
struct Cross: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 左上から右下への線
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.minY + rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.maxY - rect.height * 0.2))
        
        // 右上から左下への線
        path.move(to: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.minY + rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY - rect.height * 0.2))
        
        return path
    }
}

// 安全な配列参照用
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}