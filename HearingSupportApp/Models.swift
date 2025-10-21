//
//  Models.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/06/01.
//


import SwiftUI
import SwiftData
import Foundation

enum ValidationError: LocalizedError {
    case emptyName
    case emptyHospital
    case emptyTestType
    case emptyEar
    case emptyCondition
    case emptyPurpose
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "利用者名を入力してください"
        case .emptyHospital:
            return "病院名を入力してください"
        case .emptyTestType:
            return "検査種類を選択してください"
        case .emptyEar:
            return "検査対象耳を選択してください"
        case .emptyCondition:
            return "検査条件を選択してください"
        case .emptyPurpose:
            return "予約目的を入力してください"
        }
    }
}

@Model
final class Child {
    var id: UUID
    var name: String
    var notes: String
    var isActive: Bool
    var createdAt: Date
    var records: [Record]
    var appointments: [Appointment]
    
    init(name: String, notes: String = "") throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyName
        }
        self.id = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.notes = notes
        self.isActive = true
        self.createdAt = Date()
        self.records = []
        self.appointments = []
    }
    
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyName
        }
    }
}

@Model
final class Record {
    var id: UUID
    var date: Date
    var hospital: String
    var title: String
    var detail: String
    var results: [TestResult]
    var child: Child?
    
    init(date: Date, hospital: String, title: String, detail: String, results: [TestResult] = [], child: Child? = nil) throws {
        guard !hospital.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyHospital
        }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyTestType
        }
        self.id = UUID()
        self.date = date
        self.hospital = hospital.trimmingCharacters(in: .whitespacesAndNewlines)
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.detail = detail
        self.results = results
        self.child = child
    }
    
    func validate() throws {
        guard !hospital.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyHospital
        }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyTestType
        }
    }
}

@Model
final class TestResult {
    var id: UUID
    var ear: String                 // 「右耳のみ」「左耳のみ」「両耳」
    var condition: String           // 「裸耳」「補聴器」「人工内耳」
    var thresholdsRightData: Data?
    var thresholdsLeftData: Data?
    var thresholdsBothData: Data?
    var freqsData: Data
    
