//
//  HearingSimulationEngine.swift
//  HearingSupportApp
//
//  難聴の聞こえ方を疑似体験するための録音・再生エンジン。
//
//  - 話し声を一時ファイルに録音する（保存はせず、アプリ終了で消える）
//  - 聴力検査の閾値データをもとに、周波数帯ごとに音量をしぼって再生する
//  - すべて端末内で完結し、音声データを外部へ送信することは一切ない
//

import Foundation
import AVFoundation
import Combine

/// 周波数帯ごとの減衰設定に使う1バンド分の情報
struct SimulationBand: Identifiable {
    let id = UUID()
    /// 中心周波数（Hz）
    let frequency: Double
    /// 表示用ラベル（例: "1kHz"）
    let label: String
    /// 聴力検査の閾値（dB HL）。データがない場合は nil
    let thresholdDB: Int?
    /// 実際に適用する減衰量（dB、0以下の負値）
    var gainDB: Float
}

@MainActor
final class HearingSimulationEngine: ObservableObject {

    enum Phase: Equatable {
        case idle          // 録音前
        case recording     // 録音中
        case recorded      // 録音済み（再生可能）
    }

    enum PlaybackMode: Equatable {
        case none
        case original      // 原音
        case simulated     // 聞こえ方を再現（実際の音量低下も含む）
        case balanced      // ゆがみのみ再現（全体音量は保つ）
    }

    // MARK: - 公開状態

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var playbackMode: PlaybackMode = .none
    @Published private(set) var permissionDenied = false
    @Published private(set) var recordingDuration: TimeInterval = 0
    @Published var errorMessage: String?

    /// 周波数帯ごとの減衰設定（UI のスライダーと連動）
    @Published var bands: [SimulationBand] = []

    var isRecording: Bool { phase == .recording }
    var hasRecording: Bool { phase == .recorded }
    var isPlaying: Bool { playbackMode != .none }

    // MARK: - 内部

    private var recorder: AVAudioRecorder?
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var eq: AVAudioUnitEQ
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    private var durationTimer: Timer?

    init() {
        // バンド数はあとで聴力データに合わせて構成するが、最大バンド数で初期化しておく
        eq = AVAudioUnitEQ(numberOfBands: 12)
        engine.attach(player)
        engine.attach(eq)
        engine.connect(player, to: eq, format: nil)
        engine.connect(eq, to: engine.mainMixerNode, format: nil)
    }

    deinit {
        durationTimer?.invalidate()
    }

    // MARK: - バンド構成

    /// 聴力検査の閾値データから減衰バンドを構成する
    /// - Parameters:
    ///   - thresholds: 各周波数の閾値（dB HL）。nil は未測定
    ///   - freqLabels: 周波数ラベル（例: ["125Hz", ... "8kHz"]）
    func configureBands(thresholds: [Int?], freqLabels: [String]) {
        let count = min(thresholds.count, freqLabels.count)
        // 未測定の帯域は前後の値から補間して、できるだけ自然な減衰カーブにする
        let filled = Self.interpolate(Array(thresholds.prefix(count)))

        var newBands: [SimulationBand] = []
        for i in 0..<count {
            let freq = Self.frequency(from: freqLabels[i])
            let gain = Self.gain(forThreshold: filled[i])
            newBands.append(
                SimulationBand(
                    frequency: freq,
                    label: freqLabels[i],
                    thresholdDB: thresholds[i],
                    gainDB: gain
                )
            )
        }
        bands = newBands
        applyBandsToEQ()
    }

    /// 閾値（dB HL）を再生時の減衰量（dB）へ変換する。
    /// 正常閾値（おおむね 0〜20dB）を基準に、それを超えた分だけ音をしぼる。
    static func gain(forThreshold threshold: Int?) -> Float {
        guard let threshold else { return 0 }
        // 0dB HL を基準とし、閾値の分だけ減衰させる（聞こえにくさを音量低下で近似）
        let attenuation = Float(max(0, threshold))
        // AVAudioUnitEQ のゲイン下限は -96dB
        return -min(attenuation, 96)
    }

    /// 未測定（nil）の帯域を前後の測定値から線形補間する
    static func interpolate(_ values: [Int?]) -> [Int?] {
        var result = values
        let knownIndices = values.enumerated().compactMap { $0.element != nil ? $0.offset : nil }
        guard let firstKnown = knownIndices.first, let lastKnown = knownIndices.last else {
            return result // 1点も測定値がなければそのまま
        }
        for i in values.indices where result[i] == nil {
            if i < firstKnown {
                result[i] = values[firstKnown]
            } else if i > lastKnown {
                result[i] = values[lastKnown]
            } else {
                // 前後の測定点を探して線形補間
                let prev = knownIndices.last { $0 < i }!
                let next = knownIndices.first { $0 > i }!
                let prevVal = Double(values[prev]!)
                let nextVal = Double(values[next]!)
                let ratio = Double(i - prev) / Double(next - prev)
                result[i] = Int((prevVal + (nextVal - prevVal) * ratio).rounded())
            }
        }
        return result
    }

    /// "125Hz" / "1kHz" / "8kHz" などのラベルを中心周波数(Hz)へ変換する
    static func frequency(from label: String) -> Double {
        let lower = label.lowercased().replacingOccurrences(of: "hz", with: "")
        if lower.contains("k") {
            let number = lower.replacingOccurrences(of: "k", with: "")
            return (Double(number) ?? 1) * 1000
        }
        return Double(lower) ?? 1000
    }

