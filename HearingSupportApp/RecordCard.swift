//
//  RecordCard.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/06/01.
//

import SwiftUI

// 記録カード
struct RecordCard: View {
    let record: Record
    
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日"
        return f
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー情報
            HStack {
                Text(formatter.string(from: record.date))
                    .font(.title3)
                    .foregroundColor(.orange)
                Spacer()
                Text(record.hospital)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Text(record.title)
                .font(.headline)
                .foregroundColor(.black)
            
            if !record.detail.isEmpty {
                Text(record.detail)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // 統合されたグラフ表示
            if !record.results.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("検査結果")
                        .font(.subheadline)
                        .bold()
                    
                    // 1枚のグラフに全パターンを表示
                    HearingGraph(testResults: record.results)
                    
                    // 数値データ詳細表示
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(record.results, id: \.id) { result in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("【\(result.displayLabel)】")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(result.displayColor)
                                
                                if let graphData = result.graphData {
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 4) {
                                        ForEach(0..<result.freqs.count, id: \.self) { i in
                                            if i < graphData.count {
                                                Text("\(result.freqs[i]): \(graphData[i] != nil ? "\(graphData[i]!)dB" : "-")")
                                                    .font(.caption2)
                                                    .foregroundColor(result.displayColor)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}