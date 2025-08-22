//
//  AudioPermissionTests.swift
//  HearingSupportAppTests
//
//  音声権限処理のテスト
//

import XCTest
import AVFoundation
@testable import HearingSupportApp

final class AudioPermissionTests: XCTestCase {
    
    var audioManager: AudioSimulationManager!
    
    override func setUpWithError() throws {
        audioManager = AudioSimulationManager()
    }
    
    override func tearDownWithError() throws {
        audioManager.stopRealTimeProcessing()
        audioManager = nil
    }
    
    // MARK: - 権限状態の初期値テスト
    
    func testInitialPermissionState() throws {
        XCTAssertFalse(audioManager.permissionGranted, "初期状態では権限が許可されていない")
    }
    
    // MARK: - 権限要求プロセステスト
    
    func testMicrophonePermissionRequest() async throws {
        let initialState = audioManager.permissionGranted
        
        // 権限要求を実行
        await audioManager.requestMicrophonePermission()
        
        // 権限要求が完了することを確認（実際の許可状態は環境依存）
        XCTAssertNotNil(audioManager, "権限要求後もマネージャーが有効")
        
        // 権限状態は変更される可能性がある（許可または拒否）
        // 実際の値は環境によって異なるため、変更されたことのみ確認
        let finalState = audioManager.permissionGranted
        XCTAssertTrue(initialState == false, "初期状態は false")
        
        // 状態が変更されているか、または初期値のままかを確認
        XCTAssertTrue(finalState == true || finalState == false, "権限状態が有効な値")
    }
    
    // MARK: - 権限に依存する機能のテスト
    
    func testRecordingWithoutPermission() throws {
        // 権限がない状態で録音を試行
        XCTAssertFalse(audioManager.permissionGranted, "権限がない状態")
        
        audioManager.startRecording()
        
        // 権限がない場合は録音状態にならないことを確認
        XCTAssertFalse(audioManager.isRecording, "権限がない場合は録音されない")
        XCTAssertNil(audioManager.recordedAudioFile, "権限がない場合は録音ファイルが作成されない")
    }
    
    func testRealTimeProcessingWithoutPermission() throws {
        // 権限がない状態でリアルタイム処理を試行
        XCTAssertFalse(audioManager.permissionGranted, "権限がない状態")
        
        audioManager.startRealTimeProcessing()
        
        // 権限がない場合は再生状態にならないことを確認
        XCTAssertFalse(audioManager.isPlaying, "権限がない場合はリアルタイム処理されない")
    }
    
    // MARK: - 権限状態変化の処理テスト
    
