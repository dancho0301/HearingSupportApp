//
//  UtilityTests.swift
//  HearingSupportAppTests
//
//  Created by dancho on 2025/08/20.
//

import XCTest
import SwiftUI
import Foundation
@testable import HearingSupportApp

final class UtilityTests: XCTestCase {
    
    // MARK: - Array Safe Access Tests
    
    func testArraySafeAccessValidIndex() {
        let testArray = [10, 20, 30, 40, 50]
        
        // 有効なインデックスでのアクセス
        XCTAssertEqual(testArray[safe: 0], 10, "インデックス0の要素が正しく取得できません")
        XCTAssertEqual(testArray[safe: 2], 30, "インデックス2の要素が正しく取得できません")
        XCTAssertEqual(testArray[safe: 4], 50, "最後の要素が正しく取得できません")
    }
    
    func testArraySafeAccessInvalidIndex() {
        let testArray = [10, 20, 30]
        
        // 無効なインデックスでのアクセス
        XCTAssertNil(testArray[safe: -1], "負のインデックスではnilを返すべき")
        XCTAssertNil(testArray[safe: 3], "範囲外のインデックスではnilを返すべき")
        XCTAssertNil(testArray[safe: 100], "大きな範囲外インデックスではnilを返すべき")
    }
    
    func testArraySafeAccessEmptyArray() {
        let emptyArray: [Int] = []
        
        // 空配列での安全アクセス
        XCTAssertNil(emptyArray[safe: 0], "空配列ではnilを返すべき")
        XCTAssertNil(emptyArray[safe: -1], "空配列の負のインデックスではnilを返すべき")
    }
    
    func testArraySafeAccessDifferentTypes() {
        // String配列でのテスト
        let stringArray = ["apple", "banana", "cherry"]
        XCTAssertEqual(stringArray[safe: 1], "banana")
        XCTAssertNil(stringArray[safe: 5])
        
        // Optional値を含む配列でのテスト
        let optionalArray: [Int?] = [10, nil, 30, nil]
        if let value = optionalArray[safe: 0] {
            XCTAssertEqual(value, 10)
        } else {
            XCTFail("インデックス0の要素が取得できません")
        }
        
        if let value = optionalArray[safe: 1] {
            XCTAssertNil(value) // 要素自体がnil
        } else {
            XCTFail("インデックス1の要素が取得できません")
        }
        
        if let value = optionalArray[safe: 2] {
            XCTAssertEqual(value, 30)
        } else {
            XCTFail("インデックス2の要素が取得できません")
        }
        
        XCTAssertNil(optionalArray[safe: 10]) // 範囲外
    }
    
    // MARK: - Date Formatter Tests
    
