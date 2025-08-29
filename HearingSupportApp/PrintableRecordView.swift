import SwiftUI

// PDF用のテーブルなしHearingGraph
struct PDFHearingGraph: View {
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
                .frame(width: 35, height: 320)
                
                // グラフエリア（右端にマージンを追加）
                GeometryReader { geo in
                    let graphWidth = geo.size.width - 20 // 右端に20ポイントのマージン
                    ZStack {
                        // Y軸のスケール線（-10dBから110dBまで10dB刻み）
                        ForEach(0...12, id: \.self) { level in
                            let y = geo.size.height * CGFloat(level) / 12.0
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: graphWidth, y: y))
                            }
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        }
                        
                        // X軸のスケール線（各周波数）
                        ForEach(0..<7, id: \.self) { freqIndex in
                            let x = graphWidth * CGFloat(freqIndex) / 6.0
                            Path { path in
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: geo.size.height))
                            }
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        }
                        
                        // 各検査結果のライン
                        ForEach(testResults, id: \.id) { result in
                            if let graphData = result.graphData {
                                PDFSingleLineGraph(
                                    freqs: result.freqs,
                                    values: graphData,
                                    color: result.displayColor,
                                    geometrySize: CGSize(width: graphWidth, height: geo.size.height),
                                    testResult: result
                                )
                            }
                        }
                    }
                }
                .frame(height: 320)
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
                        // 右端のスペースを確保
                        Spacer()
                            .frame(width: 20)
                    }
                }
            }
            
        }
    }
}

// PDF用の凡例
struct PDFGraphLegend: View {
    let testResults: [TestResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("凡例")
                .font(.caption)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], alignment: .leading, spacing: 8) {
                ForEach(testResults, id: \.id) { result in
                    HStack(spacing: 6) {
                        // マーカーの表示
                        Group {
                            switch (result.ear, result.condition) {
                            case ("右耳のみ", "裸耳"):
                                Circle()
                                    .stroke(Color.red, lineWidth: 2)
                                    .frame(width: 12, height: 12)
                            case ("右耳のみ", "補聴器"):
                                Triangle(direction: .up)
                                    .stroke(Color(red: 0.8, green: 0.2, blue: 0.2), lineWidth: 2)
                                    .frame(width: 12, height: 12)
                            case ("左耳のみ", "裸耳"):
                                Cross()
                                    .stroke(Color.blue, lineWidth: 2)
                                    .frame(width: 12, height: 12)
                            case ("左耳のみ", "補聴器"):
                                Triangle(direction: .down)
                                    .stroke(Color(red: 0.2, green: 0.4, blue: 0.8), lineWidth: 2)
                                    .frame(width: 12, height: 12)
                            case ("両耳", "裸耳"):
                                Triangle(direction: .up)
                                    .stroke(Color.green, lineWidth: 2)
                                    .frame(width: 12, height: 12)
                            case ("両耳", "補聴器"):
                                Triangle(direction: .up)
                                    .fill(Color(red: 0.2, green: 0.6, blue: 0.2))
                                    .frame(width: 12, height: 12)
                            default:
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        // ラベル
                        Text(result.displayLabel)
                            .font(.caption2)
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(6)
    }
}

struct PDFSingleLineGraph: View {
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
            // ライン（白黒印刷を考慮してグレーにする）
            Path { path in
                if let first = points.first {
                    path.move(to: first)
                    for p in points.dropFirst() {
                        path.addLine(to: p)
                    }
                }
            }
            .stroke(Color.black, lineWidth: 2)
            
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


struct PrintableRecordView: View {
    let record: Record
    
    private let frequencies: [Double] = [125, 250, 500, 1000, 2000, 4000, 8000]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // ヘッダー
            VStack(alignment: .leading, spacing: 8) {
                Text("聴力検査記録")
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack {
                    Text("検査日: \(formattedDate)")
                    Spacer()
                    Text("印刷日: \(currentDate)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                Divider()
            }
            
            // 基本情報
            VStack(alignment: .leading, spacing: 12) {
                Text("基本情報")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Label("病院・施設", systemImage: "building.2")
                    Spacer()
                    Text(record.hospital)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Label("検査タイトル", systemImage: "doc.text")
                    Spacer()
                    Text(record.title)
                        .fontWeight(.medium)
                }
                
                if !record.detail.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("詳細", systemImage: "note.text")
                        Text(record.detail)
                            .padding(.leading, 20)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // 検査結果
            if !record.results.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("検査結果")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // オージオグラム
                    VStack(alignment: .leading, spacing: 12) {
                        Text("オージオグラム")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        PDFHearingGraph(testResults: record.results)
                            .frame(height: 380)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        
                        // 凡例
                        PDFGraphLegend(testResults: record.results)
                    }
                }
            }
            
            Spacer()
            
            // フッター
            VStack(spacing: 4) {
                Divider()
                Text("おみみ手帳で作成")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
        .background(Color.white)
        .colorScheme(.light)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: record.date)
    }
    
    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: Date())
    }
}

struct PrintableTestResultView: View {
    let testResult: TestResult
    
    private let frequencies: [Double] = [125, 250, 500, 1000, 2000, 4000, 8000]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(testResult.condition)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
                
                Text(earDisplayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // データテーブル
            VStack(spacing: 0) {
                // ヘッダー行
                HStack(spacing: 0) {
                    Text("周波数 (Hz)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 80, alignment: .center)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                    
                    ForEach(frequencies, id: \.self) { frequency in
                        Text(frequencyLabel(frequency))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 60, alignment: .center)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                    }
                }
                
                // データ行を表示
                if let data = testResult.graphData {
                    HStack(spacing: 0) {
                        Text(earDisplayName + " (dB)")
                            .font(.caption)
                            .frame(width: 80, alignment: .center)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                        
                        ForEach(0..<min(frequencies.count, data.count), id: \.self) { index in
                            Text(data[index] != nil ? "\(data[index]!)" : "-")
                                .font(.caption)
                                .frame(width: 60, alignment: .center)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                        }
                        
                        // 残りの周波数を埋める
                        ForEach(data.count..<frequencies.count, id: \.self) { _ in
                            Text("-")
                                .font(.caption)
                                .frame(width: 60, alignment: .center)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                        }
                    }
                }
            }
            .overlay(
                Rectangle()
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(12)
    }
    
    private var earDisplayName: String {
        return testResult.ear
    }
    
    private func frequencyLabel(_ frequency: Double) -> String {
        if frequency < 1000 {
            return "\(Int(frequency))"
        } else {
            return "\(Int(frequency / 1000))k"
        }
    }
}

#Preview {
    let sampleRecord = try! Record(
        date: Date(),
        hospital: "○○総合病院",
        title: "定期聴力検査",
        detail: "年次定期検査",
        results: [
            try! TestResult(
                ear: "両耳",
                condition: "裸耳",
                thresholdsBoth: [30, 35, 40, 45, 50, 55, 60],
                freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
            )
        ]
    )
    
    PrintableRecordView(record: sampleRecord)
        .frame(width: 595, height: 842)
}

