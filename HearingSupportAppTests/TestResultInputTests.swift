//
//  TestResultInputTests.swift
//  HearingSupportAppTests
//
//  Created by dancho on 2025/08/20.
//

import XCTest
@testable import HearingSupportApp

final class TestResultInputTests: XCTestCase {
    
    override func setUpWithError() throws {
        // テストメソッド実行前のセットアップ
    }
    
    override func tearDownWithError() throws {
        // テストメソッド実行後のクリーンアップ
    }
    
    // MARK: - TestResultInput初期化テスト
    
    func testTestResultInputInitialization() throws {
        let testInput = TestResultInput()
        
        // デフォルト値の確認
        XCTAssertEqual(testInput.ear, "両耳", "デフォルトで両耳が選択されるべきです")
        XCTAssertEqual(testInput.condition, "裸耳", "デフォルトで裸耳が選択されるべきです")
        
        // 配列の初期化確認
        XCTAssertEqual(testInput.thresholdsRight.count, 7, "右耳の閾値配列は7要素であるべきです")
        XCTAssertEqual(testInput.thresholdsLeft.count, 7, "左耳の閾値配列は7要素であるべきです")
        XCTAssertEqual(testInput.thresholdsBoth.count, 7, "両耳の閾値配列は7要素であるべきです")
        
        // 初期値がnilであることを確認
        XCTAssertTrue(testInput.thresholdsRight.allSatisfy { $0 == nil }, "右耳の初期閾値はすべてnilであるべきです")
        XCTAssertTrue(testInput.thresholdsLeft.allSatisfy { $0 == nil }, "左耳の初期閾値はすべてnilであるべきです")
        XCTAssertTrue(testInput.thresholdsBoth.allSatisfy { $0 == nil }, "両耳の初期閾値はすべてnilであるべきです")
        
        // オプション配列の確認
        XCTAssertEqual(testInput.earOptions.count, 3, "耳のオプションは3つであるべきです")
        XCTAssertTrue(testInput.earOptions.contains("右耳のみ"), "右耳のみオプションが含まれるべきです")
        XCTAssertTrue(testInput.earOptions.contains("左耳のみ"), "左耳のみオプションが含まれるべきです")
        XCTAssertTrue(testInput.earOptions.contains("両耳"), "両耳オプションが含まれるべきです")
        
        XCTAssertEqual(testInput.conditionOptions.count, 2, "条件のオプションは2つであるべきです")
        XCTAssertTrue(testInput.conditionOptions.contains("裸耳"), "裸耳オプションが含まれるべきです")
        XCTAssertTrue(testInput.conditionOptions.contains("補聴器・人工内耳"), "補聴器・人工内耳オプションが含まれるべきです")
        
        // 周波数配列の確認
        XCTAssertEqual(testInput.freqs.count, 7, "周波数配列は7要素であるべきです")
        XCTAssertEqual(testInput.freqs[0], "125Hz", "最初の周波数は125Hzであるべきです")
        XCTAssertEqual(testInput.freqs[6], "8kHz", "最後の周波数は8kHzであるべきです")
    }
    
    // MARK: - TestResultへの変換テスト
    
    func testToResultRightEarOnly() throws {
        var testInput = TestResultInput()
        testInput.ear = "右耳のみ"
        testInput.condition = "補聴器・人工内耳"
        testInput.thresholdsRight = [25, 30, 35, 40, 45, 50, 55]
        
        let result = testInput.toResult()
        
        XCTAssertEqual(result.ear, "右耳のみ", "耳の設定が正しく変換されるべきです")
        XCTAssertEqual(result.condition, "補聴器・人工内耳", "条件の設定が正しく変換されるべきです")
        
        XCTAssertNotNil(result.thresholdsRight, "右耳の閾値が設定されるべきです")
        XCTAssertNil(result.thresholdsLeft, "左耳の閾値は設定されないべきです")
        XCTAssertNil(result.thresholdsBoth, "両耳の閾値は設定されないべきです")
        
        if let rightThresholds = result.thresholdsRight {
            XCTAssertEqual(rightThresholds[0], 25, "右耳125Hzの閾値が正しく変換されるべきです")
            XCTAssertEqual(rightThresholds[6], 55, "右耳8kHzの閾値が正しく変換されるべきです")
        }
    }
    