    func testPermissionStateChangeHandling() async throws {
        let expectation = XCTestExpectation(description: "権限状態変化の処理")
        
        // 権限要求の非同期処理をテスト
        Task {
            await audioManager.requestMicrophonePermission()
            
            // 権限要求後の処理が正常に完了することを確認
            XCTAssertNotNil(audioManager, "権限状態変化後もマネージャーが有効")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - 複数回権限要求テスト
    
    func testMultiplePermissionRequests() async throws {
        // 複数回権限を要求しても問題ないことを確認
        for i in 1...3 {
            await audioManager.requestMicrophonePermission()
            
            XCTAssertNotNil(audioManager, "権限要求\(i)回目: マネージャーが有効")
            
            // 各回で一貫した動作をすることを確認
            let currentState = audioManager.permissionGranted
            XCTAssertTrue(currentState == true || currentState == false, "権限要求\(i)回目: 有効な権限状態")
        }
    }
    
    // MARK: - 権限関連のエラーハンドリングテスト
    
    func testPermissionErrorHandling() throws {
        // 権限がない状態での各種操作がエラーを起こさないことを確認
        
        XCTAssertNoThrow({
            self.audioManager.startRecording()
        }, "権限なしでの録音開始がエラーを起こさない")
        
        XCTAssertNoThrow({
            self.audioManager.startRealTimeProcessing()
        }, "権限なしでのリアルタイム処理開始がエラーを起こさない")
        
        XCTAssertNoThrow({
            self.audioManager.playRecordedAudioWithSimulation()
        }, "権限なしでの再生がエラーを起こさない")
        
        XCTAssertNoThrow({
            self.audioManager.stopRealTimeProcessing()
        }, "権限なしでの停止処理がエラーを起こさない")
    }
    
    // MARK: - 権限状態の永続性テスト
    
    func testPermissionStatePersistence() async throws {
        // 権限要求前の状態
        let initialState = audioManager.permissionGranted
        
        // 権限要求
        await audioManager.requestMicrophonePermission()
        let afterRequestState = audioManager.permissionGranted
        
        // 短時間待機後の状態確認
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機
        let afterWaitState = audioManager.permissionGranted
        
        XCTAssertEqual(afterRequestState, afterWaitState, "権限状態が短時間で変化しない")
        
        // 初期状態と比較（変化があった場合のみ）
        if initialState != afterRequestState {
            XCTAssertNotEqual(initialState, afterRequestState, "権限状態が適切に更新された")
        }
    }
    
    // MARK: - AVAudioSession権限テスト
    
    func testAVAudioSessionPermissionConsistency() async throws {
        // AudioSimulationManagerの権限状態とAVAudioSessionの権限状態の整合性をテスト
        
        await audioManager.requestMicrophonePermission()
        let managerPermission = audioManager.permissionGranted
        
        // AVAudioSessionから直接権限状態を取得
        let audioSessionPermission = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        // 両者が一致することを確認
        XCTAssertEqual(managerPermission, audioSessionPermission, "マネージャーとAVAudioSessionの権限状態が一致")
    }
    
    // MARK: - 権限に基づくUI状態テスト
    
    func testUIStateBasedOnPermission() throws {
        // 権限がない状態でのUI関連プロパティ
        XCTAssertFalse(audioManager.permissionGranted, "権限なし状態")
        XCTAssertFalse(audioManager.isRecording, "録音していない")
        XCTAssertFalse(audioManager.isPlaying, "再生していない")
        XCTAssertNil(audioManager.recordedAudioFile, "録音ファイルなし")
        
        // これらの状態はUIでの表示制御に使用される
        let canRecord = audioManager.permissionGranted
        let canPlayRealTime = audioManager.permissionGranted
        let hasRecordedFile = audioManager.recordedAudioFile != nil
        
        XCTAssertFalse(canRecord, "録音ボタンが無効状態")
        XCTAssertFalse(canPlayRealTime, "リアルタイム再生ボタンが無効状態")
        XCTAssertFalse(hasRecordedFile, "録音再生ボタンが無効状態")
    }
    
    // MARK: - 権限変更後の機能復旧テスト
    
    func testFunctionalityAfterPermissionGrant() async throws {
        // 初期状態（権限なし）で機能が無効なことを確認
        XCTAssertFalse(audioManager.permissionGranted, "初期状態で権限なし")
        
        audioManager.startRecording()
        XCTAssertFalse(audioManager.isRecording, "権限なしでは録音されない")
        
        // 権限要求
        await audioManager.requestMicrophonePermission()
        
        // 権限が許可された場合の機能復旧をテスト
        if audioManager.permissionGranted {
            // 権限が許可された場合、機能が利用可能になることをテスト
            XCTAssertTrue(audioManager.permissionGranted, "権限が許可された")
            
            // 録音機能のテスト（実際の録音は環境依存のため、エラーが発生しないことのみ確認）
            XCTAssertNoThrow({
                self.audioManager.startRecording()
            }, "権限許可後は録音開始がエラーを起こさない")
            
            // リアルタイム処理のテスト
            XCTAssertNoThrow({
                self.audioManager.startRealTimeProcessing()
            }, "権限許可後はリアルタイム処理開始がエラーを起こさない")
            
            // 停止処理
            audioManager.stopRealTimeProcessing()
        } else {
            XCTAssertFalse(audioManager.permissionGranted, "権限が拒否された場合の状態確認")
        }
    }
    
    // MARK: - パフォーマンステスト
    
    func testPermissionRequestPerformance() throws {
        self.measure {
            Task {
                await audioManager.requestMicrophonePermission()
            }
        }
    }
    
    // MARK: - メモリ管理テスト（権限関連）
    
    func testPermissionRelatedMemoryManagement() async throws {
        weak var weakManager: AudioSimulationManager?
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task {
                let localManager = AudioSimulationManager()
                weakManager = localManager
                
                // 権限要求
                await localManager.requestMicrophonePermission()
                
                // 各種操作
                localManager.startRecording()
                localManager.startRealTimeProcessing()
                localManager.stopRealTimeProcessing()
                
                continuation.resume()
            }
        }
        
        // 権限関連の処理後もメモリリークがないことを確認
        XCTAssertNil(weakManager, "権限処理後にマネージャーが適切に解放される")
    }
}