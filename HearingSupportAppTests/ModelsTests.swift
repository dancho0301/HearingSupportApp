//
//  ModelsTests.swift
//  HearingSupportAppTests
//
//  Created by dancho on 2025/08/20.
//

import XCTest
import SwiftUI
import SwiftData
@testable import HearingSupportApp

final class ModelsTests: XCTestCase {
    
    // MARK: - TestResult Tests
    
    func testTestResultDisplayColor() {
        // 両耳・裸耳 -> 青
        let bothEarsNaked = TestResult(
            ear: "両耳",
            condition: "裸耳",
            thresholdsRight: nil,
            thresholdsLeft: nil,
            thresholdsBoth: [20, 25, 30, 35, 40, 45, 50],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        XCTAssertEqual(bothEarsNaked.displayColor, .blue)
        
        // 右耳のみ・裸耳 -> 赤
        let rightEarNaked = TestResult(
            ear: "右耳のみ",
            condition: "裸耳",
            thresholdsRight: [20, 25, 30, 35, 40, 45, 50],
            thresholdsLeft: nil,
            thresholdsBoth: nil,
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        XCTAssertEqual(rightEarNaked.displayColor, .red)
        
        // 左耳のみ・補聴器・人工内耳 -> mint
        let leftEarAided = TestResult(
            ear: "左耳のみ",
            condition: "補聴器・人工内耳",
            thresholdsRight: nil,
            thresholdsLeft: [15, 20, 25, 30, 35, 40, 45],
            thresholdsBoth: nil,
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        XCTAssertEqual(leftEarAided.displayColor, .mint)
        
        // 未定義パターン -> グレー
        let unknownPattern = TestResult(
            ear: "不明",
            condition: "不明",
            thresholdsRight: nil,
            thresholdsLeft: nil,
            thresholdsBoth: nil,
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        XCTAssertEqual(unknownPattern.displayColor, .gray)
    }
    
    func testTestResultGraphData() {
        let testData = [20, 25, 30, 35, 40, 45, 50]
        
        // 右耳のみ -> thresholdsRightを返す
        let rightEar = TestResult(
            ear: "右耳のみ",
            condition: "裸耳",
            thresholdsRight: testData,
            thresholdsLeft: nil,
            thresholdsBoth: nil,
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        XCTAssertEqual(rightEar.graphData, testData)
        
        // 左耳のみ -> thresholdsLeftを返す
        let leftEar = TestResult(
            ear: "左耳のみ",
            condition: "裸耳",
            thresholdsRight: nil,
            thresholdsLeft: testData,
            thresholdsBoth: nil,
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        XCTAssertEqual(leftEar.graphData, testData)
        
        // 両耳 -> thresholdsBothを返す
        let bothEars = TestResult(
            ear: "両耳",
            condition: "裸耳",
            thresholdsRight: nil,
            thresholdsLeft: nil,
            thresholdsBoth: testData,
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        XCTAssertEqual(bothEars.graphData, testData)
        
        // 不明 -> nilを返す
        let unknownEar = TestResult(
            ear: "不明",
            condition: "裸耳",
            thresholdsRight: testData,
            thresholdsLeft: testData,
            thresholdsBoth: testData,
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        XCTAssertNil(unknownEar.graphData)
    }
    
    func testTestResultDisplayLabel() {
        let testResult = TestResult(
            ear: "右耳のみ",
            condition: "補聴器・人工内耳",
            thresholdsRight: [20, 25, 30, 35, 40, 45, 50],
            thresholdsLeft: nil,
            thresholdsBoth: nil,
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        XCTAssertEqual(testResult.displayLabel, "右耳のみ・補聴器・人工内耳")
    }
    
    // MARK: - TestResultInput Tests
    
    func testTestResultInputConversion() {
        var input = TestResultInput()
        input.ear = "右耳のみ"
        input.condition = "裸耳"
        
        // 右耳のデータを設定
        input.thresholdsRight = [20, 25, 30, 35, 40, 45, 50]
        
        let testResult = input.toResult()
        
        XCTAssertEqual(testResult.ear, "右耳のみ")
        XCTAssertEqual(testResult.condition, "裸耳")
        XCTAssertEqual(testResult.thresholdsRight, [20, 25, 30, 35, 40, 45, 50])
        XCTAssertNil(testResult.thresholdsLeft)
        XCTAssertNil(testResult.thresholdsBoth)
        XCTAssertEqual(testResult.freqs, ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"])
    }
    
    func testTestResultInputBothEarsConversion() {
        var input = TestResultInput()
        input.ear = "両耳"
        input.condition = "補聴器・人工内耳"
        
        // 両耳のデータを設定
        input.thresholdsBoth = [15, 20, 25, 30, 35, 40, 45]
        
        let testResult = input.toResult()
        
        XCTAssertEqual(testResult.ear, "両耳")
        XCTAssertEqual(testResult.condition, "補聴器・人工内耳")
        XCTAssertNil(testResult.thresholdsRight)
        XCTAssertNil(testResult.thresholdsLeft)
        XCTAssertEqual(testResult.thresholdsBoth, [15, 20, 25, 30, 35, 40, 45])
    }
    
    // MARK: - Record Tests
    
    func testRecordInitialization() {
        let date = Date()
        let hospital = "テスト病院"
        let title = "定期検査"
        let detail = "年次健診"
        
        let testResult = TestResult(
            ear: "両耳",
            condition: "裸耳",
            thresholdsRight: nil,
            thresholdsLeft: nil,
            thresholdsBoth: [20, 25, 30, 35, 40, 45, 50],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        let record = Record(
            date: date,
            hospital: hospital,
            title: title,
            detail: detail,
            results: [testResult]
        )
        
        XCTAssertEqual(record.date, date)
        XCTAssertEqual(record.hospital, hospital)
        XCTAssertEqual(record.title, title)
        XCTAssertEqual(record.detail, detail)
        XCTAssertEqual(record.results.count, 1)
        XCTAssertEqual(record.results.first?.ear, "両耳")
    }
    
    // MARK: - Appointment Tests
    
    func testAppointmentInitialization() {
        let appointmentDate = Date()
        let appointmentTime = Date()
        let hospital = "千葉こども耳鼻科"
        let purpose = "定期検査"
        let notes = "聴力検査予定"
        
        let appointment = Appointment(
            hospital: hospital,
            appointmentDate: appointmentDate,
            appointmentTime: appointmentTime,
            purpose: purpose,
            notes: notes,
            reminderEnabled: true
        )
        
        XCTAssertEqual(appointment.hospital, hospital)
        XCTAssertEqual(appointment.appointmentDate, appointmentDate)
        XCTAssertEqual(appointment.appointmentTime, appointmentTime)
        XCTAssertEqual(appointment.purpose, purpose)
        XCTAssertEqual(appointment.notes, notes)
        XCTAssertTrue(appointment.reminderEnabled)
        XCTAssertFalse(appointment.isCompleted)
        XCTAssertNotNil(appointment.reminderTime)
    }
    
    func testAppointmentFullAppointmentDate() {
        let calendar = Calendar.current
        
        // 2025年8月20日
        let appointmentDate = calendar.date(from: DateComponents(year: 2025, month: 8, day: 20))!
        // 15:30
        let appointmentTime = calendar.date(from: DateComponents(hour: 15, minute: 30))!
        
        let appointment = Appointment(
            hospital: "テスト病院",
            appointmentDate: appointmentDate,
            appointmentTime: appointmentTime,
            purpose: "検査",
            reminderEnabled: false
        )
        
        let fullDate = appointment.fullAppointmentDate
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fullDate)
        
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 8)
        XCTAssertEqual(components.day, 20)
        XCTAssertEqual(components.hour, 15)
        XCTAssertEqual(components.minute, 30)
    }
    
    func testAppointmentReminderTime() {
        let calendar = Calendar.current
        
        // 2025年8月20日 15:00
        let appointmentDate = calendar.date(from: DateComponents(year: 2025, month: 8, day: 20))!
        let appointmentTime = calendar.date(from: DateComponents(hour: 15, minute: 0))!
        
        let appointment = Appointment(
            hospital: "テスト病院",
            appointmentDate: appointmentDate,
            appointmentTime: appointmentTime,
            purpose: "検査",
            reminderEnabled: true
        )
        
        guard let reminderTime = appointment.reminderTime else {
            XCTFail("リマインダー時刻が設定されていません")
            return
        }
        
        let reminderComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        
        // 1時間前（14:00）になっているかチェック
        XCTAssertEqual(reminderComponents.year, 2025)
        XCTAssertEqual(reminderComponents.month, 8)
        XCTAssertEqual(reminderComponents.day, 20)
        XCTAssertEqual(reminderComponents.hour, 14)
        XCTAssertEqual(reminderComponents.minute, 0)
    }
    
    func testAppointmentNoReminder() {
        let appointment = Appointment(
            hospital: "テスト病院",
            appointmentDate: Date(),
            appointmentTime: Date(),
            purpose: "検査",
            reminderEnabled: false
        )
        
        XCTAssertNil(appointment.reminderTime)
    }
}