    func testToResultLeftEarOnly() throws {
        var testInput = TestResultInput()
        testInput.ear = "左耳のみ"
        testInput.condition = "裸耳"
        testInput.thresholdsLeft = [20, 25, 30, 35, 40, 45, 50]
        
        let result = testInput.toResult()
        
        XCTAssertEqual(result.ear, "左耳のみ", "耳の設定が正しく変換されるべきです")
        XCTAssertEqual(result.condition, "裸耳", "条件の設定が正しく変換されるべきです")
        
        XCTAssertNil(result.thresholdsRight, "右耳の閾値は設定されないべきです")
        XCTAssertNotNil(result.thresholdsLeft, "左耳の閾値が設定されるべきです")
        XCTAssertNil(result.thresholdsBoth, "両耳の閾値は設定されないべきです")
        
        if let leftThresholds = result.thresholdsLeft {
            XCTAssertEqual(leftThresholds[0], 20, "左耳125Hzの閾値が正しく変換されるべきです")
            XCTAssertEqual(leftThresholds[6], 50, "左耳8kHzの閾値が正しく変換されるべきです")
        }
    }
    
    func testToResultBothEars() throws {
        var testInput = TestResultInput()
        testInput.ear = "両耳"
        testInput.condition = "裸耳"
        testInput.thresholdsBoth = [15, 20, 25, 30, 35, 40, 45]
        
        let result = testInput.toResult()
        
        XCTAssertEqual(result.ear, "両耳", "耳の設定が正しく変換されるべきです")
        XCTAssertEqual(result.condition, "裸耳", "条件の設定が正しく変換されるべきです")
        
        XCTAssertNil(result.thresholdsRight, "右耳の閾値は設定されないべきです")
        XCTAssertNil(result.thresholdsLeft, "左耳の閾値は設定されないべきです")
        XCTAssertNotNil(result.thresholdsBoth, "両耳の閾値が設定されるべきです")
        
        if let bothThresholds = result.thresholdsBoth {
            XCTAssertEqual(bothThresholds[0], 15, "両耳125Hzの閾値が正しく変換されるべきです")
            XCTAssertEqual(bothThresholds[6], 45, "両耳8kHzの閾値が正しく変換されるべきです")
        }
    }
    
    // MARK: - Identifiableプロトコルテスト
    
    func testIdentifiableProtocol() throws {
        let testInput1 = TestResultInput()
        let testInput2 = TestResultInput()
        
        XCTAssertNotEqual(testInput1.id, testInput2.id, "異なるインスタンスは異なるIDを持つべきです")
    }
    
    // MARK: - Hashableプロトコルテスト
    
    func testHashableProtocol() throws {
        var testInput1 = TestResultInput()
        testInput1.ear = "右耳のみ"
        testInput1.condition = "裸耳"
        testInput1.thresholdsRight[0] = 25
        
        var testInput2 = TestResultInput()
        testInput2.ear = "右耳のみ"
        testInput2.condition = "裸耳"
        testInput2.thresholdsRight[0] = 25
        
        var testInput3 = TestResultInput()
        testInput3.ear = "左耳のみ"
        testInput3.condition = "裸耳"
        testInput3.thresholdsLeft[0] = 25
        
        // 同じ設定でも異なるIDを持つため、ハッシュ値は異なる
        XCTAssertNotEqual(testInput1.hashValue, testInput2.hashValue, "異なるIDを持つインスタンスは異なるハッシュ値を持つべきです")
        
        // 設定とそれぞれ異なる
        XCTAssertNotEqual(testInput1.hashValue, testInput3.hashValue, "異なる設定のインスタンスは異なるハッシュ値を持つべきです")
        
        // ハッシュセットで使用可能か確認
        var testSet = Set<TestResultInput>()
        testSet.insert(testInput1)
        testSet.insert(testInput2)
        testSet.insert(testInput3)
        
        XCTAssertEqual(testSet.count, 3, "すべて異なるインスタンスとして扱われるべきです")
    }
    
