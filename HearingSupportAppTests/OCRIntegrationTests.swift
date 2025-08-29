//
//  OCRIntegrationTests.swift
//  HearingSupportAppTests
//
//  Created by dancho on 2025/08/20.
//

import XCTest
@testable import HearingSupportApp

final class OCRIntegrationTests: XCTestCase {
    
    override func setUpWithError() throws {
        // テストメソッド実行前のセットアップ
    }
    
    override func tearDownWithError() throws {
        // テストメソッド実行後のクリーンアップ
    }
    
    // MARK: - OCR機能統合テスト
    
    func testOCRToTestResultIntegration() throws {
        // 実際のオージオグラムテキストのサンプル
        let ocrText = """
        聴力検査結果
        
        気導聴力検査
        
        周波数   125Hz  250Hz  500Hz  1kHz   2kHz   4kHz   8kHz
        右耳 ○    25     30     35     40     45     50     55
        左耳 ×    20     25     30     35     40     45     50
        
        検査日: 2025年8月20日
        病院: 千葉利用者耳鼻科
        """
        
        // OCR解析を実行
        let parsedInput = HearingTestParser.parseOCRText(ocrText)
        
        XCTAssertNotNil(parsedInput, "OCRテキストが正常に解析されるべきです")
        
        guard let testInput = parsedInput else {
            XCTFail("OCR解析結果がnilです")
            return
        }
        
        // 解析結果の検証
        XCTAssertEqual(testInput.ear, "両耳", "両耳として認識されるべきです")
        XCTAssertEqual(testInput.condition, "裸耳", "デフォルトで裸耳として認識されるべきです")
        
        // 右耳データの検証
        XCTAssertTrue(testInput.thresholdsRight.contains { $0 != nil }, "右耳のデータが存在するべきです")
        
        // 左耳データの検証
        XCTAssertTrue(testInput.thresholdsLeft.contains { $0 != nil }, "左耳のデータが存在するべきです")
        
        // TestResultに変換
        let testResult = try testInput.toResult()
        
        // 変換結果の検証
        XCTAssertEqual(testResult.ear, "両耳", "TestResultの耳設定が正しく変換されるべきです")
        XCTAssertEqual(testResult.condition, "裸耳", "TestResultの条件設定が正しく変換されるべきです")
        XCTAssertEqual(testResult.freqs.count, 7, "周波数データが正しく設定されるべきです")
        
        // 両耳モードでは両耳のデータが設定されるべき
        XCTAssertNotNil(testResult.thresholdsBoth, "両耳モードでは両耳の閾値が設定されるべきです")
        XCTAssertNil(testResult.thresholdsRight, "両耳モードでは右耳個別の閾値は設定されないべきです")
        XCTAssertNil(testResult.thresholdsLeft, "両耳モードでは左耳個別の閾値は設定されないべきです")
    }
    
    func testOCRHearingAidIntegration() throws {
        let ocrText = """
        聴力検査結果 - 補聴器装用時
        
        気導聴力検査 (HA装用)
        右耳 ○ 15 20 25 30 35 40 45
        
        補聴器: リサウンド
        """
        
        let parsedInput = HearingTestParser.parseOCRText(ocrText)
        
        XCTAssertNotNil(parsedInput, "補聴器のOCRテキストが正常に解析されるべきです")
        
        guard let testInput = parsedInput else {
            XCTFail("OCR解析結果がnilです")
            return
        }
        
        XCTAssertEqual(testInput.condition, "補聴器", "補聴器として認識されるべきです")
        XCTAssertEqual(testInput.ear, "右耳のみ", "右耳のみとして認識されるべきです")
        
        let testResult = try testInput.toResult()
        XCTAssertEqual(testResult.condition, "補聴器", "TestResultに補聴器設定が正しく変換されるべきです")
        XCTAssertNotNil(testResult.thresholdsRight, "右耳のみの場合、右耳の閾値が設定されるべきです")
    }
    
