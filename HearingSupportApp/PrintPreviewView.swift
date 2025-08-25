import SwiftUI

struct PrintPreviewView: View {
    let record: Record
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                PrintableRecordView(record: record)
                    .scaleEffect(0.7)
                    .background(Color.white)
                    .shadow(radius: 5)
            }
            .background(Color(.systemGray6))
            .navigationTitle("印刷プレビュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("印刷") {
                        PrintManager.shared.printRecord(record)
                    }
                    .fontWeight(.semibold)
                }
            }
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
    
    PrintPreviewView(record: sampleRecord)
}