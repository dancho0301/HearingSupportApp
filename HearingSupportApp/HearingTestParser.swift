//
//  HearingTestParser.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/08/20.
//

import Foundation
import SwiftUI

struct HearingTestParser {
    static func parseOCRText(_ text: String) -> TestResultInput? {
        let lines = text.components(separatedBy: .newlines)
        var testResult = TestResultInput()
        
        // 周波数のマッピング（Hz表記）
        let frequencyMappings: [String: Int] = [
            "125": 0, "250": 1, "500": 2, "1000": 3, "1k": 3, "1K": 3,
            "2000": 4, "2k": 4, "2K": 4, "4000": 5, "4k": 5, "4K": 5,
            "8000": 6, "8k": 6, "8K": 6
        ]
        
        // オージオグラム特有のキーワード（気導検査のみ対応）
        let audiogramKeywords = ["オージオグラム", "聴力検査", "気導", "周波数", "dB", "Hz"]
        let isAudiogram = audiogramKeywords.contains { keyword in
            text.contains(keyword)
        }
        
        // 耳の判定
        let rightEarKeywords = ["右", "右耳", "R", "Right"]
        let leftEarKeywords = ["左", "左耳", "L", "Left"]
        
        var hasRightEarData = false
        var hasLeftEarData = false
        var testType = "裸耳"  // デフォルト値
        
        // 検査種類の判定
        if text.contains("補聴器") || text.contains("HA") {
            testType = "補聴器"
        } else if text.contains("人工内耳") || text.contains("CI") {
            testType = "人工内耳"
        }
        
        // オージオグラム専用の解析
        if isAudiogram {
            parseAudiogramData(text: text, testResult: &testResult, frequencyMappings: frequencyMappings)
        } else {
            // 従来の解析方法
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                
                // 耳の種類を判定
                let hasRightKeyword = rightEarKeywords.contains { trimmedLine.contains($0) }
                let hasLeftKeyword = leftEarKeywords.contains { trimmedLine.contains($0) }
                
                if hasRightKeyword {
                    hasRightEarData = true
                    parseThresholds(from: trimmedLine, for: .right, into: &testResult, frequencyMappings: frequencyMappings)
                } else if hasLeftKeyword {
                    hasLeftEarData = true
                    parseThresholds(from: trimmedLine, for: .left, into: &testResult, frequencyMappings: frequencyMappings)
                } else {
                    // キーワードがない場合は数値だけを探す
                    parseThresholds(from: trimmedLine, for: .both, into: &testResult, frequencyMappings: frequencyMappings)
                }
            }
            
            // 耳の設定を決定
            if hasRightEarData && hasLeftEarData {
                testResult.ear = "両耳"
            } else if hasRightEarData {
                testResult.ear = "右耳のみ"
            } else if hasLeftEarData {
                testResult.ear = "左耳のみ"
            }
        }
        
        testResult.condition = testType
        
        // データが全く見つからない場合はnilを返す
        let hasAnyData = testResult.thresholdsRight.contains { $0 != nil } ||
                        testResult.thresholdsLeft.contains { $0 != nil } ||
                        testResult.thresholdsBoth.contains { $0 != nil }
        
