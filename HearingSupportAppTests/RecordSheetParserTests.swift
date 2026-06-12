//
//  RecordSheetParserTests.swift
//  HearingSupportAppTests
//
//  紙の記録用紙OCRテキスト解析のテスト
//

import XCTest
@testable import HearingSupportApp

final class RecordSheetParserTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    private func assertDate(_ date: Date?, year: Int, month: Int, day: Int,
                            file: StaticString = #filePath, line: UInt = #line) {
        guard let date = date else {
            XCTFail("日付が解析されるべきです", file: file, line: line)
            return
        }
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(components.year, year, file: file, line: line)
        XCTAssertEqual(components.month, month, file: file, line: line)
        XCTAssertEqual(components.day, day, file: file, line: line)
    }

    // MARK: - 検査日の解析

    func testParseWesternDateWithKanji() {
        let date = RecordSheetParser.parseDate(from: "検査日: 2025年8月20日")
        assertDate(date, year: 2025, month: 8, day: 20)
    }

    func testParseWesternDateWithSlash() {
        let date = RecordSheetParser.parseDate(from: "検査日 2025/8/20")
        assertDate(date, year: 2025, month: 8, day: 20)
    }

    func testParseReiwaDate() {
        let date = RecordSheetParser.parseDate(from: "検査年月日 令和7年8月20日")
        assertDate(date, year: 2025, month: 8, day: 20)
    }

    func testParseReiwaAbbreviatedDate() {
        let date = RecordSheetParser.parseDate(from: "検査日 R7.8.20")
        assertDate(date, year: 2025, month: 8, day: 20)
    }

    func testParseReiwaFirstYear() {
        let date = RecordSheetParser.parseDate(from: "検査日 令和元年5月10日")
        assertDate(date, year: 2019, month: 5, day: 10)
    }

    func testTestDateLabelTakesPriorityOverOtherDates() {
        let text = """
        生年月日 2018年4月1日
        検査日 2025年8月20日
        """
        let date = RecordSheetParser.parseDate(from: text)
        assertDate(date, year: 2025, month: 8, day: 20)
    }

    func testBirthDateLineIsIgnoredWithoutTestDateLabel() {
        let text = """
        生年月日 2018年4月1日
        2025年8月20日 実施
        """
        let date = RecordSheetParser.parseDate(from: text)
        assertDate(date, year: 2025, month: 8, day: 20)
    }

    func testInvalidDateReturnsNil() {
        XCTAssertNil(RecordSheetParser.parseDate(from: "検査日 2025年13月40日"))
        XCTAssertNil(RecordSheetParser.parseDate(from: "日付なしのテキスト"))
    }

    // MARK: - 病院名の解析

    func testParseHospitalWithLabel() {
        let hospital = RecordSheetParser.parseHospital(from: "病院名：さくら総合病院")
        XCTAssertEqual(hospital, "さくら総合病院")
    }

    func testParseHospitalWithSuffixKeyword() {
        let hospital = RecordSheetParser.parseHospital(from: "おみみ耳鼻咽喉科クリニック")
        XCTAssertEqual(hospital, "おみみ耳鼻咽喉科クリニック")
    }

    func testParseHospitalCutsTrailingText() {
        let hospital = RecordSheetParser.parseHospital(from: "さくら病院 聴力検査結果")
        XCTAssertEqual(hospital, "さくら病院")
    }

    func testParseHospitalReturnsNilWhenNotFound() {
        XCTAssertNil(RecordSheetParser.parseHospital(from: "聴力検査の結果です"))
    }

    // MARK: - 用紙全体の解析

    func testParseFullRecordSheet() {
        let text = """
        さくら総合病院
        聴力検査結果
        検査日 2025年8月20日
        気導検査
        右耳 ○
        125Hz: 25dB
        250Hz: 30dB
        500Hz: 35dB
        1000Hz: 40dB
        2000Hz: 45dB
        4000Hz: 50dB
        8000Hz: 55dB
        """

        let parsed = RecordSheetParser.parse(text)

        XCTAssertTrue(parsed.hasAnyData)
        assertDate(parsed.date, year: 2025, month: 8, day: 20)
        XCTAssertEqual(parsed.hospital, "さくら総合病院")
        XCTAssertEqual(parsed.testResults.count, 1, "聴力値が解析されるべきです")
        XCTAssertFalse(parsed.usedGraphRecognition, "テキストから読み取れる場合はグラフ推定を使わないべきです")
        XCTAssertEqual(parsed.testResults.first?.ear, "右耳のみ")
        XCTAssertEqual(parsed.testResults.first?.thresholdsRight[0], 25)
        XCTAssertEqual(parsed.testResults.first?.thresholdsRight[6], 55)
    }

    func testBothEarsTextResultIsSplitPerEar() {
        // 「両耳」のまま保存すると右耳・左耳の個別データが失われるため、耳ごとに分割される
        let text = """
        聴力検査結果
        気導検査
        右耳 ○ 25 30 35 40 45 50 55
        左耳 × 20 25 30 35 40 45 50
        """

        let parsed = RecordSheetParser.parse(text)

        XCTAssertEqual(parsed.testResults.count, 2, "右耳と左耳に分割されるべきです")
        let right = parsed.testResults.first { $0.ear == "右耳のみ" }
        let left = parsed.testResults.first { $0.ear == "左耳のみ" }
        XCTAssertEqual(right?.thresholdsRight[0], 25)
        XCTAssertEqual(left?.thresholdsLeft[0], 20)
    }

    func testParseEmptyTextHasNoData() {
        let parsed = RecordSheetParser.parse("")
        XCTAssertFalse(parsed.hasAnyData)
    }

    // MARK: - グラフへのフォールバック

    func testGraphFallbackWhenTextHasNoThresholds() {
        // テキストに聴力値がなく、グラフの軸ラベルと記号だけがあるページ
        var tokens: [ScannedToken] = []
        let freqLabels = ["125", "250", "500", "1000", "2000", "4000", "8000"]
        for (i, label) in freqLabels.enumerated() {
            tokens.append(makeToken(label, x: 0.2 + CGFloat(i) * 0.1, y: 0.92))
        }
        for db in stride(from: 0, through: 120, by: 10) {
            tokens.append(makeToken("\(db)", x: 0.08, y: 0.85 - CGFloat(db) / 120 * 0.7))
        }
        let values = [25, 30, 35, 40, 45, 50, 55]
        for (i, value) in values.enumerated() {
            tokens.append(makeToken("○", x: 0.2 + CGFloat(i) * 0.1, y: 0.85 - CGFloat(value) / 120 * 0.7))
        }

        let page = ScannedPage(text: "オージオグラム\n検査日 2025年8月20日", tokens: tokens)
        let parsed = RecordSheetParser.parse(pages: [page])

        XCTAssertTrue(parsed.usedGraphRecognition, "グラフ推定が使われるべきです")
        XCTAssertEqual(parsed.testResults.count, 1)
        XCTAssertEqual(parsed.testResults.first?.ear, "右耳のみ")
        XCTAssertEqual(parsed.testResults.first?.thresholdsRight, values.map { Optional($0) })
        assertDate(parsed.date, year: 2025, month: 8, day: 20)
    }

    private func makeToken(_ text: String, x: CGFloat, y: CGFloat) -> ScannedToken {
        ScannedToken(text: text, boundingBox: CGRect(x: x - 0.015, y: y - 0.01, width: 0.03, height: 0.02))
    }
}
