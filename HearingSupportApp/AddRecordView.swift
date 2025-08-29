//
//  AddRecordView 2.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/06/01.
//


import SwiftUI

struct AddRecordView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var records: [Record]

    @State private var date = Date()
    @State private var selectedHospitalIndex = 0
    @State private var newHospital = ""
    @State private var selectedTestIndex = 0
    @State private var detail: String = ""

    @State private var hospitalList: [String] = []
    let testTypes = [
        "ABR検査",
        "OAE検査",
        "ASSR検査",
        "ピュアトーン聴力検査",
        "語音聴力検査",
        "インピーダンスオージオメトリー",
        "その他"
    ]

    @State private var results: [TestResultInput] = [
        TestResultInput()
    ]

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
                do {
                    let testResults = try results.map { try $0.toResult() }
                    let record = try Record(
                        date: date,
                        hospital: hospitalName,
                        title: testTypes[selectedTestIndex],
                        detail: detail,
                        results: testResults
                    )
                    records.insert(record, at: 0)
                    dismiss()
                } catch {
                    print("レコード作成エラー: \(error.localizedDescription)")
                }
            }
            .disabled((selectedHospitalIndex == hospitalList.count && newHospital.isEmpty))
        }
        .navigationTitle("検査記録を追加")
    }
}
