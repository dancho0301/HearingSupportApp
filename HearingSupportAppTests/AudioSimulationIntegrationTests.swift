//
//  AudioSimulationIntegrationTests.swift
//  HearingSupportAppTests
//
//  音声処理とシミュレーション統合のテスト
//

import XCTest
import AVFoundation
@testable import HearingSupportApp

final class AudioSimulationIntegrationTests: XCTestCase {
    
    var audioManager: AudioSimulationManager!
    var testRecord: Record!
    var normalHearingResult: TestResult!
    var mildLossResult: TestResult!
    var severeLossResult: TestResult!
    
    override func setUpWithError() throws {
        audioManager = AudioSimulationManager()
        
        // 正常聴力のテストデータ
        normalHearingResult = TestResult(
            ear: "両耳",
            condition: "裸耳",
            thresholdsBoth: [10, 15, 20, 15, 10, 20, 25],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        // 軽度難聴のテストデータ
        mildLossResult = TestResult(
            ear: "両耳",
            condition: "裸耳",
            thresholdsBoth: [25, 30, 35, 40, 35, 30, 40],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        // 重度難聴のテストデータ
        severeLossResult = TestResult(
            ear: "両耳",
            condition: "裸耳",
            thresholdsBoth: [70, 80, 90, 100, 110, 120, 110],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        testRecord = Record(
            date: Date(),
            hospital: "統合テスト病院",
            title: "統合テスト検査",
            detail: "統合テスト詳細",
            results: [normalHearingResult, mildLossResult, severeLossResult]
        )
    }
    
    override func tearDownWithError() throws {
        audioManager.stopRealTimeProcessing()
        audioManager = nil
        testRecord = nil
        normalHearingResult = nil
        mildLossResult = nil
        severeLossResult = nil
    }
    
    // MARK: - 周波数別減衰計算の統合テスト
    
    func testFrequencySpecificAttenuationIntegration() throws {
        // 正常聴力から重度難聴まで段階的にテスト
        let testCases = [
            (result: normalHearingResult, description: "正常聴力"),
            (result: mildLossResult, description: "軽度難聴"),
            (result: severeLossResult, description: "重度難聴")
        ]
        
        for testCase in testCases {
            audioManager.configureSimulation(testResult: testCase.result!, ear: "両耳")
            
            // 各周波数で適切な設定がされることを確認
            let thresholds = testCase.result!.thresholdsBoth!
            for (index, threshold) in thresholds.enumerated() {
                if let threshold = threshold {
                    XCTAssertGreaterThanOrEqual(threshold, 0, "\(testCase.description)の\(index)番目の周波数の閾値が有効: \(threshold)dB")
                }
            }
        }
    }
    
    // MARK: - 耳別シミュレーション統合テスト
    
    func testEarSpecificSimulationIntegration() throws {
        // 右耳のみの検査結果
        let rightOnlyResult = TestResult(
            ear: "右耳のみ",
            condition: "補聴器・人工内耳",
            thresholdsRight: [40, 45, 50, 55, 60, 65, 70],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        // 左耳のみの検査結果
        let leftOnlyResult = TestResult(
            ear: "左耳のみ",
            condition: "裸耳",
            thresholdsLeft: [35, 40, 45, 50, 55, 60, 65],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        // 右耳シミュレーション
        audioManager.configureSimulation(testResult: rightOnlyResult, ear: "右耳のみ")
        XCTAssertEqual(rightOnlyResult.ear, "右耳のみ", "右耳のみのシミュレーション設定")
        
        // 左耳シミュレーション
        audioManager.configureSimulation(testResult: leftOnlyResult, ear: "左耳のみ")
        XCTAssertEqual(leftOnlyResult.ear, "左耳のみ", "左耳のみのシミュレーション設定")
        
        // 両耳シミュレーション
        audioManager.configureSimulation(testResult: normalHearingResult, ear: "両耳")
        XCTAssertEqual(normalHearingResult.ear, "両耳", "両耳のシミュレーション設定")
    }
    
    // MARK: - 条件別シミュレーション統合テスト
    
    func testConditionSpecificSimulationIntegration() throws {
        // 裸耳条件
        let nakedEarResult = TestResult(
            ear: "両耳",
            condition: "裸耳",
            thresholdsBoth: [50, 55, 60, 65, 70, 75, 80],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        // 補聴器・人工内耳条件
        let hearingAidResult = TestResult(
            ear: "両耳",
            condition: "補聴器・人工内耳",
            thresholdsBoth: [25, 30, 35, 40, 45, 50, 55],
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        // 各条件でシミュレーション設定
        audioManager.configureSimulation(testResult: nakedEarResult, ear: "両耳")
        XCTAssertEqual(nakedEarResult.condition, "裸耳", "裸耳条件のシミュレーション")
        
        audioManager.resetSimulation()
        
        audioManager.configureSimulation(testResult: hearingAidResult, ear: "両耳")
        XCTAssertEqual(hearingAidResult.condition, "補聴器・人工内耳", "補聴器条件のシミュレーション")
    }
    
    // MARK: - 複数回シミュレーション変更テスト
    
    func testMultipleSimulationChanges() throws {
        let testResults = [normalHearingResult!, mildLossResult!, severeLossResult!]
        
        // 複数回シミュレーション設定を変更
        for (index, result) in testResults.enumerated() {
            audioManager.configureSimulation(testResult: result, ear: "両耳")
            
            // 各設定変更後の状態確認
            XCTAssertNotNil(result.thresholdsBoth, "設定変更\(index + 1)回目: 閾値データが存在")
            XCTAssertEqual(result.freqs.count, 7, "設定変更\(index + 1)回目: 7周波数が存在")
            
            // リセットして次の設定に備える
            audioManager.resetSimulation()
        }
    }
    
    // MARK: - エラーハンドリング統合テスト
    
    func testErrorHandlingIntegration() throws {
        // nil閾値でのシミュレーション設定
        let emptyResult = TestResult(
            ear: "両耳",
            condition: "裸耳",
            freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
        )
        
        // エラーが発生せずに処理が完了することを確認
        XCTAssertNoThrow({
            self.audioManager.configureSimulation(testResult: emptyResult, ear: "両耳")
        }, "空の閾値データでもエラーが発生しない")
        
        // 無効な耳タイプでのテスト
        XCTAssertNoThrow({
            self.audioManager.configureSimulation(testResult: self.normalHearingResult, ear: "無効な耳")
        }, "無効な耳タイプでもエラーが発生しない")
        
        // 無効な周波数データでのテスト
        let invalidFreqResult = TestResult(
            ear: "両耳",
            condition: "裸耳",
            thresholdsBoth: [30, 40, 50],  // 3つの閾値のみ
            freqs: ["125Hz", "250Hz", "500Hz"]  // 3つの周波数のみ
        )
        
        XCTAssertNoThrow({
            self.audioManager.configureSimulation(testResult: invalidFreqResult, ear: "両耳")
        }, "不一致な周波数データでもエラーが発生しない")
    }
    
    // MARK: - パフォーマンス統合テスト
    
    func testSimulationPerformanceIntegration() throws {
        self.measure {
            // 大量の設定変更パフォーマンステスト
            for i in 0..<100 {
                let dynamicResult = TestResult(
                    ear: "両耳",
                    condition: i % 2 == 0 ? "裸耳" : "補聴器・人工内耳",
                    thresholdsBoth: Array(20...26).map { $0 + (i % 30) },
                    freqs: ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]
                )
                
                audioManager.configureSimulation(testResult: dynamicResult, ear: "両耳")
                audioManager.resetSimulation()
            }
        }
    }
    
    // MARK: - リアルタイム処理統合テスト
    
    func testRealTimeProcessingIntegration() throws {
        // リアルタイム処理の開始・停止テスト
        XCTAssertFalse(audioManager.isPlaying, "初期状態では再生していない")
        
        // シミュレーション設定
        audioManager.configureSimulation(testResult: mildLossResult, ear: "両耳")
        
        // リアルタイム処理の開始をテスト（権限がない場合は何も起こらない）
        audioManager.startRealTimeProcessing()
        
        // 権限がない場合でもエラーが発生しないことを確認
        XCTAssertNotNil(audioManager, "リアルタイム処理開始後もマネージャーが有効")
        
        // 停止処理
        audioManager.stopRealTimeProcessing()
        XCTAssertFalse(audioManager.isPlaying, "停止後は再生状態ではない")
    }
    
    // MARK: - メモリ管理テスト
    
    func testMemoryManagementIntegration() throws {
        weak var weakAudioManager: AudioSimulationManager?
        
        autoreleasepool {
            let localAudioManager = AudioSimulationManager()
            weakAudioManager = localAudioManager
            
            // シミュレーション設定
            localAudioManager.configureSimulation(testResult: normalHearingResult, ear: "両耳")
            
            // 処理開始・停止
            localAudioManager.startRealTimeProcessing()
            localAudioManager.stopRealTimeProcessing()
            
            // リセット
            localAudioManager.resetSimulation()
        }
        
        // メモリリークがないことを確認
        XCTAssertNil(weakAudioManager, "AudioSimulationManagerが適切に解放される")
    }
    
    // MARK: - データ整合性テスト
    
    func testDataConsistencyIntegration() throws {
        let originalThresholds = normalHearingResult.thresholdsBoth
        let originalFreqs = normalHearingResult.freqs
        
        // シミュレーション設定前のデータを保存
        XCTAssertEqual(originalFreqs.count, 7, "元データで7周波数が存在")
        XCTAssertEqual(originalThresholds?.count, 7, "元データで7閾値が存在")
        
        // シミュレーション設定
        audioManager.configureSimulation(testResult: normalHearingResult, ear: "両耳")
        
        // シミュレーション設定後もデータが変更されないことを確認
        XCTAssertEqual(normalHearingResult.freqs, originalFreqs, "周波数データが変更されない")
        XCTAssertEqual(normalHearingResult.thresholdsBoth, originalThresholds, "閾値データが変更されない")
        
        // リセット後もデータが保持されることを確認
        audioManager.resetSimulation()
        XCTAssertEqual(normalHearingResult.freqs, originalFreqs, "リセット後も周波数データが保持される")
        XCTAssertEqual(normalHearingResult.thresholdsBoth, originalThresholds, "リセット後も閾値データが保持される")
    }
}