    // MARK: - 閾値データの更新テスト
    
    func testThresholdDataUpdate() throws {
        var testInput = TestResultInput()
        
        // 右耳の閾値を更新
        testInput.thresholdsRight[0] = 25
        testInput.thresholdsRight[3] = 40
        testInput.thresholdsRight[6] = 55
        
        XCTAssertEqual(testInput.thresholdsRight[0], 25, "右耳125Hzの閾値が更新されるべきです")
        XCTAssertEqual(testInput.thresholdsRight[3], 40, "右耳1kHzの閾値が更新されるべきです")
        XCTAssertEqual(testInput.thresholdsRight[6], 55, "右耳8kHzの閾値が更新されるべきです")
        
        // 更新していない要素はnilのまま
        XCTAssertNil(testInput.thresholdsRight[1], "更新していない要素はnilのままであるべきです")
        XCTAssertNil(testInput.thresholdsRight[2], "更新していない要素はnilのままであるべきです")
        XCTAssertNil(testInput.thresholdsRight[4], "更新していない要素はnilのままであるべきです")
        XCTAssertNil(testInput.thresholdsRight[5], "更新していない要素はnilのままであるべきです")
    }
    
    func testExtremThresholdValues() throws {
        var testInput = TestResultInput()
        
        // 極値をテスト
        testInput.thresholdsRight[0] = -10  // 最小値
        testInput.thresholdsRight[1] = 0    // ゼロ
        testInput.thresholdsRight[2] = 120  // 最大値
        
        let result = testInput.toResult()
        result.ear = "右耳のみ"
        
        if let rightThresholds = result.thresholdsRight {
            XCTAssertEqual(rightThresholds[0], -10, "負の閾値が正しく保持されるべきです")
            XCTAssertEqual(rightThresholds[1], 0, "ゼロの閾値が正しく保持されるべきです")
            XCTAssertEqual(rightThresholds[2], 120, "最大値の閾値が正しく保持されるべきです")
        }
    }
    
    // MARK: - 周波数データの検証テスト
    
    func testFrequencyData() throws {
        let testInput = TestResultInput()
        
        let expectedFrequencies = ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        
        XCTAssertEqual(testInput.freqs, expectedFrequencies, "周波数データが正しく設定されるべきです")
        
        // toResult()で周波数データが正しく引き継がれるか確認
        let result = testInput.toResult()
        XCTAssertEqual(result.freqs, expectedFrequencies, "TestResultに周波数データが正しく変換されるべきです")
    }
    
    // MARK: - 設定オプションの検証テスト
    
    func testEarOptions() throws {
        let testInput = TestResultInput()
        
        let expectedEarOptions = ["右耳のみ", "左耳のみ", "両耳"]
        XCTAssertEqual(Set(testInput.earOptions), Set(expectedEarOptions), "耳のオプションが正しく設定されるべきです")
        
        // 各オプションが有効な選択肢として機能するか確認
        for option in expectedEarOptions {
            var mutableTestInput = testInput
            mutableTestInput.ear = option
            XCTAssertEqual(mutableTestInput.ear, option, "\(option)が正しく設定されるべきです")
        }
    }
    
    func testConditionOptions() throws {
        let testInput = TestResultInput()
        
        let expectedConditionOptions = ["裸耳", "補聴器・人工内耳"]
        XCTAssertEqual(Set(testInput.conditionOptions), Set(expectedConditionOptions), "条件のオプションが正しく設定されるべきです")
        
        // 各オプションが有効な選択肢として機能するか確認
        for option in expectedConditionOptions {
            var mutableTestInput = testInput
            mutableTestInput.condition = option
            XCTAssertEqual(mutableTestInput.condition, option, "\(option)が正しく設定されるべきです")
        }
    }
}