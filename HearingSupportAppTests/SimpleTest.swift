//
//  SimpleTest.swift
//  HearingSupportAppTests
//
//  Created by dancho on 2025/08/20.
//

import XCTest
@testable import HearingSupportApp

final class SimpleTest: XCTestCase {
    
    func testBasicFunctionality() {
        // 基本的なテスト
        XCTAssertEqual(2 + 2, 4, "基本的な計算が正しくありません")
    }
    
    func testTestResultCreation() {
        // TestResultの作成テスト
        let testResult = TestResult(
            ear: "右耳のみ",
            condition: "裸耳",
            thresholdsRight: [20, 25, 30, 35, 40, 45, 50],
            freqs: ["125", "250", "500", "1k", "2k", "4k", "8k"]
        )
        
        XCTAssertNotNil(testResult)
        XCTAssertEqual(testResult.ear, "右耳のみ")
        XCTAssertEqual(testResult.condition, "裸耳")
    }
}