    func testOCRCochlearImplantIntegration() throws {
        let ocrText = """
        人工内耳 聴力評価
        
        CI装用時聴力
        左耳 × 25 30 35 40 45 50 55
        
        機種: コクレア社 Nucleus
        """
        
        let parsedInput = HearingTestParser.parseOCRText(ocrText)
        
        XCTAssertNotNil(parsedInput, "人工内耳のOCRテキストが正常に解析されるべきです")
        
        guard let testInput = parsedInput else {
            XCTFail("OCR解析結果がnilです")
            return
        }
        
        XCTAssertEqual(testInput.condition, "人工内耳", "人工内耳として認識されるべきです")
        XCTAssertEqual(testInput.ear, "左耳のみ", "左耳のみとして認識されるべきです")
        
        let testResult = try testInput.toResult()
        XCTAssertEqual(testResult.condition, "人工内耳", "TestResultに人工内耳設定が正しく変換されるべきです")
        XCTAssertNotNil(testResult.thresholdsLeft, "左耳のみの場合、左耳の閾値が設定されるべきです")
    }
    
    func testOCRScaleOutIntegration() throws {
        let ocrText = """
        聴力検査結果
        
        右耳 ○ 25 30 35 ↓ 50 スケールアウト NR
        左耳 × 30 35 40 45 50 55 60
        
        備考: 右耳1kHzおよび4kHz以上でスケールアウト
        """
        
        let parsedInput = HearingTestParser.parseOCRText(ocrText)
        
        XCTAssertNotNil(parsedInput, "スケールアウトのOCRテキストが正常に解析されるべきです")
        
        guard let testInput = parsedInput else {
            XCTFail("OCR解析結果がnilです")
            return
        }
        
        XCTAssertEqual(testInput.ear, "両耳", "両耳として認識されるべきです")
        
        // スケールアウトで120dBが設定されているか確認
        XCTAssertTrue(testInput.thresholdsRight.contains(120), "スケールアウトで120dBが設定されるべきです")
        
        let testResult = try testInput.toResult()
        
        // TestResultでもスケールアウト値が保持されているか確認
        if let bothThresholds = testResult.thresholdsBoth {
            XCTAssertTrue(bothThresholds.contains(120), "TestResultでもスケールアウト値が保持されるべきです")
        } else {
            XCTFail("両耳の閾値データが設定されているべきです")
        }
    }
    
    // MARK: - エラーハンドリング統合テスト
    
    func testOCRErrorHandlingIntegration() throws {
        let invalidTexts = [
            "",  // 空文字
            "これは全く関係のないテキストです",  // 無関係なテキスト
            "オージオグラム",  // キーワードのみ
            "123 456 789",  // 数値のみ
            "聴力検査 右耳 左耳"  // キーワードのみ（数値なし）
        ]
        
        for invalidText in invalidTexts {
            let parsedInput = HearingTestParser.parseOCRText(invalidText)
            XCTAssertNil(parsedInput, "無効なテキスト '\(invalidText)' はnilを返すべきです")
        }
    }
    
    // MARK: - 複雑なケースの統合テスト
    
