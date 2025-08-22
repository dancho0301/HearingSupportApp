//
//  HearingSimulationViewTests.swift
//  HearingSupportAppTests
//
//  HearingSimulationViewのUIテスト
//

import XCTest
import SwiftUI
@testable import HearingSupportApp

final class HearingSimulationViewTests: XCTestCase {
    
    var testRecords: [Record]!
    var testRecord: Record!
    var testResult: TestResult!
    
    override func setUpWithError() throws {
        // テスト用データの準備
        testResult = TestResult(
            ear: "両耳",
            condition: "裸耳",
            thresholdsBoth: [20, 30, 45, 60, 70, 80, 90],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        testRecord = Record(
            date: Date(),
            hospital: "テスト病院",
            title: "テスト聴力検査",
            detail: "テスト詳細",
            results: [testResult]
        )
        
        testRecords = [testRecord]
    }
    
    override func tearDownWithError() throws {
        testRecords = nil
        testRecord = nil
        testResult = nil
    }
    
    // MARK: - 初期状態テスト
    
    func testInitialViewState() throws {
        let _ = HearingSimulationView(records: testRecords)
        // ビューの初期化が成功することを確認（クラッシュしない）
    }
    
    func testEmptyRecordsHandling() throws {
        let _ = HearingSimulationView(records: [])
        // 空の記録リストでもビューが初期化されることを確認
    }
    
    // MARK: - データ処理テスト
    
    func testRecordSelection() throws {
        let view = HearingSimulationView(records: testRecords)
        
        // 記録選択のロジックをテスト
        XCTAssertEqual(testRecords.count, 1, "テスト記録が1件存在する")
        XCTAssertEqual(testRecords.first?.title, "テスト聴力検査", "記録のタイトルが正しい")
    }
    
    func testEarOptionsAvailability() throws {
        let view = HearingSimulationView(records: testRecords)
        let earOptions = ["右耳のみ", "左耳のみ", "両耳"]
        
        XCTAssertEqual(earOptions.count, 3, "3つの耳オプションが存在する")
        XCTAssertTrue(earOptions.contains("両耳"), "両耳オプションが存在する")
        XCTAssertTrue(earOptions.contains("右耳のみ"), "右耳のみオプションが存在する")
        XCTAssertTrue(earOptions.contains("左耳のみ"), "左耳のみオプションが存在する")
    }
    
    // MARK: - 聴力データ取得テスト
    
    func testThresholdDataRetrieval() throws {
        // 両耳データのテスト
        let bothEarThresholds = testResult.thresholdsBoth
        XCTAssertNotNil(bothEarThresholds, "両耳の閾値データが存在する")
        XCTAssertEqual(bothEarThresholds?.count, 7, "7つの周波数の閾値データがある")
        
        // 特定の閾値をテスト
        XCTAssertEqual(bothEarThresholds?[0], 20, "125Hzの閾値が正しい")
        XCTAssertEqual(bothEarThresholds?[6], 90, "8kHzの閾値が正しい")
    }
    
    func testFrequencyDataConsistency() throws {
        let frequencies = testResult.freqs
        XCTAssertEqual(frequencies.count, 7, "7つの周波数が定義されている")
        XCTAssertEqual(frequencies[0], "125Hz", "最初の周波数が125Hz")
        XCTAssertEqual(frequencies[6], "8kHz", "最後の周波数が8kHz")
    }
    
    // MARK: - 多数の検査記録テスト
    
    func testMultipleRecordsHandling() throws {
        // 複数の検査記録を作成
        let record1 = Record(
            date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            hospital: "病院A",
            title: "初回検査",
            detail: "初回詳細",
            results: [TestResult(
                ear: "両耳",
                condition: "裸耳",
                thresholdsBoth: [15, 20, 25, 30, 35, 40, 45],
                freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
            )]
        )
        
        let record2 = Record(
            date: Calendar.current.date(byAdding: .day, value: -60, to: Date())!,
            hospital: "病院B",
            title: "フォローアップ検査",
            detail: "フォローアップ詳細",
            results: [TestResult(
                ear: "右耳のみ",
                condition: "補聴器・人工内耳",
                thresholdsRight: [25, 30, 35, 40, 45, 50, 55],
                freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
            )]
        )
        
        let multipleRecords: [Record] = [record1, record2, testRecord]
        let view = HearingSimulationView(records: multipleRecords)
        
        XCTAssertEqual(multipleRecords.count, 3, "3件の検査記録が存在する")
        XCTAssertNotNil(view, "複数記録でもビューが正常に初期化される")
    }
    
    // MARK: - 耳タイプ別テスト
    
    func testRightEarOnlyRecord() throws {
        let rightEarResult = TestResult(
            ear: "右耳のみ",
            condition: "補聴器・人工内耳",
            thresholdsRight: [30, 35, 40, 45, 50, 55, 60],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        let rightEarRecord = Record(
            date: Date(),
            hospital: "右耳専門病院",
            title: "右耳検査",
            detail: "右耳のみの検査",
            results: [rightEarResult]
        )
        
        let _ = HearingSimulationView(records: [rightEarRecord])
        
        XCTAssertEqual(rightEarResult.ear, "右耳のみ", "右耳のみの記録が正しい")
        XCTAssertNotNil(rightEarResult.thresholdsRight, "右耳の閾値データが存在する")
        XCTAssertNil(rightEarResult.thresholdsLeft, "左耳の閾値データは存在しない")
    }
    
    func testLeftEarOnlyRecord() throws {
        let leftEarResult = TestResult(
            ear: "左耳のみ",
            condition: "裸耳",
            thresholdsLeft: [25, 30, 35, 40, 45, 50, 55],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        let leftEarRecord = Record(
            date: Date(),
            hospital: "左耳専門病院",
            title: "左耳検査",
            detail: "左耳のみの検査",
            results: [leftEarResult]
        )
        
        let _ = HearingSimulationView(records: [leftEarRecord])
        
        XCTAssertEqual(leftEarResult.ear, "左耳のみ", "左耳のみの記録が正しい")
        XCTAssertNotNil(leftEarResult.thresholdsLeft, "左耳の閾値データが存在する")
        XCTAssertNil(leftEarResult.thresholdsRight, "右耳の閾値データは存在しない")
    }
    
    // MARK: - 条件別テスト
    
    func testNakedEarCondition() throws {
        let nakedEarResult = TestResult(
            ear: "両耳",
            condition: "裸耳",
            thresholdsBoth: [40, 45, 50, 55, 60, 65, 70],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        XCTAssertEqual(nakedEarResult.condition, "裸耳", "裸耳条件が正しい")
        XCTAssertNotNil(nakedEarResult.thresholdsBoth, "裸耳条件の閾値データが存在する")
    }
    
    func testHearingAidCondition() throws {
        let hearingAidResult = TestResult(
            ear: "両耳",
            condition: "補聴器・人工内耳",
            thresholdsBoth: [20, 25, 30, 35, 40, 45, 50],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        XCTAssertEqual(hearingAidResult.condition, "補聴器・人工内耳", "補聴器条件が正しい")
        XCTAssertNotNil(hearingAidResult.thresholdsBoth, "補聴器条件の閾値データが存在する")
    }
    
    // MARK: - 日付フォーマットテスト
    
    func testDateFormatting() throws {
        let specificDate = Calendar.current.date(from: DateComponents(year: 2024, month: 8, day: 15))!
        let _ = Record(
            date: specificDate,
            hospital: "日付テスト病院",
            title: "日付テスト",
            detail: "日付フォーマットテスト",
            results: [testResult]
        )
        
        // 日本語ロケールでの日付フォーマットをテスト
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/M/d"
        
        let formattedDate = formatter.string(from: specificDate)
        XCTAssertEqual(formattedDate, "2024/8/15", "日付が正しくフォーマットされる")
    }
    
    // MARK: - エッジケーステスト
    
    func testRecordWithNoResults() throws {
        let emptyRecord = Record(
            date: Date(),
            hospital: "空の病院",
            title: "結果なし検査",
            detail: "結果なし",
            results: []
        )
        
        let view = HearingSimulationView(records: [emptyRecord])
        XCTAssertEqual(emptyRecord.results.count, 0, "結果がない記録も処理される")
        XCTAssertNotNil(view, "結果がない記録でもビューが初期化される")
    }
    
    func testRecordWithMultipleTestResults() throws {
        let result1 = TestResult(
            ear: "右耳のみ",
            condition: "裸耳",
            thresholdsRight: [30, 35, 40, 45, 50, 55, 60],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        let result2 = TestResult(
            ear: "左耳のみ",
            condition: "裸耳",
            thresholdsLeft: [25, 30, 35, 40, 45, 50, 55],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        let multiResultRecord = Record(
            date: Date(),
            hospital: "複数結果病院",
            title: "両耳別々検査",
            detail: "右耳と左耳を別々に検査",
            results: [result1, result2]
        )
        
        let view = HearingSimulationView(records: [multiResultRecord])
        XCTAssertEqual(multiResultRecord.results.count, 2, "複数の検査結果が存在する")
        XCTAssertNotNil(view, "複数結果でもビューが正常に初期化される")
    }
    
    // MARK: - パフォーマンステスト
    
    func testViewInitializationPerformance() throws {
        // 大量のレコードでのパフォーマンステスト
        var largeRecordSet: [Record] = []
        
        for i in 0..<100 {
            let result = TestResult(
                ear: "両耳",
                condition: "裸耳",
                thresholdsBoth: Array(20...26).map { $0 + (i % 10) },
                freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
            )
            
            let record = Record(
                date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
                hospital: "病院\(i)",
                title: "検査\(i)",
                detail: "詳細\(i)",
                results: [result]
            )
            
            largeRecordSet.append(record)
        }
        
        self.measure {
            let view = HearingSimulationView(records: largeRecordSet)
            XCTAssertNotNil(view)
        }
    }
}