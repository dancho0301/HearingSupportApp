//
//  AudiogramGraphParser.swift
//  HearingSupportApp
//
//  オージオグラムのグラフ（○・×記号のプロット）をOCRの位置情報から読み取る。
//  軸ラベル（125〜8000Hz / 0〜120dB）の座標で平面をキャリブレーションし、
//  プロットされた記号の位置を周波数・聴力レベルに変換する。
//

import Foundation
import CoreGraphics

struct AudiogramGraphParser {

    // OCRが気導記号として認識しうる文字（○は O・0 などに誤認されやすい）。
    // 数字の "0" は dB軸ラベル等で出現しうるが、軸ラベルはプロット領域外にあり
    // plotXRange / plotYRange の位置フィルタ（parse 内）で除外されるため記号集合に含める。
    private static let rightEarSymbols: Set<Character> = ["○", "〇", "◯", "O", "o", "0"]
    private static let leftEarSymbols: Set<Character> = ["×", "✕", "✗", "X", "x"]

    private enum EarSide {
        case right, left
    }

    // 軸ラベルの位置から求めた座標変換
    private struct Calibration {
        let frequencySlope: Double
        let frequencyIntercept: Double
        let decibelSlope: Double
        let decibelIntercept: Double
        let plotXRange: ClosedRange<Double>
        let plotYRange: ClosedRange<Double>

        func frequencyIndex(atX x: Double) -> Double {
            frequencyIntercept + frequencySlope * x
        }

        func decibel(atY y: Double) -> Double {
            decibelIntercept + decibelSlope * y
        }
    }

    /// グラフから読み取れた検査結果を耳ごとに返す（読み取れない場合は空配列）
    static func parse(_ page: ScannedPage) -> [TestResultInput] {
        guard let calibration = calibrate(tokens: page.tokens) else { return [] }

        var rightThresholds: [Int?] = Array(repeating: nil, count: 7)
        var leftThresholds: [Int?] = Array(repeating: nil, count: 7)
        // 同じ周波数に複数の記号が検出された場合は列の中心に近いものを採用する
        var rightDistances = [Double](repeating: .infinity, count: 7)
        var leftDistances = [Double](repeating: .infinity, count: 7)

        for token in page.tokens {
            guard let side = classifySymbol(token.text) else { continue }

            for center in symbolCenters(of: token) {
                let x = Double(center.x)
                let y = Double(center.y)
                guard calibration.plotXRange.contains(x),
                      calibration.plotYRange.contains(y) else { continue }

                let rawIndex = calibration.frequencyIndex(atX: x)
                let index = Int(rawIndex.rounded())
                let distance = abs(rawIndex - Double(index))
                guard (0...6).contains(index), distance <= 0.35 else { continue }

                let decibel = calibration.decibel(atY: y)
                let rounded = Int((decibel / 5).rounded()) * 5
                guard (-10...120).contains(rounded) else { continue }

                switch side {
                case .right:
                    if distance < rightDistances[index] {
                        rightThresholds[index] = rounded
                        rightDistances[index] = distance
                    }
                case .left:
                    if distance < leftDistances[index] {
                        leftThresholds[index] = rounded
                        leftDistances[index] = distance
                    }
                }
            }
        }

        // 誤検出を避けるため、2点以上読み取れた耳のみ採用する
        var results: [TestResultInput] = []
        if rightThresholds.compactMap({ $0 }).count >= 2 {
            var input = TestResultInput()
            input.ear = "右耳のみ"
            input.thresholdsRight = rightThresholds
            results.append(input)
        }
        if leftThresholds.compactMap({ $0 }).count >= 2 {
            var input = TestResultInput()
            input.ear = "左耳のみ"
            input.thresholdsLeft = leftThresholds
            results.append(input)
        }
        return results
    }

    // MARK: - 軸のキャリブレーション

    private static func calibrate(tokens: [ScannedToken]) -> Calibration? {
        guard let frequency = calibrateFrequencyAxis(tokens: tokens),
              let decibel = calibrateDecibelAxis(tokens: tokens) else {
            return nil
        }

        // プロット領域: 周波数は両端の列の少し外側まで、dBは目盛の少し外側まで
        let xFor: (Double) -> Double = { ($0 - frequency.intercept) / frequency.slope }
        let yFor: (Double) -> Double = { ($0 - decibel.intercept) / decibel.slope }
        let xBounds = [xFor(-0.7), xFor(6.7)]
        let yBounds = [yFor(-20), yFor(135)]

        return Calibration(
            frequencySlope: frequency.slope,
            frequencyIntercept: frequency.intercept,
            decibelSlope: decibel.slope,
            decibelIntercept: decibel.intercept,
            plotXRange: xBounds.min()!...xBounds.max()!,
            plotYRange: yBounds.min()!...yBounds.max()!
        )
    }