    /// 現在の bands の内容を EQ ユニットへ反映する
    /// - Parameter relative: true の場合、最もよく聞こえる帯域を基準(0dB)に全体を持ち上げ、
    ///   帯域間の相対差（音色のゆがみ）だけを残す。全体音量は保たれる。
    private func applyBandsToEQ(relative: Bool = false) {
        // relative モードでは、最もゲインの大きい（=最も減衰の少ない）帯域を基準にする
        let offset: Float = relative ? (bands.map { $0.gainDB }.max() ?? 0) : 0
        for (i, band) in bands.enumerated() where i < eq.bands.count {
            let p = eq.bands[i]
            p.filterType = .parametric
            p.frequency = Float(band.frequency)
            p.bandwidth = 1.0 // 約1オクターブ
            p.gain = band.gainDB - offset
            p.bypass = false
        }
        // 使っていないバンドはバイパス
        if bands.count < eq.bands.count {
            for i in bands.count..<eq.bands.count {
                eq.bands[i].bypass = true
            }
        }
    }

    /// スライダー操作などで1バンドの減衰量を更新する
    func updateGain(bandID: UUID, gainDB: Float) {
        guard let index = bands.firstIndex(where: { $0.id == bandID }) else { return }
        bands[index].gainDB = gainDB
        if index < eq.bands.count {
            eq.bands[index].gain = gainDB
        }
    }

    /// 自動算出した減衰量へ戻す
    func resetToAuto() {
        for i in bands.indices {
            bands[i].gainDB = Self.gain(forThreshold: bands[i].thresholdDB)
        }
        applyBandsToEQ()
    }

    // MARK: - 録音

    func requestPermissionAndStartRecording() {
        requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                if granted {
                    self.startRecording()
                } else {
                    self.permissionDenied = true
                }
            }
        }
    }

    private func requestRecordPermission(_ completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                completion(granted)
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                completion(granted)
            }
        }
    }

    private func startRecording() {
        stopPlayback()
        // 録音中は再生エンジンを止めておく（セッションのカテゴリ衝突を避ける）
        if engine.isRunning {
            engine.stop()
        }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("hearing_sim_\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let newRecorder = try AVAudioRecorder(url: url, settings: settings)
            newRecorder.record()

            recorder = newRecorder
            recordingURL = url
            recordingDuration = 0
            phase = .recording
            startDurationTimer()
        } catch {
            errorMessage = "録音を開始できませんでした: \(error.localizedDescription)"
        }
    }

    func stopRecording() {
        guard phase == .recording else { return }
        recorder?.stop()
        recorder = nil
        stopDurationTimer()

        if let url = recordingURL,
           let file = try? AVAudioFile(forReading: url) {
            audioFile = file
            phase = .recorded
            // 再生エンジンを先に起動（ウォームアップ）しておく。
            // 再生ボタンを押した瞬間に起動すると初回の音が取りこぼされるため、
            // 録音終了の時点で起動しておくことで1回目から確実に鳴るようにする。
            prepareEngineForPlayback()
        } else {
            errorMessage = "録音の保存に失敗しました"
            phase = .idle
        }
    }

    /// 再生用にオーディオセッションとエンジンを準備し、起動しておく
    private func prepareEngineForPlayback() {
        guard let audioFile else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)

            // 録音ファイルのフォーマットに合わせて接続する
            let format = audioFile.processingFormat
            engine.connect(player, to: eq, format: format)
            engine.connect(eq, to: engine.mainMixerNode, format: format)
            engine.mainMixerNode.outputVolume = 1.0

            engine.prepare()
            if !engine.isRunning {
                try engine.start()
            }
        } catch {
            errorMessage = "再生の準備に失敗しました: \(error.localizedDescription)"
        }
    }

    private func startDurationTimer() {
        durationTimer?.invalidate()
        let start = Date()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingDuration = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }

    // MARK: - 再生

    /// 原音をそのまま再生する
    func playOriginal() {
        play(mode: .original)
    }

    /// 聞こえ方（実際の音量低下を含む）で再生する
    func playSimulated() {
        play(mode: .simulated)
    }

    /// ゆがみのみ（全体音量は保ったまま周波数バランスの崩れだけ）で再生する
    func playBalanced() {
        play(mode: .balanced)
    }

    private func play(mode: PlaybackMode) {
        guard let audioFile else { return }
        stopPlayback()

        // モードに応じて EQ を設定する
        switch mode {
        case .original, .none:
            for band in eq.bands { band.bypass = true }
        case .simulated:
            applyBandsToEQ(relative: false)
        case .balanced:
            applyBandsToEQ(relative: true)
        }

        // 通常はエンジンは録音終了時にウォームアップ済み。
        // 何らかの理由で停止していた場合はここで起動し直す。
        if !engine.isRunning {
            prepareEngineForPlayback()
        }
        guard engine.isRunning else { return }

        audioFile.framePosition = 0
        // 完了タイプに .dataPlayedBack を指定する。
        // 指定しないと再生終了前にハンドラが呼ばれ、すぐ stop() してしまい音が出ない。
        player.scheduleFile(audioFile, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor in
                self?.handlePlaybackFinished()
            }
        }
        player.play()
        playbackMode = mode
    }

    private func handlePlaybackFinished() {
        // 自然に再生が終わった場合
        if playbackMode != .none {
            playbackMode = .none
            player.stop()
        }
    }

    func stopPlayback() {
        if player.isPlaying {
            player.stop()
        }
        playbackMode = .none
    }

    /// 録音をやり直す
    func discardRecording() {
        stopPlayback()
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        audioFile = nil
        recordingDuration = 0
        phase = .idle
    }
}
