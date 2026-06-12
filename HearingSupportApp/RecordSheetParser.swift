//
//  RecordSheetParser.swift
//  HearingSupportApp
//
//  紙の検査記録用紙のOCRテキストから検査日・病院名・聴力値を抽出する
//

import Foundation

struct ParsedRecordSheet {
    var date: Date?
    var hospital: String?
    var testResults: [TestResultInput] = []
    // 聴力値をテキストではなくグラフの記号位置から推定した場合 true
    var usedGraphRecognition: Bool = false

    var hasAnyData: Bool {
        date != nil || hospital != nil || !testResults.isEmpty
    }
}

struct RecordSheetParser {
    static func parse(_ text: String) -> ParsedRecordSheet {
        ParsedRecordSheet(
            date: parseDate(from: text),
            hospital: parseHospital(from: text),
            testResults: splitByEar(HearingTestParser.parseOCRText(text))
        )
    }

    /// ページごとの位置情報付きOCR結果を解析する。
    /// テキストから聴力値が得られない場合はグラフ（○・×記号の位置）から推定する。
    static func parse(pages: [ScannedPage]) -> ParsedRecordSheet {
        let fullText = pages.map(\.text).joined(separator: "\n")
        var sheet = parse(fullText)

        if sheet.testResults.isEmpty {
            for page in pages {
                let graphResults = AudiogramGraphParser.parse(page)
                if !graphResults.isEmpty {
                    let condition = detectCondition(in: fullText)
                    sheet.testResults = graphResults.map { input in
                        var input = input
                        input.condition = condition
                        return input
                    }
                    sheet.usedGraphRecognition = true
                    break
                }
            }
        }
        return sheet
    }

    // 「両耳」として解析された結果に右耳・左耳の個別データが含まれる場合、
    // 保存時に失われないよう耳ごとの結果に分割する
    // （TestResultInput.toResult() は「両耳」のとき thresholdsBoth しか保存しないため）
    private static func splitByEar(_ input: TestResultInput?) -> [TestResultInput] {
        guard let input = input else { return [] }
        guard input.ear == "両耳" else { return [input] }

        let hasRight = input.thresholdsRight.contains { $0 != nil }
        let hasLeft = input.thresholdsLeft.contains { $0 != nil }
        guard hasRight || hasLeft else { return [input] }

        var results: [TestResultInput] = []
        if hasRight {
            var right = TestResultInput()
            right.ear = "右耳のみ"
            right.condition = input.condition
            right.thresholdsRight = input.thresholdsRight
            results.append(right)
        }
        if hasLeft {
            var left = TestResultInput()
            left.ear = "左耳のみ"
            left.condition = input.condition
            left.thresholdsLeft = input.thresholdsLeft
            results.append(left)
        }
        return results
    }

    private static func detectCondition(in text: String) -> String {
        if text.contains("補聴器") || text.contains("HA") { return "補聴器" }
        if text.contains("人工内耳") || text.contains("CI") { return "人工内耳" }
        return "裸耳"
    }

    // MARK: - 検査日の抽出

    private static let testDateLabels = ["検査日", "検査年月日", "測定日", "実施日", "受診日"]

    static func parseDate(from text: String) -> Date? {
        let lines = text.components(separatedBy: .newlines)

        // 「検査日」などのラベルが付いた行を優先する
        for line in lines where testDateLabels.contains(where: { line.contains($0) }) {
            if let date = parseDateValue(in: line) {
                return date
            }
        }

        // ラベルがない場合は生年月日の行を除いて最初に見つかった日付を使う
        for line in lines where !line.contains("生年月日") && !line.contains("誕生日") {
            if let date = parseDateValue(in: line) {
                return date
            }
        }

        return nil
    }

    private static func parseDateValue(in line: String) -> Date? {
        // 西暦表記: 2025年8月20日 / 2025/8/20 / 2025-08-20 / 2025.8.20
        let westernPattern = #"(\d{4})\s*[年/\-.]\s*(\d{1,2})\s*[月/\-.]\s*(\d{1,2})\s*日?"#
        if let components = matchDate(pattern: westernPattern, in: line),
           let date = makeDate(year: components.0, month: components.1, day: components.2) {
            return date
        }

        // 和暦表記: 令和7年8月20日 / R7.8.20 / 平成30年1月5日 / H30.1.5
        let eraPattern = #"(令和|平成|昭和|[RHS])\s*(元|\d{1,2})\s*[年/\-.]\s*(\d{1,2})\s*[月/\-.]\s*(\d{1,2})\s*日?"#
        if let regex = try? NSRegularExpression(pattern: eraPattern),
           let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
           let eraRange = Range(match.range(at: 1), in: line),
           let yearRange = Range(match.range(at: 2), in: line),
           let monthRange = Range(match.range(at: 3), in: line),
           let dayRange = Range(match.range(at: 4), in: line) {

            let eraYearString = String(line[yearRange])
            let eraYear = eraYearString == "元" ? 1 : (Int(eraYearString) ?? 0)

            let baseYear: Int
            switch String(line[eraRange]) {
            case "令和", "R": baseYear = 2018
            case "平成", "H": baseYear = 1988
            case "昭和", "S": baseYear = 1925
            default: return nil
            }

            if let month = Int(String(line[monthRange])),
               let day = Int(String(line[dayRange])),
               let date = makeDate(year: baseYear + eraYear, month: month, day: day) {
                return date
            }
        }

        return nil
    }

    private static func matchDate(pattern: String, in line: String) -> (Int, Int, Int)? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let yearRange = Range(match.range(at: 1), in: line),
              let monthRange = Range(match.range(at: 2), in: line),
              let dayRange = Range(match.range(at: 3), in: line),
              let year = Int(String(line[yearRange])),
              let month = Int(String(line[monthRange])),
              let day = Int(String(line[dayRange])) else {
            return nil
        }
        return (year, month, day)
    }

    private static func makeDate(year: Int, month: Int, day: Int) -> Date? {
        guard (1950...2100).contains(year), (1...12).contains(month), (1...31).contains(day) else {
            return nil
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: components),
              calendar.component(.day, from: date) == day else {
            // 2月30日のような存在しない日付を除外
            return nil
        }
        return date
    }

    // MARK: - 病院名の抽出

    private static let hospitalLabels = ["病院名", "医療機関名", "医療機関", "施設名"]
    private static let facilityKeywords = ["クリニック", "病院", "医院", "診療所", "医療センター", "耳鼻咽喉科"]

    static func parseHospital(from text: String) -> String? {
        for rawLine in text.components(separatedBy: .newlines) {
            var line = rawLine.trimmingCharacters(in: .whitespaces)

            // 「病院名：○○」のようなラベルを取り除く
            for label in hospitalLabels where line.hasPrefix(label) {
                line = String(line.dropFirst(label.count))
                    .trimmingCharacters(in: CharacterSet(charactersIn: ":：　 "))
                break
            }
            guard !line.isEmpty else { continue }

            // 施設名キーワードで終わる部分までを病院名として切り出す
            // （例:「○○病院 聴力検査結果」→「○○病院」）
            var candidate: String?
            for keyword in facilityKeywords {
                if let range = line.range(of: keyword, options: .backwards) {
                    let name = String(line[..<range.upperBound])
                    if candidate == nil || name.count > candidate!.count {
                        candidate = name
                    }
                }
            }

            if let candidate = candidate?.trimmingCharacters(in: .whitespaces),
               (2...30).contains(candidate.count) {
                return candidate
            }
        }
        return nil
    }
}
