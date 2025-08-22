//
//  RecordFormView.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/06/01.
//

import SwiftUI
import SwiftData

struct RecordFormView: View {
    @State var date: Date
    @State var selectedHospitalIndex: Int
    @State var newHospital: String
    @State var selectedTestIndex: Int
    @State var detail: String
    @State var results: [TestResultInput]

    let settings: AppSettings
    var isEditing: Bool
    var onSave: (String, String, Date, String, [TestResult]) -> Void
    var onDelete: (() -> Void)? = nil
    @Environment(\.presentationMode) var presentationMode
 
    init(
        record: Record?,
        settings: AppSettings,
        isEditing: Bool,
        onSave: @escaping (String, String, Date, String, [TestResult]) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        _date = State(initialValue: record?.date ?? Date())
        self.settings = settings
        if let rec = record, let idx = settings.enabledHospitals.firstIndex(of: rec.hospital) {
            _selectedHospitalIndex = State(initialValue: idx)
            _newHospital = State(initialValue: "")
        } else {
            _selectedHospitalIndex = State(initialValue: settings.enabledHospitals.count)
            _newHospital = State(initialValue: record?.hospital ?? "")
        }
        if let rec = record, let tIdx = settings.enabledTestTypes.firstIndex(of: rec.title) {
            _selectedTestIndex = State(initialValue: tIdx)
        } else {
            _selectedTestIndex = State(initialValue: 0)
        }
        _detail = State(initialValue: record?.detail ?? "")
        _results = State(initialValue: record?.results.map { $0.toInput() } ?? [TestResultInput()])
        self.isEditing = isEditing
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        Form {
            Section(header: Text("検査情報")) {
                DatePicker("検査日", selection: $date, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                Picker("病院名", selection: $selectedHospitalIndex) {
                    ForEach(0..<(settings.enabledHospitals.count + 1), id: \.self) { idx in
                        if idx < settings.enabledHospitals.count {
                            Text(settings.enabledHospitals[idx])
                        } else {
                            Text("新規入力")
                        }
                    }
                }
                if selectedHospitalIndex == settings.enabledHospitals.count {
                    TextField("新しい病院名を入力", text: $newHospital)
                }
                Picker("検査名", selection: $selectedTestIndex) {
                    ForEach(0..<settings.enabledTestTypes.count, id: \.self) {
                        Text(settings.enabledTestTypes[$0])
                    }
                }
            }
            Section(header: Text("検査結果（最大6通り追加可）")) {
                ForEach($results) { $result in
                    TestResultInputView(result: $result)
                }
                if results.count < 6 {
                    Button(action: {
                        results.append(TestResultInput())
                    }) {
                        Label("検査結果を追加", systemImage: "plus.circle")
                    }
                }
            }
            Section(header: Text("結果・所見")) {
                TextEditor(text: $detail)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            Button("保存") {
                let hospitalName: String
                if selectedHospitalIndex == settings.enabledHospitals.count {
                    hospitalName = newHospital
                } else {
                    hospitalName = settings.enabledHospitals[selectedHospitalIndex]
                }
                
                let testResults = results.map { input in
                    TestResult(
                        ear: input.ear,
                        condition: input.condition,
                        thresholdsRight: input.ear == "右耳のみ" ? input.thresholdsRight : nil,
                        thresholdsLeft: input.ear == "左耳のみ" ? input.thresholdsLeft : nil,
                        thresholdsBoth: input.ear == "両耳" ? input.thresholdsBoth : nil,
                        freqs: input.freqs
                    )
                }
                
                onSave(hospitalName, settings.enabledTestTypes[selectedTestIndex], date, detail, testResults)
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.blue)
            if isEditing, let onDelete = onDelete {
                Button("削除", role: .destructive) {
                    onDelete()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationTitle(isEditing ? "記録の編集" : "検査記録を追加")
    }
}

extension TestResult {
    func toInput() -> TestResultInput {
        var input = TestResultInput()
        input.ear = self.ear
        input.condition = self.condition
        
        if let right = self.thresholdsRight {
            input.thresholdsRight = right
        }
        if let left = self.thresholdsLeft {
            input.thresholdsLeft = left
        }
        if let both = self.thresholdsBoth {
            input.thresholdsBoth = both
        }
        
        return input
    }
}