//
//  HearingTestParserTests.swift
//  HearingSupportAppTests
//
//  Created by dancho on 2025/08/20.
//

import XCTest
@testable import HearingSupportApp

final class HearingTestParserTests: XCTestCase {
    
    override func setUpWithError() throws {
        // テストメソッド実行前のセットアップ
    }
    
    override func tearDownWithError() throws {
        // テストメソッド実行後のクリーンアップ
    }
    
    // MARK: - 基本的なオージオグラム解析テスト
    
    func testParseBasicAudiogramData() throws {
        // 基本的なオージオグラムデータ（右耳のみ）
        let audiogramText = """
        オージオグラム
        気導検査
        右耳 ○
        125Hz: 25dB
        250Hz: 30dB
        500Hz: 35dB
        1kHz: 40dB
        2kHz: 45dB
        4kHz: 50dB
        8kHz: 55dB
        """
        
        let result = HearingTestParser.parseOCRText(audiogramText)
        
        XCTAssertNotNil(result, "オージオグラムデータが解析されるべきです")
        XCTAssertEqual(result?.ear, "右耳のみ", "右耳のみとして認識されるべきです")
        XCTAssertEqual(result?.condition, "裸耳", "デフォルトで裸耳として認識されるべきです")
        
        // 右耳の閾値データが正しく解析されているか確認
        if let thresholds = result?.thresholdsRight {
            XCTAssertEqual(thresholds[0], 25, "125Hzの閾値が正しく解析されるべきです")
            XCTAssertEqual(thresholds[1], 30, "250Hzの閾値が正しく解析されるべきです")
            XCTAssertEqual(thresholds[2], 35, "500Hzの閾値が正しく解析されるべきです")
            XCTAssertEqual(thresholds[3], 40, "1kHzの閾値が正しく解析されるべきです")
            XCTAssertEqual(thresholds[4], 45, "2kHzの閾値が正しく解析されるべきです")
            XCTAssertEqual(thresholds[5], 50, "4kHzの閾値が正しく解析されるべきです")
            XCTAssertEqual(thresholds[6], 55, "8kHzの閾値が正しく解析されるべきです")
        } else {
            XCTFail("右耳の閾値データが設定されているべきです")
        }
    }
    
    func testParseBothEarsAudiogramData() throws {
        // 両耳のオージオグラムデータ
        let audiogramText = """
        聴力検査結果
        気導検査
        右耳 ○ 25 30 35 40 45 50 55
        左耳 × 20 25 30 35 40 45 50
        """
        
        let result = HearingTestParser.parseOCRText(audiogramText)
        
        XCTAssertNotNil(result, "両耳のオージオグラムデータが解析されるべきです")
        XCTAssertEqual(result?.ear, "両耳", "両耳として認識されるべきです")
        
        // 右耳と左耳のデータが正しく設定されているか確認
        XCTAssertTrue(result?.thresholdsRight.contains { $0 != nil } ?? false, "右耳のデータが設定されているべきです")
        XCTAssertTrue(result?.thresholdsLeft.contains { $0 != nil } ?? false, "左耳のデータが設定されているべきです")
    }
    
    func testParseLeftEarOnlyData() throws {
        // 左耳のみのデータ
        let audiogramText = """
        オージオグラム
        左耳のみ × 30 35 40 45 50 55 60
        """
        
        let result = HearingTestParser.parseOCRText(audiogramText)
        
        XCTAssertNotNil(result, "左耳のみのデータが解析されるべきです")
        XCTAssertEqual(result?.ear, "左耳のみ", "左耳のみとして認識されるべきです")
        
        if let thresholds = result?.thresholdsLeft {
            XCTAssertEqual(thresholds[0], 30, "125Hzの閾値が正しく解析されるべきです")
            XCTAssertEqual(thresholds[6], 60, "8kHzの閾値が正しく解析されるべきです")
        } else {
            XCTFail("左耳の閾値データが設定されているべきです")
        }
    }
    
    // MARK: - 補聴器・人工内耳検査のテスト
    
    func testParseHearingAidData() throws {
        let audiogramText = """
        オージオグラム
        補聴器装用時
        右耳 ○ 15 20 25 30 35 40 45
        """
        
        let result = HearingTestParser.parseOCRText(audiogramText)
        
        XCTAssertNotNil(result, "補聴器データが解析されるべきです")
        XCTAssertEqual(result?.condition, "補聴器", "補聴器として認識されるべきです")
    }
    
    func testParseCochlearImplantData() throws {
        let audiogramText = """
        聴力検査
        人工内耳装用時 CI
        左耳 × 20 25 30 35 40 45 50
        """
        
        let result = HearingTestParser.parseOCRText(audiogramText)
        
        XCTAssertNotNil(result, "人工内耳データが解析されるべきです")
        XCTAssertEqual(result?.condition, "人工内耳", "人工内耳として認識されるべきです")
    }
    
    // MARK: - スケールアウトのテスト
    
