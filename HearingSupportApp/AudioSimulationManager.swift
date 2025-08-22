//
//  AudioSimulationManager.swift
//  HearingSupportApp
//
//  難聴児の聞こえを再現するオーディオシミュレーション機能
//

import AVFoundation
import SwiftUI

class AudioSimulationManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    private var audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode
    private var outputNode: AVAudioOutputNode
    private var eqNodes: [AVAudioUnitEQ] = []
    private var mixerNode = AVAudioMixerNode()
    private var audioRecorder: AVAudioRecorder?
    
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordedAudioFile: AVAudioFile?
    @Published var permissionGranted = false
    
    // 7つの周波数帯域に対応するイコライザー設定
    private let frequencies: [Float] = [125, 250, 500, 1000, 2000, 4000, 8000]
    
    override init() {
        inputNode = audioEngine.inputNode
        outputNode = audioEngine.outputNode
        super.init()
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        // 共通フォーマットを定義
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let sampleRate = inputFormat.sampleRate
        let channels = inputFormat.channelCount
        
        guard let commonFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channels) else {
            print("共通フォーマットの作成に失敗")
            return
        }
        
        // EQノードを各周波数帯域用に作成
        for frequency in frequencies {
            let eqNode = AVAudioUnitEQ(numberOfBands: 1)
            eqNode.bands[0].filterType = .parametric
            eqNode.bands[0].frequency = frequency
            eqNode.bands[0].bandwidth = 0.5
            eqNode.bands[0].gain = 0.0 // 初期値は0dB（減衰なし）
            eqNode.bands[0].bypass = false
            eqNodes.append(eqNode)
        }
        
        // ミキサーノードをエンジンに追加
        audioEngine.attach(mixerNode)
        
        // EQノードをエンジンに追加
        for eqNode in eqNodes {
            audioEngine.attach(eqNode)
        }
        
        // ノードを接続（入力 → EQ → ミキサー → 出力）
        audioEngine.connect(inputNode, to: eqNodes[0], format: commonFormat)
        
        // EQノードを直列接続
        for i in 0..<eqNodes.count - 1 {
            audioEngine.connect(eqNodes[i], to: eqNodes[i + 1], format: commonFormat)
        }
        
        // 最後のEQノードをミキサーに接続
        audioEngine.connect(eqNodes.last!, to: mixerNode, format: commonFormat)
        
        // ミキサーを出力に接続
        audioEngine.connect(mixerNode, to: outputNode, format: commonFormat)
    }
    
    // マイクロフォン権限を要求
    func requestMicrophonePermission() async {
        let permission: Bool
        
        if #available(iOS 17.0, *) {
            // iOS 17.0以降は AVAudioApplication を使用
            permission = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        } else {
            // iOS 17.0未満では従来のAPIを使用
            permission = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.permissionGranted = permission
        }
    }
    
    // 聴力検査結果に基づいてEQを設定
    func configureSimulation(testResult: TestResult, ear: String = "両耳") {
        guard let thresholds = getThresholds(from: testResult, for: ear) else { return }
        
        for (index, threshold) in thresholds.enumerated() {
            if index < eqNodes.count, let thresholdValue = threshold {
                // 聴力閾値に基づいて減衰量を計算
                // 正常聴力（0-20dB）は減衰なし
                // 軽度難聴（21-40dB）は軽度減衰
                // 中等度以上は段階的に減衰を増加
                let attenuationDB = calculateAttenuation(from: thresholdValue)
                eqNodes[index].bands[0].gain = -attenuationDB
            }
        }
    }
    
    private func getThresholds(from testResult: TestResult, for ear: String) -> [Int?]? {
        switch ear {
        case "右耳のみ":
            return testResult.thresholdsRight
        case "左耳のみ":
            return testResult.thresholdsLeft
        case "両耳":
            return testResult.thresholdsBoth
        default:
            return testResult.thresholdsBoth
        }
    }
    
    private func calculateAttenuation(from threshold: Int) -> Float {
        // 聴力閾値に基づく減衰量の計算
        switch threshold {
        case 0...20:    // 正常聴力
            return 0.0
        case 21...40:   // 軽度難聴
            return Float(threshold - 20) * 0.5
        case 41...70:   // 中等度難聴
            return Float(threshold - 20) * 0.7
        case 71...90:   // 高度難聴
            return Float(threshold - 20) * 0.9
        default:        // 重度難聴（91dB以上）
            return Float(threshold - 20) * 1.0
        }
    }
    
    // リアルタイム音声処理を開始
    func startRealTimeProcessing() {
        guard permissionGranted else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            
            if !audioEngine.isRunning {
                try audioEngine.start()
            }
            
            DispatchQueue.main.async {
                self.isPlaying = true
            }
            
        } catch {
            print("リアルタイム処理開始エラー: \(error)")
        }
    }
    
    // リアルタイム音声処理を停止
    func stopRealTimeProcessing() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.reset()
            setupAudioEngine()
        }
        
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
    
    // 音声録音を開始
    func startRecording() {
        guard permissionGranted else { 
            print("マイクロフォン権限が許可されていません")
            return 
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        do {
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            DispatchQueue.main.async {
                self.isRecording = true
            }
            
            // 録音完了後にファイルを保存
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.audioRecorder?.stop()
                strongSelf.isRecording = false
                
                do {
                    strongSelf.recordedAudioFile = try AVAudioFile(forReading: audioURL)
                    print("録音ファイル作成成功: \(audioURL)")
                } catch {
                    print("録音ファイル読み込みエラー: \(error)")
                }
            }
            
        } catch {
            print("録音開始エラー: \(error)")
            DispatchQueue.main.async {
                self.isRecording = false
            }
        }
    }
    
    // 録音した音声をシミュレーション付きで再生
    func playRecordedAudioWithSimulation() {
        guard let audioFile = recordedAudioFile else { 
            print("再生する録音ファイルがありません")
            return 
        }
        
        do {
            // AudioSessionを再生用に設定
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            
            // 既存のaudioEngineを停止してリセット
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            audioEngine.reset()
            
            // 新しいプレイバック用のオーディオエンジンセットアップ
            setupPlaybackAudioEngine(audioFile: audioFile)
            
            print("音声ファイル再生開始: \(audioFile.url)")
            
        } catch {
            print("再生エラー: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.isPlaying = false
            }
        }
    }
    
    private func setupPlaybackAudioEngine(audioFile: AVAudioFile) {
        do {
            let playerNode = AVAudioPlayerNode()
            audioEngine.attach(playerNode)
            
            // 共通フォーマットを使用（44.1kHz, stereo）
            let commonFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
            guard let format = commonFormat else {
                print("共通フォーマットの作成に失敗")
                return
            }
            
            // 現在のEQ設定を保存
            let currentGains = eqNodes.map { $0.bands[0].gain }
            
            // EQノードを再作成して適切なフォーマットで接続
            for eqNode in eqNodes {
                audioEngine.detach(eqNode)
            }
            eqNodes.removeAll()
            
            // 新しいEQノードを作成（現在のシミュレーション設定を復元）
            for (index, frequency) in frequencies.enumerated() {
                let eqNode = AVAudioUnitEQ(numberOfBands: 1)
                eqNode.bands[0].filterType = .parametric
                eqNode.bands[0].frequency = frequency
                eqNode.bands[0].bandwidth = 0.5
                // 以前の設定があれば復元、なければ0.0
                eqNode.bands[0].gain = index < currentGains.count ? currentGains[index] : 0.0
                eqNode.bands[0].bypass = false
                eqNodes.append(eqNode)
                audioEngine.attach(eqNode)
            }
            
            // ミキサーノードを再作成
            audioEngine.detach(mixerNode)
            mixerNode = AVAudioMixerNode()
            audioEngine.attach(mixerNode)
            
            // ノードを順次接続（共通フォーマット使用）
            audioEngine.connect(playerNode, to: eqNodes[0], format: format)
            
            for i in 0..<eqNodes.count - 1 {
                audioEngine.connect(eqNodes[i], to: eqNodes[i + 1], format: format)
            }
            
            audioEngine.connect(eqNodes.last!, to: mixerNode, format: format)
            audioEngine.connect(mixerNode, to: outputNode, format: format)
            
            // オーディオエンジンを準備して開始
            audioEngine.prepare()
            try audioEngine.start()
            
            // オーディオファイルを適切なフォーマットで再生スケジュール
            let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))!
            try audioFile.read(into: buffer)
            
            playerNode.scheduleBuffer(buffer, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    self?.isPlaying = false
                    print("音声再生完了")
                }
            }
            
            playerNode.play()
            
            DispatchQueue.main.async { [weak self] in
                self?.isPlaying = true
            }
            
        } catch {
            print("プレイバックエンジンセットアップエラー: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.isPlaying = false
            }
        }
    }
    
    // シミュレーション設定をリセット
    func resetSimulation() {
        for eqNode in eqNodes {
            eqNode.bands[0].gain = 0.0
        }
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
        }
        
        if flag {
            print("録音完了成功")
            do {
                recordedAudioFile = try AVAudioFile(forReading: recorder.url)
                print("録音ファイル読み込み成功: \(recorder.url)")
            } catch {
                print("録音ファイル読み込みエラー: \(error)")
            }
        } else {
            print("録音失敗")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("録音エンコードエラー: \(error?.localizedDescription ?? "不明なエラー")")
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
        }
    }
    
    deinit {
        stopRealTimeProcessing()
        audioRecorder?.stop()
        audioRecorder = nil
        
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // 全てのノードを削除
        for eqNode in eqNodes {
            audioEngine.detach(eqNode)
        }
        audioEngine.detach(mixerNode)
        
        eqNodes.removeAll()
    }
}