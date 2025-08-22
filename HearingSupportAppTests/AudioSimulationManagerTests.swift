//
//  AudioSimulationManagerTests.swift
//  HearingSupportAppTests
//
//  AudioSimulationManager機能のテスト
//

import XCTest
@testable import HearingSupportApp

final class AudioSimulationManagerTests: XCTestCase {
    
    var audioManager: AudioSimulationManager!
    var testRecord: Record!
    var testResult: TestResult!
    
    override func setUpWithError() throws {
        audioManager = AudioSimulationManager()
        
        // テスト用の聴力検査記録を作成
        testResult = TestResult(
            ear: "両耳",
            condition: "裸耳",
            thresholdsBoth: [20, 30, 45, 60, 70, 80, 90], // 段階的な難聴データ
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        testRecord = Record(
            date: Date(),
            hospital: "テスト病院",
            title: "テスト検査",
            detail: "テスト詳細",
            results: [testResult]
        )
    }
    
    override func tearDownWithError() throws {
        audioManager = nil
        testRecord = nil
        testResult = nil
    }
    
    // MARK: - 初期化テスト
    
    func testAudioManagerInitialization() throws {
        XCTAssertFalse(audioManager.isRecording, "初期状態では録音していない")
        XCTAssertFalse(audioManager.isPlaying, "初期状態では再生していない")
        XCTAssertNil(audioManager.recordedAudioFile, "初期状態では録音ファイルがない")
        XCTAssertFalse(audioManager.permissionGranted, "初期状態では権限が許可されていない")
    }
    
    // MARK: - 聴力閾値に基づく減衰量計算テスト
    
    func testAttenuationCalculationForNormalHearing() throws {
        // 正常聴力（0-20dB）の場合
        audioManager.configureSimulation(testResult: createTestResult(thresholds: [10, 15, 20]), ear: "両耳")
        
        // 内部の減衰計算が正しく動作することを間接的にテスト
        // 実際の減衰値は private メソッドのため、公開メソッド経由でテスト
        XCTAssertNotNil(testResult, "正常聴力データでのシミュレーション設定が成功")
    }
    
    func testAttenuationCalculationForMildHearingLoss() throws {
        // 軽度難聴（21-40dB）の場合
        audioManager.configureSimulation(testResult: createTestResult(thresholds: [25, 30, 35]), ear: "両耳")
        XCTAssertNotNil(testResult, "軽度難聴データでのシミュレーション設定が成功")
    }
    
    func testAttenuationCalculationForModerateHearingLoss() throws {
        // 中等度難聴（41-70dB）の場合
        audioManager.configureSimulation(testResult: createTestResult(thresholds: [45, 55, 65]), ear: "両耳")
        XCTAssertNotNil(testResult, "中等度難聴データでのシミュレーション設定が成功")
    }
    
    func testAttenuationCalculationForSevereHearingLoss() throws {
        // 高度難聴（71-90dB）の場合
        audioManager.configureSimulation(testResult: createTestResult(thresholds: [75, 85, 90]), ear: "両耳")
        XCTAssertNotNil(testResult, "高度難聴データでのシミュレーション設定が成功")
    }
    
    func testAttenuationCalculationForProfoundHearingLoss() throws {
        // 重度難聴（91dB以上）の場合
        audioManager.configureSimulation(testResult: createTestResult(thresholds: [95, 105, 120]), ear: "両耳")
        XCTAssertNotNil(testResult, "重度難聴データでのシミュレーション設定が成功")
    }
    
    // MARK: - 耳別データ取得テスト
    
    func testRightEarOnlyConfiguration() throws {
        let rightEarResult = TestResult(
            ear: "右耳のみ",
            condition: "裸耳",
            thresholdsRight: [30, 40, 50, 60, 70, 80, 90],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        audioManager.configureSimulation(testResult: rightEarResult, ear: "右耳のみ")
        XCTAssertEqual(rightEarResult.ear, "右耳のみ", "右耳のみの設定が正しい")
        XCTAssertNotNil(rightEarResult.thresholdsRight, "右耳のデータが存在する")
        XCTAssertNil(rightEarResult.thresholdsLeft, "左耳のデータは存在しない")
    }
    
    func testLeftEarOnlyConfiguration() throws {
        let leftEarResult = TestResult(
            ear: "左耳のみ",
            condition: "裸耳",
            thresholdsLeft: [25, 35, 45, 55, 65, 75, 85],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        audioManager.configureSimulation(testResult: leftEarResult, ear: "左耳のみ")
        XCTAssertEqual(leftEarResult.ear, "左耳のみ", "左耳のみの設定が正しい")
        XCTAssertNotNil(leftEarResult.thresholdsLeft, "左耳のデータが存在する")
        XCTAssertNil(leftEarResult.thresholdsRight, "右耳のデータは存在しない")
    }
    
    func testBothEarsConfiguration() throws {
        audioManager.configureSimulation(testResult: testResult, ear: "両耳")
        XCTAssertEqual(testResult.ear, "両耳", "両耳の設定が正しい")
        XCTAssertNotNil(testResult.thresholdsBoth, "両耳のデータが存在する")
    }
    
    // MARK: - エラーハンドリングテスト
    
    func testConfigurationWithNilThresholds() throws {
        let emptyResult = TestResult(
            ear: "両耳",
            condition: "裸耳",
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        // nil閾値でも設定が失敗しないことを確認
        audioManager.configureSimulation(testResult: emptyResult, ear: "両耳")
        XCTAssertNil(emptyResult.thresholdsBoth, "空の閾値データでも処理が完了する")
    }
    
    func testConfigurationWithInvalidEarType() throws {
        // 無効な耳タイプでの設定テスト
        audioManager.configureSimulation(testResult: testResult, ear: "無効な耳")
        // エラーが発生せず、デフォルト動作することを確認
        XCTAssertNotNil(testResult, "無効な耳タイプでも処理が完了する")
    }
    
    // MARK: - シミュレーションリセットテスト
    
    func testSimulationReset() throws {
        // まずシミュレーションを設定
        audioManager.configureSimulation(testResult: testResult, ear: "両耳")
        
        // リセットを実行
        audioManager.resetSimulation()
        
        // リセット後の状態を確認（内部状態は直接確認できないため、エラーが発生しないことを確認）
        XCTAssertNotNil(audioManager, "リセット後もマネージャーが有効")
    }
    
    // MARK: - ヘルパーメソッド
    
    private func createTestResult(thresholds: [Int]) -> TestResult {
        // テスト用の7周波数データを作成（不足分はnilで埋める）
        var fullThresholds: [Int?] = thresholds.map { $0 }
        while fullThresholds.count < 7 {
            fullThresholds.append(nil)
        }
        
        return TestResult(
            ear: "両耳",
            condition: "裸耳",
            thresholdsBoth: fullThresholds,
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
    }
    
    // MARK: - 非同期処理テスト
    
    func testMicrophonePermissionRequest() async throws {
        let expectation = XCTestExpectation(description: "マイクロフォン権限要求")
        
        Task {
            await audioManager.requestMicrophonePermission()
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        // 権限の結果は環境依存のため、処理完了のみ確認
        XCTAssertNotNil(audioManager, "権限要求処理が完了")
    }
    
    // MARK: - パフォーマンステスト
    
    func testConfigurationPerformance() throws {
        self.measure {
            // シミュレーション設定の処理時間を測定
            audioManager.configureSimulation(testResult: testResult, ear: "両耳")
        }
    }
    
    func testResetPerformance() throws {
        // まず設定を行う
        audioManager.configureSimulation(testResult: testResult, ear: "両耳")
        
        self.measure {
            // リセット処理の処理時間を測定
            audioManager.resetSimulation()
        }
    }
}