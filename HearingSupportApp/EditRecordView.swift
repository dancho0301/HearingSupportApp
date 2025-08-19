//
//  EditRecordView.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/06/01.
//


import SwiftUI

struct EditRecordView: View {
    @Binding var record: Record
    var onDelete: (() -> Void)? = nil
    @Environment(\.presentationMode) var presentationMode

    @State private var editingRecord: Record
    @State private var editingResults: [TestResultInput] = []

    init(record: Binding<Record>, onDelete: (() -> Void)? = nil) {
        self._record = record
        self.onDelete = onDelete
        _editingRecord = State(initialValue: record.wrappedValue)
        // TestResult → TestResultInputへの変換
        _editingResults = State(initialValue: record.wrappedValue.results.map { $0.toInput() })
    }

    var body: some View {
        Form {
            DatePicker("検査日", selection: $editingRecord.date, displayedComponents: [.date])
                .datePickerStyle(.compact)
                .environment(\.locale, Locale(identifier: "ja_JP"))

            TextField("病院名", text: $editingRecord.hospital)
            TextField("検査名", text: $editingRecord.title)
            TextEditor(text: $editingRecord.detail)
                .frame(minHeight: 80)

            Section(header: Text("検査結果")) {
                ForEach($editingResults) { $result in
                    TestResultInputView(result: $result)
                }
            }

            Button("保存") {
                editingRecord.results = editingResults.map { $0.toResult() }
                record = editingRecord
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.blue)

            if let onDelete = onDelete {
                Button("削除", role: .destructive) {
                    onDelete()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationTitle("記録の編集")
    }
}
// TestResult から TestResultInput へ変換するための拡張
extension TestResult {
    func toInput() -> TestResultInput {
        TestResultInput(
            ear: self.ear,
            condition: self.condition,
            thresholdsRight: self.thresholdsRight ?? Array(repeating: nil, count: 7),
            thresholdsLeft: self.thresholdsLeft ?? Array(repeating: nil, count: 7),
            thresholdsBoth: self.thresholdsBoth ?? Array(repeating: nil, count: 7)
        )
    }
}
