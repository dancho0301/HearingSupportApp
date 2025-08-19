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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(formatter.string(from: record.date))
                    .font(.title3)
                    .foregroundColor(.orange)
                Spacer()
                Text(record.hospital)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text(record.title)
                .font(.headline)
                .foregroundColor(.primary)
            if !record.detail.isEmpty {
                Text(record.detail)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            ForEach(record.results, id: \.self) { result in
                Text("【\(result.ear)・\(result.condition)】")
                    .font(.caption)
                    .bold()
                if result.ear == "右耳のみ", let v = result.thresholdsRight {
                    HearingGraph(freqs: result.freqs, values: v, color: .orange)
                }
                if result.ear == "左耳のみ", let v = result.thresholdsLeft {
                    HearingGraph(freqs: result.freqs, values: v, color: .blue)
                }
                if result.ear == "両耳", let v = result.thresholdsBoth {
                    HearingGraph(freqs: result.freqs, values: v, color: .gray)
                }
                ForEach(0..<result.freqs.count, id: \.self) { i in
                    switch result.ear {
                    case "右耳のみ":
                        Text("\(result.freqs[i])：右 \(result.thresholdsRight?[i] ?? nil != nil ? "\(result.thresholdsRight![i]!)dB" : "-")")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    case "左耳のみ":
                        Text("\(result.freqs[i])：左 \(result.thresholdsLeft?[i] ?? nil != nil ? "\(result.thresholdsLeft![i]!)dB" : "-")")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    case "両耳":
                        Text("\(result.freqs[i])：両耳 \(result.thresholdsBoth?[i] ?? nil != nil ? "\(result.thresholdsBoth![i]!)dB" : "-")")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}
