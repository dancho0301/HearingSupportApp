//
//  RecordFormView.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/06/01.
//

import SwiftUI

struct RecordFormView: View {
    @State var date: Date
    @State var hospitalList: [String]
    @State var selectedHospitalIndex: Int
    @State var newHospital: String
    @State var testTypes: [String]
    @State var selectedTestIndex: Int
    @State var detail: String
    @State var results: [TestResultInput]

    var isEditing: Bool
    var onSave: (Record) -> Void
    var onDelete: (() -> Void)? = nil
    @Environment(\.presentationMode) var presentationMode
 
    init(
        record: Record?,
        hospitalList: [String],
        testTypes: [String],
        isEditing: Bool,
        onSave: @escaping (Record) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        _date = State(initialValue: record?.date ?? Date())
        _hospitalList = State(initialValue: hospitalList)
        if let rec = record, let idx = hospitalList.firstIndex(of: rec.hospital) {
            _selectedHospitalIndex = State(initialValue: idx)
            _newHospital = State(initialValue: "")
        } else {
            _selectedHospitalIndex = State(initialValue: hospitalList.count)
            _newHospital = State(initialValue: record?.hospital ?? "")
        }
        _testTypes = State(initialValue: testTypes)
        if let rec = record, let tIdx = testTypes.firstIndex(of: rec.title) {
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
                    ForEach(0..<(hospitalList.count + 1), id: \.self) { idx in
                        if idx < hospitalList.count {
                            Text(hospitalList[idx])
                        } else {
                            Text("新規入力")
                        }
                    }
                }
                if selectedHospitalIndex == hospitalList.count {
                    TextField("新しい病院名を入力", text: $newHospital)
                }
                Picker("検査名", selection: $selectedTestIndex) {
                    ForEach(0..<testTypes.count, id: \.self) {
                        Text(testTypes[$0])
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
                if selectedHospitalIndex == hospitalList.count {
                    hospitalName = newHospital
                    if !hospitalList.contains(newHospital) && !newHospital.isEmpty {
                        hospitalList.append(newHospital)
                    }
                } else {
                    hospitalName = hospitalList[selectedHospitalIndex]
                }
                let record = Record(
                    date: date,
                    hospital: hospitalName,
                    title: testTypes[selectedTestIndex],
                    detail: detail,
                    results: results.map { $0.toResult() }
                )
                onSave(record)
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
