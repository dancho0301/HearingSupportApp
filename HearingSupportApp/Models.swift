//
//  Models.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/06/01.
//


import SwiftUI
import SwiftData
import Foundation

@Model
final class Record {
    var id: UUID
    var date: Date
    var hospital: String
    var title: String
    var detail: String
    var results: [TestResult]
    
    init(date: Date, hospital: String, title: String, detail: String, results: [TestResult] = []) {
        self.id = UUID()
        self.date = date
        self.hospital = hospital
        self.title = title
        self.detail = detail
        self.results = results
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
    
    init(ear: String, condition: String, thresholdsRight: [Int?]? = nil, thresholdsLeft: [Int?]? = nil, thresholdsBoth: [Int?]? = nil, freqs: [String]) {
        self.id = UUID()
        self.ear = ear
        self.condition = condition
        
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
    
    init(name: String, isEnabled: Bool = true) {
        self.name = name
        self.isEnabled = isEnabled
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
}

@Model
final class AppSettings {
    var id: UUID
    var hospitalListData: Data
    var testTypesData: Data
    var testTypeSettingsData: Data?
    var hospitalSettingsData: Data?
    
    init(hospitalList: [String] = ["千葉こども耳鼻科", "東京医大", "柏総合病院"], 
         testTypes: [String] = ["ABR検査", "OAE検査", "ASSR検査", "ピュアトーン聴力検査", "語音聴力検査", "インピーダンスオージオメトリー", "その他"]) {
        self.id = UUID()
        self.hospitalListData = (try? JSONEncoder().encode(hospitalList)) ?? Data()
        self.testTypesData = (try? JSONEncoder().encode(testTypes)) ?? Data()
        
        // デフォルトの検査種類設定（すべて有効）
        let defaultTestTypeSettings = testTypes.map { TestTypeSetting(name: $0, isEnabled: true) }
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
                let initialSettings = testTypes.map { TestTypeSetting(name: $0, isEnabled: true) }
                testTypeSettingsData = try? JSONEncoder().encode(initialSettings)
                return initialSettings
            }
            
            let settings = (try? JSONDecoder().decode([TestTypeSetting].self, from: data)) ?? []
            
            // 設定が空の場合、現在の検査種類から初期設定を作成
            if settings.isEmpty {
                let initialSettings = testTypes.map { TestTypeSetting(name: $0, isEnabled: true) }
                testTypeSettingsData = try? JSONEncoder().encode(initialSettings)
                return initialSettings
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
}

struct TestResultInput: Identifiable, Hashable {
    let id = UUID()
    var ear: String = "両耳"
    var condition: String = "裸耳"
    var thresholdsRight: [Int?] = Array(repeating: nil, count: 7)
    var thresholdsLeft: [Int?] = Array(repeating: nil, count: 7)
    var thresholdsBoth: [Int?] = Array(repeating: nil, count: 7)
    let earOptions = ["右耳のみ", "左耳のみ", "両耳"]
    let conditionOptions = ["裸耳", "補聴器・人工内耳"]
    let freqs = ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]

    func toResult() -> TestResult {
        TestResult(
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
        case ("両耳", "裸耳"):
            return .blue
        case ("両耳", "補聴器・人工内耳"):
            return .cyan
        case ("右耳のみ", "裸耳"):
            return .red
        case ("右耳のみ", "補聴器・人工内耳"):
            return .orange
        case ("左耳のみ", "裸耳"):
            return .green
        case ("左耳のみ", "補聴器・人工内耳"):
            return .mint
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
    var isCompleted: Bool
    var reminderEnabled: Bool
    var reminderTime: Date?
    
    init(hospital: String, appointmentDate: Date, appointmentTime: Date, purpose: String, notes: String = "", reminderEnabled: Bool = true) {
        self.id = UUID()
        self.hospital = hospital
        self.appointmentDate = appointmentDate
        self.appointmentTime = appointmentTime
        self.purpose = purpose
        self.notes = notes
        self.isCompleted = false
        self.reminderEnabled = reminderEnabled
        
        // デフォルトで1時間前にリマインダー設定
        if reminderEnabled {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: appointmentDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: appointmentTime)
            
            var combinedComponents = DateComponents()
            combinedComponents.year = dateComponents.year
            combinedComponents.month = dateComponents.month
            combinedComponents.day = dateComponents.day
            combinedComponents.hour = timeComponents.hour
            combinedComponents.minute = timeComponents.minute
            
            if let appointmentDateTime = calendar.date(from: combinedComponents) {
                self.reminderTime = calendar.date(byAdding: .hour, value: -1, to: appointmentDateTime)
            }
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
        
        let result = calendar.date(from: combinedComponents) ?? appointmentDate
        print("fullAppointmentDate計算: \(hospital) - 日付:\(appointmentDate) 時刻:\(appointmentTime) → 結果:\(result)")
        return result
    }
}