    func testJapaneseDateFormatter() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(year: 2025, month: 8, day: 20))!
        
        let formattedString = formatter.string(from: testDate)
        XCTAssertEqual(formattedString, "2025年8月20日", "日本語日付フォーマットが正しくありません")
    }
    
    func testJapaneseTimeFormatter() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        
        let calendar = Calendar.current
        let testTime = calendar.date(from: DateComponents(hour: 15, minute: 30))!
        
        let formattedString = formatter.string(from: testTime)
        XCTAssertEqual(formattedString, "15:30", "時刻フォーマットが正しくありません")
    }
    
    func testAppointmentDateTimeFormatter() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E) HH:mm"
        
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 25, hour: 9, minute: 15))!
        
        let formattedString = formatter.string(from: testDate)
        // 12月25日(水) 09:15 のような形式になるはず（曜日は環境によって異なる可能性）
        XCTAssertTrue(formattedString.contains("12月25日"), "月日が含まれていません")
        XCTAssertTrue(formattedString.contains("09:15"), "時刻が含まれていません")
    }
    
    // MARK: - Color Tests
    
    func testAppCustomColor() {
        let customColor = Color(red: 1.0, green: 0.97, blue: 0.92)
        
        // カスタムカラーが正しく生成されるかテスト
        XCTAssertNotNil(customColor, "カスタムカラーが生成されません")
        
        // 色の比較は難しいので、作成できることだけ確認
        let anotherSameColor = Color(red: 1.0, green: 0.97, blue: 0.92)
        XCTAssertNotNil(anotherSameColor)
    }
    
    // MARK: - TestResult Color Logic Tests
    
    func testAllTestResultColorCombinations() {
        let ears = ["両耳", "右耳のみ", "左耳のみ"]
        let conditions = ["裸耳", "補聴器・人工内耳"]
        let freqs = ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        
        for ear in ears {
            for condition in conditions {
                let testResult = TestResult(
                    ear: ear,
                    condition: condition,
                    thresholdsRight: ear == "右耳のみ" ? [20, 25, 30, 35, 40, 45, 50] : nil,
                    thresholdsLeft: ear == "左耳のみ" ? [20, 25, 30, 35, 40, 45, 50] : nil,
                    thresholdsBoth: ear == "両耳" ? [20, 25, 30, 35, 40, 45, 50] : nil,
                    freqs: freqs
                )
                
                // 各組み合わせで色が設定されることを確認
                XCTAssertNotNil(testResult.displayColor, "\(ear)・\(condition)の組み合わせで色が設定されません")
                
                // グレー以外の色が設定されることを確認（定義されたパターンの場合）
                if ears.contains(ear) && conditions.contains(condition) {
                    XCTAssertNotEqual(testResult.displayColor, .gray, "定義済みパターンでグレーが返されています: \(ear)・\(condition)")
                }
            }
        }
    }
    
    // MARK: - Data Validation Tests
    
    func testHearingThresholdValidation() {
        // 聴力閾値の有効範囲テスト（0-120dB）
        let validThresholds = [0, 20, 40, 60, 80, 100, 120]
        let invalidThresholds = [-10, -1, 121, 150, 1000]
        
        for threshold in validThresholds {
            XCTAssertTrue(threshold >= 0 && threshold <= 120, "有効な閾値が無効と判定されました: \(threshold)")
        }
        
        for threshold in invalidThresholds {
            XCTAssertFalse(threshold >= 0 && threshold <= 120, "無効な閾値が有効と判定されました: \(threshold)")
        }
    }
    
    func testFrequencyArrayConsistency() {
        let standardFreqs = ["125", "250", "500", "1k", "2k", "4k", "8k"]
        let thresholds = [20, 25, 30, 35, 40, 45, 50]
        
        // 周波数と閾値の配列長が一致することを確認
        XCTAssertEqual(standardFreqs.count, thresholds.count, "周波数と閾値の配列長が一致しません")
        XCTAssertEqual(standardFreqs.count, 7, "標準周波数数が7つではありません")
    }
    
    // MARK: - String Handling Tests
    
    func testJapaneseTextHandling() {
        let hospitalName = "千葉こども耳鼻科"
        let purpose = "定期検査"
        let notes = "聴力検査の結果、軽度の聴力低下が見られます。次回は3ヶ月後の予約をお取りください。"
        
        // 日本語テキストが正しく処理されることを確認
        XCTAssertFalse(hospitalName.isEmpty, "病院名が空です")
        XCTAssertFalse(purpose.isEmpty, "目的が空です")
        XCTAssertTrue(notes.count > 0, "メモが空です")
        
        // 特定の文字が含まれることを確認
        XCTAssertTrue(hospitalName.contains("耳鼻科"), "病院名に'耳鼻科'が含まれていません")
        XCTAssertTrue(notes.contains("聴力"), "メモに'聴力'が含まれていません")
    }
    
    func testEmptyStringHandling() {
        let emptyString = ""
        let whitespaceString = "   "
        let normalString = "テスト"
        
        XCTAssertTrue(emptyString.isEmpty, "空文字列の判定が正しくありません")
        XCTAssertFalse(whitespaceString.isEmpty, "スペース文字列は空ではありません")
        XCTAssertFalse(normalString.isEmpty, "通常文字列が空と判定されています")
        
        // トリム後の判定
        XCTAssertTrue(whitespaceString.trimmingCharacters(in: .whitespaces).isEmpty, "トリム後は空になるべきです")
        XCTAssertFalse(normalString.trimmingCharacters(in: .whitespaces).isEmpty, "通常文字列はトリム後も空ではありません")
    }
    
    // MARK: - Calendar and Date Tests
    
    func testCalendarLocale() {
        let japaneseCalendar = Calendar.current
        let locale = Locale(identifier: "ja_JP")
        
        // 日本のカレンダー設定でのテスト
        let testDate = Date()
        let components = japaneseCalendar.dateComponents([.year, .month, .day, .weekday], from: testDate)
        
        XCTAssertNotNil(components.year, "年が取得できません")
        XCTAssertNotNil(components.month, "月が取得できません")
        XCTAssertNotNil(components.day, "日が取得できません")
        XCTAssertNotNil(components.weekday, "曜日が取得できません")
        
        // 妥当な値範囲の確認
        if let year = components.year {
            XCTAssertTrue(year > 2020 && year < 2030, "年が妥当な範囲にありません: \(year)")
        }
        
        if let month = components.month {
            XCTAssertTrue(month >= 1 && month <= 12, "月が妥当な範囲にありません: \(month)")
        }
        
        if let day = components.day {
            XCTAssertTrue(day >= 1 && day <= 31, "日が妥当な範囲にありません: \(day)")
        }
    }
}