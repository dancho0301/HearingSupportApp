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
    @State private var showPDFPreview = false
    
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
                
                Text(record.hospital)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // PDFプレビューボタン
                Button(action: {
                    showPDFPreview = true
                }) {
                    Image(systemName: "printer")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
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
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .sheet(isPresented: $showPDFPreview) {
            PDFPreviewView(record: record)
        }
    }
}