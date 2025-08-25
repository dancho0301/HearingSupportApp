import SwiftUI

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
                    
                    ForEach(record.results, id: \.id) { testResult in
                        PrintableTestResultView(testResult: testResult)
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
    let sampleRecord = Record(
        date: Date(),
        hospital: "○○総合病院",
        title: "定期聴力検査",
        detail: "年次定期検査",
        results: [
            TestResult(
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