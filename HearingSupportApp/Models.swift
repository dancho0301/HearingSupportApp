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

@Model
final class AppSettings {
    var id: UUID
    var hospitalListData: Data
    var testTypesData: Data
    
    init(hospitalList: [String] = ["千葉こども耳鼻科", "東京医大", "柏総合病院"], 
         testTypes: [String] = ["ABR検査", "OAE検査", "ASSR検査", "ピュアトーン聴力検査", "語音聴力検査", "インピーダンスオージオメトリー", "その他"]) {
        self.id = UUID()
        self.hospitalListData = (try? JSONEncoder().encode(hospitalList)) ?? Data()
        self.testTypesData = (try? JSONEncoder().encode(testTypes)) ?? Data()
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
