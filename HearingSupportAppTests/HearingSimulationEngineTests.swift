//
//  HearingSimulationEngineTests.swift
//  HearingSupportAppTests
//
//  聞こえ方シミュレーションエンジンのロジックを検証するテスト。
//  （録音・再生のハードウェア処理ではなく、減衰量の計算ロジックを対象とする）
//

import XCTest
import AVFoundation
@testable import HearingSupportApp

@MainActor
final class HearingSimulationEngineTests: XCTestCase {

    private let freqLabels = ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]

    // MARK: - gain(forThreshold:)

    func testGainForThreshold_nilIsZero() {
        XCTAssertEqual(HearingSimulationEngine.gain(forThreshold: nil), 0)
    }

    func testGainForThreshold_normalHearingIsNotBoosted() {
        // 0dB（基準）以下はブーストしない（0dB のまま）
        XCTAssertEqual(HearingSimulationEngine.gain(forThreshold: 0), 0)
        XCTAssertEqual(HearingSimulationEngine.gain(forThreshold: -10), 0)
    }

    func testGainForThreshold_attenuatesByThreshold() {
        XCTAssertEqual(HearingSimulationEngine.gain(forThreshold: 40), -40)
        XCTAssertEqual(HearingSimulationEngine.gain(forThreshold: 60), -60)
    }

    func testGainForThreshold_clampedAtMinus96() {
        // EQ のゲイン下限 -96dB を超えないこと
        XCTAssertEqual(HearingSimulationEngine.gain(forThreshold: 100), -96)
        XCTAssertEqual(HearingSimulationEngine.gain(forThreshold: 120), -96)
    }

    // MARK: - interpolate

    func testInterpolate_middleGap() {
        let input: [Int?] = [nil, nil, 40, nil, 60, nil]
        let result = HearingSimulationEngine.interpolate(input)
        // 先頭は最初の測定値、末尾は最後の測定値で埋め、間は線形補間
        XCTAssertEqual(result, [40, 40, 40, 50, 60, 60])
    }

    func testInterpolate_allNilUnchanged() {
        let input: [Int?] = [nil, nil, nil]
        XCTAssertEqual(HearingSimulationEngine.interpolate(input), input)
    }

    func testInterpolate_noNilUnchanged() {
        let input: [Int?] = [10, 20, 30]
        XCTAssertEqual(HearingSimulationEngine.interpolate(input), input)
    }

    func testInterpolate_singleKnownFillsAll() {
        let input: [Int?] = [nil, 30, nil]
        XCTAssertEqual(HearingSimulationEngine.interpolate(input), [30, 30, 30])
    }

    func testInterpolate_emptyArray() {
        let input: [Int?] = []
        XCTAssertEqual(HearingSimulationEngine.interpolate(input), input)
    }

    // MARK: - frequency(from:)

    func testFrequencyFromLabel() {
        XCTAssertEqual(HearingSimulationEngine.frequency(from: "125Hz"), 125)
        XCTAssertEqual(HearingSimulationEngine.frequency(from: "250Hz"), 250)
        XCTAssertEqual(HearingSimulationEngine.frequency(from: "1kHz"), 1000)
        XCTAssertEqual(HearingSimulationEngine.frequency(from: "2kHz"), 2000)
        XCTAssertEqual(HearingSimulationEngine.frequency(from: "8kHz"), 8000)
    }

    func testFrequencyFromLabel_fallback() {
        // 解析できないラベルは 1000Hz にフォールバック
        XCTAssertEqual(HearingSimulationEngine.frequency(from: "???"), 1000)
    }

    // MARK: - relativeGains（ゆがみモード）

    func testRelativeGains_shiftsTopBandToZero() {
        // 最大ゲイン(=最も聞こえる帯域)を 0dB に合わせ、相対差を維持する
        XCTAssertEqual(HearingSimulationEngine.relativeGains([0, -20, -40]), [0, -20, -40])
        XCTAssertEqual(HearingSimulationEngine.relativeGains([-10, -30, -20]), [0, -20, -10])
    }

    func testRelativeGains_flatLossBecomesNoDistortion() {
        // 全帯域が均等に低下 → 相対差ゼロ（=ゆがみなし、原音と同じ）
        XCTAssertEqual(HearingSimulationEngine.relativeGains([-50, -50, -50]), [0, 0, 0])
    }

    func testRelativeGains_empty() {
        XCTAssertEqual(HearingSimulationEngine.relativeGains([]), [])
    }

    // MARK: - configureBands

    func testConfigureBands_producesExpectedGainsAndFrequencies() {
        let engine = HearingSimulationEngine()
        let thresholds: [Int?] = [0, 20, 40, nil, 60, 80, 100]
        engine.configureBands(thresholds: thresholds, freqLabels: freqLabels)

        XCTAssertEqual(engine.bands.count, 7)
        XCTAssertEqual(engine.bands.map { $0.gainDB }, [0, -20, -40, -50, -60, -80, -96])
        XCTAssertEqual(engine.bands[0].frequency, 125)
        XCTAssertEqual(engine.bands[3].frequency, 1000)
        XCTAssertEqual(engine.bands[6].frequency, 8000)
    }

    func testConfigureBands_interpolatedBandKeepsNilThresholdButAutoGain() {
        let engine = HearingSimulationEngine()
        let thresholds: [Int?] = [0, 20, 40, nil, 60, 80, 100]
        engine.configureBands(thresholds: thresholds, freqLabels: freqLabels)

        // 未測定帯域は thresholdDB は nil のまま、ゲインは補間値(=50→-50)
        XCTAssertNil(engine.bands[3].thresholdDB)
        XCTAssertEqual(engine.bands[3].autoGainDB, -50)
        XCTAssertEqual(engine.bands[3].gainDB, -50)
    }

    func testConfigureBands_mismatchedLengthsUsesShorter() {
        let engine = HearingSimulationEngine()
        let thresholds: [Int?] = [10, 20, 30]
        engine.configureBands(thresholds: thresholds, freqLabels: ["125Hz", "250Hz"])
        XCTAssertEqual(engine.bands.count, 2)
    }

    // MARK: - 手動調整と自動復元

    func testUpdateGainThenResetToAuto() {
        let engine = HearingSimulationEngine()
        engine.configureBands(thresholds: [0, 20, 40, nil, 60, 80, 100], freqLabels: freqLabels)

        // 手動で補間帯域のゲインを変更
        let interpolatedBand = engine.bands[3]
        engine.updateGain(bandID: interpolatedBand.id, gainDB: -90)
        XCTAssertEqual(engine.bands[3].gainDB, -90)

        // 自動に戻すと補間で算出した自動値(-50)へ復元される
        engine.resetToAuto()
        XCTAssertEqual(engine.bands[3].gainDB, -50)
    }

    func testUpdateGain_unknownIDDoesNothing() {
        let engine = HearingSimulationEngine()
        engine.configureBands(thresholds: [0, 20, 40, nil, 60, 80, 100], freqLabels: freqLabels)
        let before = engine.bands.map { $0.gainDB }
        engine.updateGain(bandID: UUID(), gainDB: -90)
        XCTAssertEqual(engine.bands.map { $0.gainDB }, before)
    }

    // MARK: - 初期状態

    func testInitialState() {
        let engine = HearingSimulationEngine()
        XCTAssertEqual(engine.phase, .idle)
        XCTAssertFalse(engine.isRecording)
        XCTAssertFalse(engine.hasRecording)
        XCTAssertFalse(engine.isPlaying)
        XCTAssertTrue(engine.bands.isEmpty)
    }
}
