//
//  SimulationSourceTests.swift
//  HearingSupportAppTests
//
//  聞こえ方シミュレーションで使う聴力データ候補(SimulationSource)の
//  生成ロジックを検証するテスト。
//

import XCTest
import SwiftData
@testable import HearingSupportApp

@MainActor
final class SimulationSourceTests: XCTestCase {

    private let freqs = ["125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz"]

    /// テスト用のインメモリ ModelContext を作る
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Child.self, Record.self, TestResult.self, AppSettings.self, Appointment.self,
            configurations: config
        )
        return container.mainContext
    }

    private func makeChild(in ctx: ModelContext) throws -> Child {
        let child = try Child(name: "テスト児")
        ctx.insert(child)
        return child
    }

    // MARK: - ID の安定性（今回修正したバグの回帰テスト）

    func testCandidateIDsAreStableAcrossCalls() throws {
        let ctx = try makeContext()
        let child = try makeChild(in: ctx)
        let tr = try TestResult(ear: "両耳", condition: "裸耳",
                                thresholdsBoth: [20, 30, 40, 50, 60, 70, 80], freqs: freqs)
        let rec = try Record(date: Date(), hospital: "病院", title: "検査", detail: "", results: [tr], child: child)
        ctx.insert(rec)
        child.records = [rec]

        let first = SimulationSource.candidates(from: child)
        let second = SimulationSource.candidates(from: child)

        XCTAssertEqual(first.count, 1)
        // 呼び出しごとに同じID（=元のTestResultのID）になること
        XCTAssertEqual(first.map(\.id), second.map(\.id))
        XCTAssertEqual(first.first?.id, tr.id)
    }

    // MARK: - 並び順・抽出

    func testCandidatesPrioritizeNakedEar() throws {
        let ctx = try makeContext()
        let child = try makeChild(in: ctx)
        let aided = try TestResult(ear: "両耳", condition: "補聴器",
                                   thresholdsBoth: [20, 30, 40, 50, 60, 70, 80], freqs: freqs)
        let naked = try TestResult(ear: "両耳", condition: "裸耳",
                                   thresholdsBoth: [30, 40, 50, 60, 70, 80, 90], freqs: freqs)
        // 補聴器を先に並べても裸耳が優先されること
        let rec = try Record(date: Date(), hospital: "病院", title: "検査", detail: "", results: [aided, naked], child: child)
        ctx.insert(rec)
        child.records = [rec]

        let sources = SimulationSource.candidates(from: child)
        XCTAssertEqual(sources.count, 2)
        XCTAssertTrue(sources.first?.earCondition.contains("裸耳") ?? false)
    }

    func testCandidatesSkipResultsWithoutData() throws {
        let ctx = try makeContext()
        let child = try makeChild(in: ctx)
        // 全周波数が未測定（nil）の結果は候補に含めない
        let empty = try TestResult(ear: "両耳", condition: "裸耳",
                                   thresholdsBoth: [nil, nil, nil, nil, nil, nil, nil], freqs: freqs)
        let rec = try Record(date: Date(), hospital: "病院", title: "検査", detail: "", results: [empty], child: child)
        ctx.insert(rec)
        child.records = [rec]

        XCTAssertTrue(SimulationSource.candidates(from: child).isEmpty)
    }

    func testCandidatesNewerRecordComesFirst() throws {
        let ctx = try makeContext()
        let child = try makeChild(in: ctx)
        let old = try TestResult(ear: "両耳", condition: "裸耳",
                                 thresholdsBoth: [20, 30, 40, 50, 60, 70, 80], freqs: freqs)
        let new = try TestResult(ear: "両耳", condition: "裸耳",
                                 thresholdsBoth: [25, 35, 45, 55, 65, 75, 85], freqs: freqs)
        let oldRec = try Record(date: Date(timeIntervalSince1970: 1_000),
                                hospital: "A", title: "t", detail: "", results: [old], child: child)
        let newRec = try Record(date: Date(timeIntervalSince1970: 2_000),
                                hospital: "B", title: "t", detail: "", results: [new], child: child)
        ctx.insert(oldRec)
        ctx.insert(newRec)
        child.records = [oldRec, newRec]

        let sources = SimulationSource.candidates(from: child)
        XCTAssertEqual(sources.count, 2)
        XCTAssertEqual(sources.first?.id, new.id, "同条件なら新しい検査が先頭になること")
    }

    func testCandidatesEmptyWhenNoRecords() throws {
        let ctx = try makeContext()
        let child = try makeChild(in: ctx)
        XCTAssertTrue(SimulationSource.candidates(from: child).isEmpty)
    }
}