    init(ear: String, condition: String, thresholdsRight: [Int?]? = nil, thresholdsLeft: [Int?]? = nil, thresholdsBoth: [Int?]? = nil, freqs: [String]) throws {
        guard !ear.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyEar
        }
        guard !condition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyCondition
        }
        self.id = UUID()
        self.ear = ear.trimmingCharacters(in: .whitespacesAndNewlines)
        self.condition = condition.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 配列をDataに変換して保存
        if let right = thresholdsRight {
            self.thresholdsRightData = try? JSONEncoder().encode(right)
        }
        if let left = thresholdsLeft {
            self.thresholdsLeftData = try? JSONEncoder().encode(left)
        }
        if let both = thresholdsBoth {
            self.thresholdsBothData = try? JSONEncoder().encode(both)
        }
        self.freqsData = (try? JSONEncoder().encode(freqs)) ?? Data()
    }
    
    func validate() throws {
        guard !ear.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyEar
        }
        guard !condition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyCondition
        }
    }
    
    // 計算プロパティで配列として取得
    var thresholdsRight: [Int?]? {
        get {
            guard let data = thresholdsRightData else { return nil }
            return try? JSONDecoder().decode([Int?].self, from: data)
        }
        set {
            thresholdsRightData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var thresholdsLeft: [Int?]? {
        get {
            guard let data = thresholdsLeftData else { return nil }
            return try? JSONDecoder().decode([Int?].self, from: data)
        }
        set {
            thresholdsLeftData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var thresholdsBoth: [Int?]? {
        get {
            guard let data = thresholdsBothData else { return nil }
            return try? JSONDecoder().decode([Int?].self, from: data)
        }
        set {
            thresholdsBothData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var freqs: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: freqsData)) ?? []
        }
        set {
            freqsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
}

struct TestTypeSetting: Codable, Identifiable, Hashable {
    let id = UUID()
    var name: String
    var isEnabled: Bool
    var isDefault: Bool
    
    init(name: String, isEnabled: Bool = true, isDefault: Bool = false) {
        self.name = name
        self.isEnabled = isEnabled
        self.isDefault = isDefault
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case isEnabled
        case isDefault
    }
}

struct HospitalSetting: Codable, Identifiable, Hashable {
    let id = UUID()
    var name: String
    var isEnabled: Bool
    
    init(name: String, isEnabled: Bool = true) {
        self.name = name
        self.isEnabled = isEnabled
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case isEnabled
    }
}

@Model
final class AppSettings {
    var id: UUID
    var hospitalListData: Data
    var testTypesData: Data
    var testTypeSettingsData: Data?
    var hospitalSettingsData: Data?
    
    init(hospitalList: [String] = [], 
         testTypes: [String] = [
            "ABR（聴性脳幹反応）",
            "OAE（耳音響放射）", 
            "ASSR（聴性定常反応）",
            "インピーダンスオージオメトリー",
            "BOA（行動観察聴力検査）",
            "COR（条件詮索反応聴力検査）",
            "VRA（視覚強化聴力検査）",
            "ピュアトーン聴力検査",
            "語音聴力検査",
            "MLR（聴性中間反応）",
            "CAEP（皮質聴性誘発反応）",
            "REM（実耳測定）"
        ]) {
        self.id = UUID()
        self.hospitalListData = (try? JSONEncoder().encode(hospitalList)) ?? Data()
        self.testTypesData = (try? JSONEncoder().encode(testTypes)) ?? Data()
        
        // デフォルトの検査種類設定（すべて有効、デフォルト検査種類はisDefault=true）
        let defaultTestTypeSettings = testTypes.map { TestTypeSetting(name: $0, isEnabled: true, isDefault: true) }
        self.testTypeSettingsData = try? JSONEncoder().encode(defaultTestTypeSettings)
        
        // デフォルトの病院設定（すべて有効）
        let defaultHospitalSettings = hospitalList.map { HospitalSetting(name: $0, isEnabled: true) }
        self.hospitalSettingsData = try? JSONEncoder().encode(defaultHospitalSettings)
    }
    
    var hospitalList: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: hospitalListData)) ?? []
        }
        set {
            hospitalListData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    var testTypes: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: testTypesData)) ?? []
        }
        set {
            testTypesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    var testTypeSettings: [TestTypeSetting] {
        get {
            guard let data = testTypeSettingsData else {
                // データがない場合、現在の検査種類から初期設定を作成
                let initialSettings = testTypes.map { TestTypeSetting(name: $0, isEnabled: true, isDefault: AppSettings.defaultTestTypes.contains($0)) }
                testTypeSettingsData = try? JSONEncoder().encode(initialSettings)
                return initialSettings
            }
            
            let settings = (try? JSONDecoder().decode([TestTypeSetting].self, from: data)) ?? []
            
            // 設定が空の場合、現在の検査種類から初期設定を作成
            if settings.isEmpty {
                let initialSettings = testTypes.map { TestTypeSetting(name: $0, isEnabled: true, isDefault: AppSettings.defaultTestTypes.contains($0)) }
                testTypeSettingsData = try? JSONEncoder().encode(initialSettings)
                return initialSettings
            }
            
            // マイグレーション: 既存データでisDefaultがない場合はデフォルト検査種類かどうかで設定
            let migratedSettings = settings.map { setting in
                var newSetting = setting
                // デフォルト検査種類の場合はisDefault=trueに設定
                if AppSettings.defaultTestTypes.contains(setting.name) {
                    newSetting.isDefault = true
                }
                return newSetting
            }
            
            // マイグレーションした結果を保存
            if settings != migratedSettings {
                testTypeSettingsData = try? JSONEncoder().encode(migratedSettings)
                return migratedSettings
            }
            
            return settings
        }
        set {
            testTypeSettingsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // 有効な検査種類のみを取得
    var enabledTestTypes: [String] {
        return testTypeSettings.filter { $0.isEnabled }.map { $0.name }
    }
    
    var hospitalSettings: [HospitalSetting] {
        get {
            guard let data = hospitalSettingsData else {
                // データがない場合、現在の病院リストから初期設定を作成
                let initialSettings = hospitalList.map { HospitalSetting(name: $0, isEnabled: true) }
                hospitalSettingsData = try? JSONEncoder().encode(initialSettings)
                return initialSettings
            }
            
            let settings = (try? JSONDecoder().decode([HospitalSetting].self, from: data)) ?? []
            
            // 設定が空の場合、現在の病院リストから初期設定を作成
            if settings.isEmpty {
                let initialSettings = hospitalList.map { HospitalSetting(name: $0, isEnabled: true) }
                hospitalSettingsData = try? JSONEncoder().encode(initialSettings)
                return initialSettings
            }
            
            return settings
        }
        set {
            hospitalSettingsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // 有効な病院のみを取得
    var enabledHospitals: [String] {
        return hospitalSettings.filter { $0.isEnabled }.map { $0.name }
    }
    
    // デフォルト検査種類を取得
    static var defaultTestTypes: [String] {
        return [
            "ABR（聴性脳幹反応）",
            "OAE（耳音響放射）", 
            "ASSR（聴性定常反応）",
            "インピーダンスオージオメトリー",
            "BOA（行動観察聴力検査）",
            "COR（条件詮索反応聴力検査）",
            "VRA（視覚強化聴力検査）",
            "ピュアトーン聴力検査",
            "語音聴力検査",
            "MLR（聴性中間反応）",
            "CAEP（皮質聴性誘発反応）",
            "REM（実耳測定）"
        ]
    }
}

struct TestResultInput: Identifiable, Hashable {
    let id = UUID()
    var ear: String = "両耳"
    var condition: String = "裸耳"
    var thresholdsRight: [Int?] = Array(repeating: nil, count: 7)
    var thresholdsLeft: [Int?] = Array(repeating: nil, count: 7)
    var thresholdsBoth: [Int?] = Array(repeating: nil, count: 7)
    let earOptions = ["右耳のみ", "左耳のみ", "両耳"]
    let conditionOptions = ["裸耳", "補聴器"]
    let freqs = ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]

    func toResult() throws -> TestResult {
        try TestResult(
            ear: ear,
            condition: condition,
            thresholdsRight: ear == "右耳のみ" ? thresholdsRight : nil,
            thresholdsLeft: ear == "左耳のみ" ? thresholdsLeft : nil,
            thresholdsBoth: ear == "両耳" ? thresholdsBoth : nil,
            freqs: freqs
        )
    }
}

// TestResult用のextension
extension TestResult {
    // 検査結果パターンに応じた固有色を返す
    var displayColor: Color {
        switch (ear, condition) {
        case ("右耳のみ", "裸耳"):
            return .red
        case ("右耳のみ", "補聴器"):
            return Color(red: 0.8, green: 0.2, blue: 0.2) // 少し暗い赤
        case ("左耳のみ", "裸耳"):
            return .blue
        case ("左耳のみ", "補聴器"):
            return Color(red: 0.2, green: 0.4, blue: 0.8) // 少し暗い青
        case ("両耳", "裸耳"):
            return .green
        case ("両耳", "補聴器"):
            return Color(red: 0.2, green: 0.6, blue: 0.2) // 少し暗い緑
        default:
            return .gray
        }
    }
    
    // グラフ表示用のデータを取得
    var graphData: [Int?]? {
        switch ear {
        case "右耳のみ":
            return thresholdsRight
        case "左耳のみ":
            return thresholdsLeft
        case "両耳":
            return thresholdsBoth
        default:
            return nil
        }
    }
    
    // 表示用ラベル
    var displayLabel: String {
        return "\(ear)・\(condition)"
    }
}

// 通院予定モデル
@Model
final class Appointment {
    var id: UUID
    var hospital: String
    var appointmentDate: Date
    var appointmentTime: Date
    var purpose: String
    var notes: String
    var child: Child?
    
    init(hospital: String, appointmentDate: Date, appointmentTime: Date, purpose: String, notes: String = "", child: Child? = nil) throws {
        guard !hospital.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyHospital
        }
        guard !purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyPurpose
        }
        self.id = UUID()
        self.hospital = hospital.trimmingCharacters(in: .whitespacesAndNewlines)
        self.appointmentDate = appointmentDate
        self.appointmentTime = appointmentTime
        self.purpose = purpose.trimmingCharacters(in: .whitespacesAndNewlines)
        self.notes = notes
        self.child = child
    }
    
    func validate() throws {
        guard !hospital.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyHospital
        }
        guard !purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyPurpose
        }
    }
    
    // 予定日時を組み合わせた Date を取得
    var fullAppointmentDate: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: appointmentDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: appointmentTime)

        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute

        return calendar.date(from: combinedComponents) ?? appointmentDate
    }
}