        return hasAnyData ? testResult : nil
    }
    
    private static func parseAudiogramData(text: String, testResult: inout TestResultInput, frequencyMappings: [String: Int]) {
        // オージオグラム特有の解析ロジック（気導検査のみ対応）
        // 注意: 骨導検査は将来のバージョンで対応予定
        let lines = text.components(separatedBy: .newlines)
        var hasRightData = false
        var hasLeftData = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // 気導検査の記号を探す: ○（右耳）、×（左耳）
            if trimmedLine.contains("○") || trimmedLine.contains("右") {
                hasRightData = true
                parseAudiogramLine(trimmedLine, for: .right, into: &testResult, frequencyMappings: frequencyMappings)
            }
            
            if trimmedLine.contains("×") || trimmedLine.contains("左") {
                hasLeftData = true
                parseAudiogramLine(trimmedLine, for: .left, into: &testResult, frequencyMappings: frequencyMappings)
            }
        }
        
        // 耳の設定を決定
        if hasRightData && hasLeftData {
            testResult.ear = "両耳"
        } else if hasRightData {
            testResult.ear = "右耳のみ"
        } else if hasLeftData {
            testResult.ear = "左耳のみ"
        }
    }
    
    private static func parseAudiogramLine(_ line: String, for ear: EarType, into testResult: inout TestResultInput, frequencyMappings: [String: Int]) {
        // 気導聴力の数値を探す（聴力レベルの範囲: -10dB ~ 120dB）
        let numberPattern = #"(-?\d+)"#
        let numberRegex = try! NSRegularExpression(pattern: numberPattern, options: [])
        let numberMatches = numberRegex.matches(in: line, options: [], range: NSRange(location: 0, length: line.count))
        
        var detectedNumbers: [Int] = []
        for match in numberMatches {
            if let range = Range(match.range, in: line) {
                if let number = Int(String(line[range])), number <= 120 && number >= -10 {
                    // 周波数の値（125, 250, 500など）は除外
                    if ![125, 250, 500, 1000, 2000, 4000, 8000].contains(number) {
                        detectedNumbers.append(number)
                    }
                }
            }
        }
        
        // 7つの周波数に対応する聴力値を設定
        if detectedNumbers.count >= 7 {
            for (index, value) in detectedNumbers.prefix(7).enumerated() {
                switch ear {
                case .right:
                    testResult.thresholdsRight[index] = value
                case .left:
                    testResult.thresholdsLeft[index] = value
                case .both:
                    testResult.thresholdsBoth[index] = value
                }
            }
        }
        
        // 明示的な周波数とdB値のペアを探す
        let frequencyPattern = #"(125|250|500|1000|2000|4000|8000)\s*[Hh]?[Zz]?\s*[:\-]?\s*(-?\d+)\s*[dD]?[Bb]?"#
        let regex = try! NSRegularExpression(pattern: frequencyPattern, options: .caseInsensitive)
        let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: line.count))
        
        for match in matches {
            if let freqRange = Range(match.range(at: 1), in: line),
               let dbRange = Range(match.range(at: 2), in: line) {
                let frequency = String(line[freqRange])
                let dbString = String(line[dbRange])
                
                if let freqIndex = frequencyMappings[frequency],
                   let dbValue = Int(dbString), dbValue <= 120 && dbValue >= -10 {
                    
                    switch ear {
                    case .right:
                        testResult.thresholdsRight[freqIndex] = dbValue
                    case .left:
                        testResult.thresholdsLeft[freqIndex] = dbValue
                    case .both:
                        testResult.thresholdsBoth[freqIndex] = dbValue
                    }
                }
            }
        }
        
        // スケールアウト（測定不能）の処理
        if line.contains("↓") || line.contains("矢印") || line.contains("スケールアウト") || line.contains("NR") {
            // スケールアウトの場合は120dBに設定
            let scaleOutValue = 120
            for i in 0..<7 {
                switch ear {
                case .right:
                    if testResult.thresholdsRight[i] == nil {
                        testResult.thresholdsRight[i] = scaleOutValue
                    }
                case .left:
                    if testResult.thresholdsLeft[i] == nil {
                        testResult.thresholdsLeft[i] = scaleOutValue
                    }
                case .both:
                    if testResult.thresholdsBoth[i] == nil {
                        testResult.thresholdsBoth[i] = scaleOutValue
                    }
                }
            }
        }
    }
    
    private enum EarType {
        case right, left, both
    }
    
    private static func parseThresholds(from line: String, for ear: EarType, into testResult: inout TestResultInput, frequencyMappings: [String: Int]) {
        // 数値パターンを検索 (dBの前の数値を探す)
        let pattern = #"(\d+)\s*(?:dB|db|DB)?"#
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: line.count))
        
        var thresholdValues: [Int] = []
        for match in matches {
            if let range = Range(match.range(at: 1), in: line) {
                if let value = Int(String(line[range])), value <= 120 {
                    thresholdValues.append(value)
                }
            }
        }
        
        // 周波数を検索
        var frequencyIndices: [Int] = []
        for (freqStr, index) in frequencyMappings {
            if line.contains(freqStr) {
                frequencyIndices.append(index)
            }
        }
        
        // 値を適切な位置に配置
        if !frequencyIndices.isEmpty && !thresholdValues.isEmpty {
            for (freqIndex, threshold) in zip(frequencyIndices, thresholdValues) {
                switch ear {
                case .right:
                    testResult.thresholdsRight[freqIndex] = threshold
                case .left:
                    testResult.thresholdsLeft[freqIndex] = threshold
                case .both:
                    testResult.thresholdsBoth[freqIndex] = threshold
                }
            }
        } else if thresholdValues.count >= 7 {
            // 7つ以上の値がある場合は順番に配置
            for (index, threshold) in thresholdValues.prefix(7).enumerated() {
                switch ear {
                case .right:
                    testResult.thresholdsRight[index] = threshold
                case .left:
                    testResult.thresholdsLeft[index] = threshold
                case .both:
                    testResult.thresholdsBoth[index] = threshold
                }
            }
        }
    }
}