    func testComplexOCRIntegration() throws {
        let complexOcrText = """
        【聴力検査結果報告書】
        
        患者名: 田中太郎  検査日: 2025年8月20日
        病院: 東京医科大学附属病院 耳鼻咽喉科
        
        ■ 純音聴力検査（気導）
        測定条件: 防音室、校正済み audiometer
        
        周波数(Hz) |  125  |  250  |  500  | 1000  | 2000  | 4000  | 8000
        ------------|-------|-------|-------|-------|-------|-------|-------
        右耳   ○   |   20  |   25  |   30  |   35  |   40  |   45  |   50
        左耳   ×   |   25  |   30  |   35  |   40  |   45  |   50  |   55
        
        ■ 診断
        両側感音難聴（軽度～中等度）
        
        ■ 備考
        - 自覚症状: 騒音下での聞き取り困難
        - 推奨: 補聴器適応検査
        
        担当医師: 山田花子  [印]
        """
        
        let parsedInput = HearingTestParser.parseOCRText(complexOcrText)
        
        XCTAssertNotNil(parsedInput, "複雑なOCRテキストが正常に解析されるべきです")
        
        guard let testInput = parsedInput else {
            XCTFail("複雑なOCR解析結果がnilです")
            return
        }
        
        // 基本設定の確認
        XCTAssertEqual(testInput.ear, "両耳", "両耳として認識されるべきです")
        XCTAssertEqual(testInput.condition, "裸耳", "裸耳として認識されるべきです")
        
        // データが存在することを確認
        XCTAssertTrue(testInput.thresholdsRight.contains { $0 != nil }, "右耳のデータが存在するべきです")
        XCTAssertTrue(testInput.thresholdsLeft.contains { $0 != nil }, "左耳のデータが存在するべきです")
        
        // TestResultに変換してデータ整合性を確認
        let testResult = try testInput.toResult()
        
        XCTAssertEqual(testResult.ear, "両耳", "TestResultの耳設定が正しいべきです")
        XCTAssertNotNil(testResult.thresholdsBoth, "両耳の閾値データが設定されるべきです")
        
        // 周波数データの確認
        let expectedFreqs = ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        XCTAssertEqual(testResult.freqs, expectedFreqs, "周波数データが正しく設定されるべきです")
    }
    
    // MARK: - データ品質テスト
    
    func testOCRDataQualityAssurance() throws {
        let highQualityOcrText = """
        オージオグラム
        
        右耳 ○  15  20  25  30  35  40  45
        左耳 ×  10  15  20  25  30  35  40
        """
        
        let parsedInput = HearingTestParser.parseOCRText(highQualityOcrText)
        
        XCTAssertNotNil(parsedInput, "高品質OCRテキストが解析されるべきです")
        
        guard let testInput = parsedInput else {
            XCTFail("高品質OCR解析結果がnilです")
            return
        }
        
        // 7つの周波数すべてにデータが存在するか確認
        let rightDataCount = testInput.thresholdsRight.compactMap { $0 }.count
        let leftDataCount = testInput.thresholdsLeft.compactMap { $0 }.count
        
        XCTAssertGreaterThan(rightDataCount, 0, "右耳に少なくとも1つの閾値データが存在するべきです")
        XCTAssertGreaterThan(leftDataCount, 0, "左耳に少なくとも1つの閾値データが存在するべきです")
        
        // データ範囲の確認（-10dB ～ 120dB）
        for threshold in testInput.thresholdsRight.compactMap({ $0 }) {
            XCTAssertGreaterThanOrEqual(threshold, -10, "右耳の閾値は-10dB以上であるべきです")
            XCTAssertLessThanOrEqual(threshold, 120, "右耳の閾値は120dB以下であるべきです")
        }
        
        for threshold in testInput.thresholdsLeft.compactMap({ $0 }) {
            XCTAssertGreaterThanOrEqual(threshold, -10, "左耳の閾値は-10dB以上であるべきです")
            XCTAssertLessThanOrEqual(threshold, 120, "左耳の閾値は120dB以下であるべきです")
        }
        
        // TestResultに変換後のデータ整合性確認
        let testResult = try testInput.toResult()
        XCTAssertEqual(testResult.ear, testInput.ear, "耳設定がTestResultに正しく反映されるべきです")
        XCTAssertEqual(testResult.condition, testInput.condition, "条件設定がTestResultに正しく反映されるべきです")
    }
    
    // MARK: - パフォーマンステスト
    
    func testOCRIntegrationPerformance() throws {
        let sampleOcrText = """
        オージオグラム
        右耳 ○ 25 30 35 40 45 50 55
        左耳 × 20 25 30 35 40 45 50
        """
        
        measure {
            // OCRから最終的なTestResultまでの完全なフローを100回実行
            for _ in 0..<100 {
                if let parsedInput = HearingTestParser.parseOCRText(sampleOcrText) {
                    let _ = try? parsedInput.toResult()
                }
            }
        }
    }
}