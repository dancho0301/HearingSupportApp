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
    @State private var showDeleteAlert = false
    @State private var showExitAlert = false
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var showingScanner = false
    @State private var scannedPages: [ScannedPage] = []
    @State private var showScanResultAlert = false
    @State private var scanResultMessage = ""
    
    // 初期値を保持するプロパティ
    private let initialDate: Date
    private let initialHospitalIndex: Int
    private let initialNewHospital: String
    private let initialTestIndex: Int
    private let initialDetail: String
    private let initialResults: [TestResultInput]

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
        let dateValue = record?.date ?? Date()
        _date = State(initialValue: dateValue)
        self.initialDate = dateValue
        
        self.settings = settings
        
        let hospitalIndex: Int
        let newHospitalValue: String
        if let rec = record, let idx = settings.enabledHospitals.firstIndex(of: rec.hospital) {
            hospitalIndex = idx
            newHospitalValue = ""
        } else {
            hospitalIndex = settings.enabledHospitals.count
            newHospitalValue = record?.hospital ?? ""
        }
        _selectedHospitalIndex = State(initialValue: hospitalIndex)
        _newHospital = State(initialValue: newHospitalValue)
        self.initialHospitalIndex = hospitalIndex
        self.initialNewHospital = newHospitalValue
        
        let testIndex: Int
        if let rec = record, let tIdx = settings.enabledTestTypes.firstIndex(of: rec.title) {
            testIndex = tIdx
        } else {
            testIndex = 0
        }
        _selectedTestIndex = State(initialValue: testIndex)
        self.initialTestIndex = testIndex
        
        let detailValue = record?.detail ?? ""
        _detail = State(initialValue: detailValue)
        self.initialDetail = detailValue
        
        let resultsValue = record?.results.map { $0.toInput() } ?? [TestResultInput()]
        _results = State(initialValue: resultsValue)
        self.initialResults = resultsValue
        
        self.isEditing = isEditing
        self.onSave = onSave
        self.onDelete = onDelete
    }
    
    // 変更があったかどうかをチェックする関数
    private var hasChanges: Bool {
        return date != initialDate ||
               selectedHospitalIndex != initialHospitalIndex ||
               newHospital != initialNewHospital ||
               selectedTestIndex != initialTestIndex ||
               detail != initialDetail ||
               !areResultsEqual(results, initialResults)
    }
    
    // TestResultInputの配列を比較する関数
    private func areResultsEqual(_ lhs: [TestResultInput], _ rhs: [TestResultInput]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for (index, leftResult) in lhs.enumerated() {
            let rightResult = rhs[index]
            if leftResult.ear != rightResult.ear ||
               leftResult.condition != rightResult.condition ||
               leftResult.thresholdsRight != rightResult.thresholdsRight ||
               leftResult.thresholdsLeft != rightResult.thresholdsLeft ||
               leftResult.thresholdsBoth != rightResult.thresholdsBoth {
                return false
            }
        }
        return true
    }

    var body: some View {
        Form {
            scanSection
            infoSection
            resultsSection
            detailSection
            deleteSection
        }
        .navigationTitle(isEditing ? "記録の編集" : "検査記録を追加")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    // 未保存の変更がある場合は破棄確認を出す
                    if hasChanges {
                        showExitAlert = true
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("戻る")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveRecord()
                }
                .foregroundColor(.blue)
            }
        }
        .alert("変更を破棄", isPresented: $showExitAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("破棄", role: .destructive) {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("変更された内容が保存されていません。変更を破棄して戻りますか？")
        }
        .alert("記録を削除", isPresented: $showDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                onDelete?()
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("この記録を削除しますか？この操作は取り消せません。")
        }
        .alert("入力エラー", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
        .sheet(isPresented: $showingScanner) {
            CameraOCRView(scannedPages: $scannedPages, isPresented: $showingScanner)
                .ignoresSafeArea()
        }
        .onChange(of: scannedPages) { _, newPages in
            applyScanResult(newPages)
        }
        .alert("読み取り結果", isPresented: $showScanResultAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(scanResultMessage)
        }
    }

    // MARK: - フォームの各セクション

    private var scanSection: some View {
        Section {
            Button(action: {
                showingScanner = true
            }) {
                Label("紙の記録用紙をカメラで読み取る", systemImage: "doc.viewfinder")
            }
        } footer: {
            Text("検査日・病院名・聴力レベルを自動で読み取ってフォームに入力します。読み取り後は必ず内容を確認してください。")
        }
    }

    private var infoSection: some View {
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
    }

    private var resultsSection: some View {
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
    }

    private var detailSection: some View {
        Section(header: Text("結果・所見")) {
            TextEditor(text: $detail)
                .frame(minHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }

    private var deleteSection: some View {
        Section {
            if isEditing, onDelete != nil {
                Button("削除", role: .destructive) {
                    showDeleteAlert = true
                }
            }
        }
    }

    // MARK: - 保存

    private func saveRecord() {
        // enabledHospitals は計算プロパティで、表示後に設定変更で件数が変わり得るため
        // インデックスの範囲を必ず確認してから参照する（範囲外アクセスでのクラッシュを防ぐ）。
        let hospitalName: String
        if settings.enabledHospitals.indices.contains(selectedHospitalIndex) {
            hospitalName = settings.enabledHospitals[selectedHospitalIndex]
        } else {
            hospitalName = newHospital
        }

        // バリデーション
        if hospitalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "病院名を入力してください"
            showValidationAlert = true
            return
        }

        if selectedTestIndex >= settings.enabledTestTypes.count {
            validationMessage = "検査種類を選択してください"
            showValidationAlert = true
            return
        }

        do {
            let testResults = try results.map { input in
                try input.toResult()
            }

            onSave(hospitalName, settings.enabledTestTypes[selectedTestIndex], date, detail, testResults)
            presentationMode.wrappedValue.dismiss()
        } catch {
            validationMessage = error.localizedDescription
            showValidationAlert = true
        }
    }

    // カメラ読み取り結果をフォームに反映する
    private func applyScanResult(_ pages: [ScannedPage]) {
        guard !pages.isEmpty else { return }
        defer { scannedPages = [] }

        let parsed = RecordSheetParser.parse(pages: pages)
        var appliedItems: [String] = []

        if let scannedDate = parsed.date {
            date = scannedDate
            appliedItems.append("検査日")
        }

        if let hospital = parsed.hospital {
            if let idx = settings.enabledHospitals.firstIndex(of: hospital) {
                selectedHospitalIndex = idx
            } else {
                selectedHospitalIndex = settings.enabledHospitals.count
                newHospital = hospital
            }
            appliedItems.append("病院名")
        }

        if !parsed.testResults.isEmpty {
            for input in parsed.testResults {
                if results.count == 1 && isEmptyResult(results[0]) {
                    results[0] = input
                } else if results.count < 6 {
                    results.append(input)
                }
            }
            appliedItems.append(parsed.usedGraphRecognition ? "聴力レベル（グラフから推定）" : "聴力レベル")
        }

        if appliedItems.isEmpty {
            scanResultMessage = "記録内容を読み取れませんでした。文字がはっきり写るように撮影し直すか、手動で入力してください。"
        } else {
            var message = "次の項目を読み取りました：\(appliedItems.joined(separator: "・"))\n内容を確認し、必要に応じて修正してください。"
            if parsed.usedGraphRecognition {
                message += "\n聴力レベルはグラフの記号位置から推定した値です。必ず元の用紙と見比べてください。"
            }
            scanResultMessage = message
        }
        // カメラのシートが閉じてからアラートを表示する
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showScanResultAlert = true
        }
    }

    private func isEmptyResult(_ input: TestResultInput) -> Bool {
        return input.thresholdsRight.allSatisfy { $0 == nil } &&
               input.thresholdsLeft.allSatisfy { $0 == nil } &&
               input.thresholdsBoth.allSatisfy { $0 == nil }
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