    func testParseScaleOutData() throws {
        let audiogramText = """
        オージオグラム
        右耳 ○ 25 30 ↓ 40 45 スケールアウト ↓
        """
        
        let result = HearingTestParser.parseOCRText(audiogramText)
        
        XCTAssertNotNil(result, "スケールアウトデータが解析されるべきです")
        
        if let thresholds = result?.thresholdsRight {
            XCTAssertEqual(thresholds[0], 25, "125Hzの閾値が正しく解析されるべきです")
            XCTAssertEqual(thresholds[1], 30, "250Hzの閾値が正しく解析されるべきです")
            // スケールアウトの場合は120dBに設定される
            XCTAssertTrue(thresholds.contains(120), "スケールアウト値が120dBに設定されるべきです")
        }
    }
    
    func testParseNRData() throws {
        let audiogramText = """
        気導検査
        左耳 × 35 40 45 NR NR 60 65
        """
        
        let result = HearingTestParser.parseOCRText(audiogramText)
        
        XCTAssertNotNil(result, "NR（無反応）データが解析されるべきです")
        
        if let thresholds = result?.thresholdsLeft {
            XCTAssertEqual(thresholds[0], 35, "125Hzの閾値が正しく解析されるべきです")
            XCTAssertEqual(thresholds[5], 60, "4kHzの閾値が正しく解析されるべきです")
        }
    }
    
    // MARK: - エラーケースのテスト
    
    func testParseInvalidData() throws {
        let invalidText = "これは無効なデータです"
        
        let result = HearingTestParser.parseOCRText(invalidText)
        
        XCTAssertNil(result, "無効なデータの場合はnilが返されるべきです")
    }
    
    func testParseEmptyData() throws {
        let emptyText = ""
        
        let result = HearingTestParser.parseOCRText(emptyText)
        
        XCTAssertNil(result, "空のデータの場合はnilが返されるべきです")
    }
    
    func testParseOnlyKeywordData() throws {
        let keywordOnlyText = "オージオグラム 聴力検査 気導"
        
        let result = HearingTestParser.parseOCRText(keywordOnlyText)
        
        XCTAssertNil(result, "キーワードのみで数値データがない場合はnilが返されるべきです")
    }
    
    // MARK: - 数値範囲のテスト
    
    func testParseValidThresholdRange() throws {
        let audiogramText = """
        オージオグラム
        右耳 ○ -10 0 10 25 50 75 120
        """
        
        let result = HearingTestParser.parseOCRText(audiogramText)
        
        XCTAssertNotNil(result, "有効な範囲内の数値が解析されるべきです")
        
        if let thresholds = result?.thresholdsRight {
            XCTAssertEqual(thresholds[0], -10, "負の値も正しく解析されるべきです")
            XCTAssertEqual(thresholds[1], 0, "0dBも正しく解析されるべきです")
            XCTAssertEqual(thresholds[6], 120, "120dBも正しく解析されるべきです")
        }
    }
    
    func testParseInvalidThresholdRange() throws {
        let audiogramText = """
        オージオグラム
        右耳 ○ 125 250 500 1000 2000 4000 8000
        """
        
        let result = HearingTestParser.parseOCRText(audiogramText)
        
        // 周波数の数値は閾値として認識されないはず
        if let result = result {
            let hasFrequencyAsThreshold = result.thresholdsRight.contains { threshold in
                guard let value = threshold else { return false }
                return [125, 250, 500, 1000, 2000, 4000, 8000].contains(value)
            }
            XCTAssertFalse(hasFrequencyAsThreshold, "周波数の値は閾値として認識されるべきではありません")
        }
    }
    
    // MARK: - 複合パターンのテスト
    
    func testParseComplexAudiogramData() throws {
        let complexText = """
        聴力検査結果 - 2025年8月20日
        病院：千葉こども耳鼻科
        
        気導聴力検査
        周波数  125Hz  250Hz  500Hz  1kHz   2kHz   4kHz   8kHz
        右耳 ○   20    25     30     35     40     45     50
        左耳 ×   25    30     35     40     ↓     55     NR
        
        備考：左耳2kHzでスケールアウト
        """
        
        let result = HearingTestParser.parseOCRText(complexText)
        
        XCTAssertNotNil(result, "複合的なオージオグラムデータが解析されるべきです")
        XCTAssertEqual(result?.ear, "両耳", "両耳として認識されるべきです")
        
        // 右耳データの確認
        if let rightThresholds = result?.thresholdsRight {
            XCTAssertTrue(rightThresholds.contains { $0 != nil }, "右耳のデータが設定されているべきです")
        }
        
        // 左耳データの確認
        if let leftThresholds = result?.thresholdsLeft {
            XCTAssertTrue(leftThresholds.contains { $0 != nil }, "左耳のデータが設定されているべきです")
        }
    }
    
    // MARK: - パフォーマンステスト
    
    func testParsingPerformance() throws {
        let sampleText = """
        オージオグラム
        右耳 ○ 25 30 35 40 45 50 55
        左耳 × 20 25 30 35 40 45 50
        """
        
        measure {
            // 100回の解析を実行してパフォーマンスを測定
            for _ in 0..<100 {
                _ = HearingTestParser.parseOCRText(sampleText)
            }
        }
    }
}