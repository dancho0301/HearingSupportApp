//
//  Record.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/06/01.
//


import SwiftUI

struct Record: Identifiable {
    let id = UUID()
    var date: Date
    var hospital: String
    var title: String
    var detail: String
    var results: [TestResult]
}

struct TestResult: Identifiable, Hashable {
    let id = UUID()
    var ear: String                 // 「右耳のみ」「左耳のみ」「両耳」
    var condition: String           // 「裸耳」「補聴器」「人工内耳」
    var thresholdsRight: [Int?]?
    var thresholdsLeft: [Int?]?
    var thresholdsBoth: [Int?]?     // 両耳のみ
    var freqs: [String]
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