    // X軸: 横に並んだ周波数ラベルから「x座標 → 周波数インデックス」の直線を求める
    private static func calibrateFrequencyAxis(tokens: [ScannedToken]) -> (slope: Double, intercept: Double)? {
        var candidates: [(index: Int, x: Double, y: Double)] = []
        for token in tokens {
            if let index = frequencyLabelIndex(token.text) {
                candidates.append((index, Double(token.boundingBox.midX), Double(token.boundingBox.midY)))
            }
        }

        // y座標が近いラベル同士を1つの行とみなし、最も多くの周波数を含む行を軸として使う
        var bestRow: [(index: Int, x: Double, y: Double)] = []
        var bestCount = 0
        for anchor in candidates {
            let row = candidates.filter { abs($0.y - anchor.y) < 0.04 }
            let distinctCount = Set(row.map(\.index)).count
            if distinctCount > bestCount {
                bestRow = row
                bestCount = distinctCount
            }
        }
        guard bestCount >= 3 else { return nil }

        guard let regression = linearRegression(bestRow.map { (x: $0.x, y: Double($0.index)) }),
              regression.slope > 0 else { return nil }
        return regression
    }

    // Y軸: 縦に並んだdBラベルから「y座標 → dB値」の直線を求める
    private static func calibrateDecibelAxis(tokens: [ScannedToken]) -> (slope: Double, intercept: Double)? {
        var candidates: [(value: Int, x: Double, y: Double)] = []
        for token in tokens {
            let trimmed = token.text.trimmingCharacters(in: .whitespaces)
            if let value = Int(trimmed), value % 10 == 0, (-10...120).contains(value) {
                candidates.append((value, Double(token.boundingBox.midX), Double(token.boundingBox.midY)))
            }
        }

        // x座標が近いラベル同士を1つの列とみなし、最も多くの値を含む列を軸として使う
        var bestColumn: [(value: Int, x: Double, y: Double)] = []
        var bestCount = 0
        for anchor in candidates {
            let column = candidates.filter { abs($0.x - anchor.x) < 0.04 }
            let distinctCount = Set(column.map(\.value)).count
            if distinctCount > bestCount {
                bestColumn = column
                bestCount = distinctCount
            }
        }
        guard bestCount >= 4 else { return nil }

        // オージオグラムはdB値が下に向かって大きくなる（Vision座標は上ほどyが大きい）
        // 単調に並んでいない列は軸ラベルではないとみなす
        let sorted = bestColumn.sorted { $0.y > $1.y }
        var seenValues = Set<Int>()
        let unique = sorted.filter { seenValues.insert($0.value).inserted }
        for i in 1..<unique.count where unique[i].value <= unique[i - 1].value {
            return nil
        }

        guard let regression = linearRegression(unique.map { (x: $0.y, y: Double($0.value)) }),
              regression.slope < 0 else { return nil }

        // 回帰直線から大きく外れるラベルがある場合は軸として信頼しない
        for point in unique {
            let predicted = regression.intercept + regression.slope * point.y
            if abs(predicted - Double(point.value)) > 7 { return nil }
        }
        return regression
    }

    private static func frequencyLabelIndex(_ text: String) -> Int? {
        let normalized = text.lowercased()
            .replacingOccurrences(of: "hz", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        switch normalized {
        case "125": return 0
        case "250": return 1
        case "500": return 2
        case "1000", "1k": return 3
        case "2000", "2k": return 4
        case "4000", "4k": return 5
        case "8000", "8k": return 6
        default: return nil
        }
    }

    // MARK: - 記号の検出

    private static func classifySymbol(_ text: String) -> EarSide? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.count <= 7 else { return nil }
        if trimmed.allSatisfy({ rightEarSymbols.contains($0) }) { return .right }
        if trimmed.allSatisfy({ leftEarSymbols.contains($0) }) { return .left }
        return nil
    }

    // 複数の記号が1トークンに結合されている場合は、枠を横に等分割して各記号の中心を求める
    private static func symbolCenters(of token: ScannedToken) -> [CGPoint] {
        let symbolCount = token.text.trimmingCharacters(in: .whitespaces).count
        let box = token.boundingBox
        guard symbolCount > 1 else {
            return [CGPoint(x: box.midX, y: box.midY)]
        }
        let width = box.width / CGFloat(symbolCount)
        return (0..<symbolCount).map { i in
            CGPoint(x: box.minX + width * (CGFloat(i) + 0.5), y: box.midY)
        }
    }

    // MARK: - 最小二乗法

    private static func linearRegression(_ points: [(x: Double, y: Double)]) -> (slope: Double, intercept: Double)? {
        guard points.count >= 2 else { return nil }
        let n = Double(points.count)
        let sumX = points.reduce(0.0) { $0 + $1.x }
        let sumY = points.reduce(0.0) { $0 + $1.y }
        let sumXY = points.reduce(0.0) { $0 + $1.x * $1.y }
        let sumXX = points.reduce(0.0) { $0 + $1.x * $1.x }
        let denominator = n * sumXX - sumX * sumX
        guard abs(denominator) > 1e-9 else { return nil }
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        return (slope, intercept)
    }
}
