//
//  AudiogramGraphParserTests.swift
//  HearingSupportAppTests
//
//  オージオグラムのグラフ記号読み取りのテスト
//

import XCTest
import CoreGraphics
@testable import HearingSupportApp

final class AudiogramGraphParserTests: XCTestCase {

    // 標準的なオージオグラム用紙を模したトークン配置:
    // X軸: 125Hz〜8kHz を x=0.2〜0.8 に等間隔配置（ラベルは上端 y=0.92）
    // Y軸: 0〜120dB を y=0.85〜0.15 に配置（下に行くほど大きい値、ラベルは左端 x=0.08）

    private func x(forFrequencyIndex index: Int) -> CGFloat {
        0.2 + CGFloat(index) * 0.1
    }

    private func y(forDecibel db: Int) -> CGFloat {
        0.85 - CGFloat(db) / 120 * 0.7
    }

    private func token(_ text: String, x: CGFloat, y: CGFloat,
                       width: CGFloat = 0.03, height: CGFloat = 0.02) -> ScannedToken {
        ScannedToken(text: text,
                     boundingBox: CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height))
    }

    private func axisTokens() -> [ScannedToken] {
        var tokens: [ScannedToken] = []
        let freqLabels = ["125", "250", "500", "1000", "2000", "4000", "8000"]
        for (i, label) in freqLabels.enumerated() {
            tokens.append(token(label, x: x(forFrequencyIndex: i), y: 0.92))
        }
        for db in stride(from: 0, through: 120, by: 10) {
            tokens.append(token("\(db)", x: 0.08, y: y(forDecibel: db)))
        }
        return tokens
    }

    private func parse(_ tokens: [ScannedToken]) -> [TestResultInput] {
        AudiogramGraphParser.parse(ScannedPage(text: "", tokens: tokens))
    }

    // MARK: - 基本の読み取り

    func testParseRightEarCircles() {
        var tokens = axisTokens()
        let values = [25, 30, 35, 40, 45, 50, 55]
        for (i, value) in values.enumerated() {
            tokens.append(token("○", x: x(forFrequencyIndex: i), y: y(forDecibel: value)))
        }

        let results = parse(tokens)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.ear, "右耳のみ")
        XCTAssertEqual(results.first?.thresholdsRight, values.map { Optional($0) })
    }

    func testParseBothEars() {
        var tokens = axisTokens()
        let rightValues = [20, 25, 30, 35, 40, 45, 50]
        let leftValues = [30, 35, 40, 45, 50, 55, 60]
        for (i, value) in rightValues.enumerated() {
            tokens.append(token("○", x: x(forFrequencyIndex: i), y: y(forDecibel: value)))
        }
        for (i, value) in leftValues.enumerated() {
            tokens.append(token("×", x: x(forFrequencyIndex: i), y: y(forDecibel: value)))
        }

        let results = parse(tokens)

        XCTAssertEqual(results.count, 2)
        let right = results.first { $0.ear == "右耳のみ" }
        let left = results.first { $0.ear == "左耳のみ" }
        XCTAssertEqual(right?.thresholdsRight, rightValues.map { Optional($0) })
        XCTAssertEqual(left?.thresholdsLeft, leftValues.map { Optional($0) })
    }

    func testCirclesMisreadAsLettersAreRecognized() {
        // OCRは ○ を O や 0 として認識することが多い
        var tokens = axisTokens()
        tokens.append(token("O", x: x(forFrequencyIndex: 0), y: y(forDecibel: 40)))
        tokens.append(token("0", x: x(forFrequencyIndex: 1), y: y(forDecibel: 45)))
        tokens.append(token("o", x: x(forFrequencyIndex: 2), y: y(forDecibel: 50)))

        let results = parse(tokens)

        XCTAssertEqual(results.first?.ear, "右耳のみ")
        XCTAssertEqual(results.first?.thresholdsRight[0], 40)
        XCTAssertEqual(results.first?.thresholdsRight[1], 45)
        XCTAssertEqual(results.first?.thresholdsRight[2], 50)
    }

    func testMergedSymbolTokenIsSplit() {
        // 隣り合う記号が1つのトークン「××」として認識された場合は等分割して扱う
        var tokens = axisTokens()
        let left = x(forFrequencyIndex: 4) - 0.02
        let right = x(forFrequencyIndex: 5) + 0.02
        tokens.append(ScannedToken(
            text: "××",
            boundingBox: CGRect(x: left, y: y(forDecibel: 60) - 0.01, width: right - left, height: 0.02)
        ))

        let results = parse(tokens)

        XCTAssertEqual(results.first?.ear, "左耳のみ")
        XCTAssertEqual(results.first?.thresholdsLeft[4], 60)
        XCTAssertEqual(results.first?.thresholdsLeft[5], 60)
    }

    // MARK: - 誤検出の防止

    func testNoAxisLabelsReturnsEmpty() {
        // 軸ラベルがなければ座標を値に変換できないため何も返さない
        let tokens = [
            token("○", x: 0.3, y: 0.5),
            token("○", x: 0.4, y: 0.5),
            token("×", x: 0.5, y: 0.5),
        ]
        XCTAssertTrue(parse(tokens).isEmpty)
    }

    func testSingleSymbolIsRejected() {
        // 1点だけの検出はノイズの可能性が高いため採用しない
        var tokens = axisTokens()
        tokens.append(token("○", x: x(forFrequencyIndex: 3), y: y(forDecibel: 40)))

        XCTAssertTrue(parse(tokens).isEmpty)
    }

    func testSymbolsOutsidePlotAreaAreIgnored() {
        // プロット領域の外（軸ラベル付近など）の記号は無視される
        var tokens = axisTokens()
        // dB軸ラベルの「0」と同じ位置にある記号は領域外
        tokens.append(token("○", x: 0.05, y: y(forDecibel: 30)))
        tokens.append(token("○", x: 0.05, y: y(forDecibel: 50)))

        XCTAssertTrue(parse(tokens).isEmpty)
    }

    func testSymbolBetweenColumnsIsIgnored() {
        // 周波数の列から大きく外れた位置の記号は採用しない
        var tokens = axisTokens()
        let betweenColumns = (x(forFrequencyIndex: 2) + x(forFrequencyIndex: 3)) / 2
        tokens.append(token("○", x: betweenColumns, y: y(forDecibel: 40)))
        tokens.append(token("○", x: betweenColumns, y: y(forDecibel: 60)))

        XCTAssertTrue(parse(tokens).isEmpty)
    }

    func testDecibelValuesAreRoundedToFiveDecibelSteps() {
        // 多少のズレは5dB刻みに丸められる
        var tokens = axisTokens()
        tokens.append(token("○", x: x(forFrequencyIndex: 0), y: y(forDecibel: 38)))
        tokens.append(token("○", x: x(forFrequencyIndex: 1), y: y(forDecibel: 52)))

        let results = parse(tokens)

        XCTAssertEqual(results.first?.thresholdsRight[0], 40)
        XCTAssertEqual(results.first?.thresholdsRight[1], 50)
    }
}
