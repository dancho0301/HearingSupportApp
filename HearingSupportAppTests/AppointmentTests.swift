//
//  AppointmentTests.swift
//  HearingSupportAppTests
//
//  Created by dancho on 2025/08/20.
//

import XCTest
import Foundation
@testable import HearingSupportApp

final class AppointmentTests: XCTestCase {
    
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        calendar = Calendar.current
    }
    
    override func tearDown() {
        calendar = nil
        super.tearDown()
    }
    
    // MARK: - Appointment Date/Time Tests
    
    func testFullAppointmentDateCombination() {
        // 異なる日付と時刻の組み合わせテスト
        let appointmentDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 25))!
        let appointmentTime = calendar.date(from: DateComponents(hour: 9, minute: 45))!
        
        let appointment = Appointment(
            hospital: "クリスマス病院",
            appointmentDate: appointmentDate,
            appointmentTime: appointmentTime,
            purpose: "特別検査",
            reminderEnabled: false
        )
        
        let fullDate = appointment.fullAppointmentDate
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fullDate)
        
        XCTAssertEqual(components.year, 2025, "年が正しく設定されていません")
        XCTAssertEqual(components.month, 12, "月が正しく設定されていません")
        XCTAssertEqual(components.day, 25, "日が正しく設定されていません")
        XCTAssertEqual(components.hour, 9, "時が正しく設定されていません")
        XCTAssertEqual(components.minute, 45, "分が正しく設定されていません")
    }
    
    func testFullAppointmentDateEdgeCases() {
        // 境界値テスト（0時0分、23時59分）
        let appointmentDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 28))!
        
        // 0時0分のテスト
        let midnightTime = calendar.date(from: DateComponents(hour: 0, minute: 0))!
        let midnightAppointment = Appointment(
            hospital: "深夜病院",
            appointmentDate: appointmentDate,
            appointmentTime: midnightTime,
            purpose: "緊急検査",
            reminderEnabled: false
        )
        
        let midnightFull = midnightAppointment.fullAppointmentDate
        let midnightComponents = calendar.dateComponents([.hour, .minute], from: midnightFull)
        XCTAssertEqual(midnightComponents.hour, 0)
        XCTAssertEqual(midnightComponents.minute, 0)
        
        // 23時59分のテスト
        let lateTime = calendar.date(from: DateComponents(hour: 23, minute: 59))!
        let lateAppointment = Appointment(
            hospital: "夜間病院",
            appointmentDate: appointmentDate,
            appointmentTime: lateTime,
            purpose: "夜間検査",
            reminderEnabled: false
        )
        
        let lateFull = lateAppointment.fullAppointmentDate
        let lateComponents = calendar.dateComponents([.hour, .minute], from: lateFull)
        XCTAssertEqual(lateComponents.hour, 23)
        XCTAssertEqual(lateComponents.minute, 59)
    }
    
    // MARK: - Reminder Time Tests
    
    func testReminderTimeCalculation() {
        let appointmentDate = calendar.date(from: DateComponents(year: 2025, month: 8, day: 20))!
        let appointmentTime = calendar.date(from: DateComponents(hour: 14, minute: 30))!
        
        let appointment = Appointment(
            hospital: "リマインダー病院",
            appointmentDate: appointmentDate,
            appointmentTime: appointmentTime,
            purpose: "定期検査",
            reminderEnabled: true
        )
        
        guard let reminderTime = appointment.reminderTime else {
            XCTFail("リマインダー時刻が設定されていません")
            return
        }
        
        let reminderComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        
        // 1時間前（13:30）になっているかチェック
        XCTAssertEqual(reminderComponents.year, 2025)
        XCTAssertEqual(reminderComponents.month, 8)
        XCTAssertEqual(reminderComponents.day, 20)
        XCTAssertEqual(reminderComponents.hour, 13)
        XCTAssertEqual(reminderComponents.minute, 30)
    }
    
    func testReminderTimeAcrossDayBoundary() {
        // 0時30分の予約の場合、前日23時30分にリマインダーが設定されるかテスト
        let appointmentDate = calendar.date(from: DateComponents(year: 2025, month: 8, day: 20))!
        let appointmentTime = calendar.date(from: DateComponents(hour: 0, minute: 30))!
        
        let appointment = Appointment(
            hospital: "深夜病院",
            appointmentDate: appointmentDate,
            appointmentTime: appointmentTime,
            purpose: "深夜検査",
            reminderEnabled: true
        )
        
        guard let reminderTime = appointment.reminderTime else {
            XCTFail("リマインダー時刻が設定されていません")
            return
        }
        
        let reminderComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        
        // 前日の23時30分になっているかチェック
        XCTAssertEqual(reminderComponents.year, 2025)
        XCTAssertEqual(reminderComponents.month, 8)
        XCTAssertEqual(reminderComponents.day, 19) // 前日
        XCTAssertEqual(reminderComponents.hour, 23)
        XCTAssertEqual(reminderComponents.minute, 30)
    }
    
    func testReminderDisabled() {
        let appointment = Appointment(
            hospital: "リマインダー無効病院",
            appointmentDate: Date(),
            appointmentTime: Date(),
            purpose: "リマインダー無しテスト",
            reminderEnabled: false
        )
        
        XCTAssertNil(appointment.reminderTime, "リマインダーが無効の場合は時刻が設定されないはず")
    }
    
    // MARK: - Appointment State Tests
    
    func testAppointmentInitialState() {
        let appointment = Appointment(
            hospital: "初期状態病院",
            appointmentDate: Date(),
            appointmentTime: Date(),
            purpose: "初期状態テスト"
        )
        
        XCTAssertFalse(appointment.isCompleted, "新規作成時は未完了状態のはず")
        XCTAssertTrue(appointment.reminderEnabled, "デフォルトでリマインダーが有効のはず")
        XCTAssertNotNil(appointment.id, "IDが設定されているはず")
    }
    
    func testAppointmentCompletion() {
        let appointment = Appointment(
            hospital: "完了テスト病院",
            appointmentDate: Date(),
            appointmentTime: Date(),
            purpose: "完了テスト"
        )
        
        // 初期状態では未完了
        XCTAssertFalse(appointment.isCompleted)
        
        // 完了状態に変更
        appointment.isCompleted = true
        XCTAssertTrue(appointment.isCompleted)
        
        // 再度未完了に変更
        appointment.isCompleted = false
        XCTAssertFalse(appointment.isCompleted)
    }
    
    // MARK: - Appointment Data Validation Tests
    
    func testAppointmentWithEmptyNotes() {
        let appointment = Appointment(
            hospital: "空メモ病院",
            appointmentDate: Date(),
            appointmentTime: Date(),
            purpose: "空メモテスト",
            notes: "", // 空のメモ
            reminderEnabled: true
        )
        
        XCTAssertEqual(appointment.notes, "")
        XCTAssertEqual(appointment.hospital, "空メモ病院")
        XCTAssertEqual(appointment.purpose, "空メモテスト")
    }
    
    func testAppointmentWithLongNotes() {
        let longNotes = "これは長いメモです。検査結果について詳細な記録を残します。聴力検査の結果、軽度の聴力低下が確認されました。"
        
        let appointment = Appointment(
            hospital: "長文メモ病院",
            appointmentDate: Date(),
            appointmentTime: Date(),
            purpose: "長文テスト",
            notes: longNotes,
            reminderEnabled: true
        )
        
        XCTAssertEqual(appointment.notes, longNotes)
        XCTAssertTrue(appointment.notes.count > 30, "長文メモが正しく保存されているか")
    }
    
    // MARK: - Multiple Appointments Tests
    
    func testMultipleAppointmentsSameDay() {
        let appointmentDate = calendar.date(from: DateComponents(year: 2025, month: 8, day: 20))!
        let morningTime = calendar.date(from: DateComponents(hour: 9, minute: 0))!
        let afternoonTime = calendar.date(from: DateComponents(hour: 15, minute: 30))!
        
        let morningAppointment = Appointment(
            hospital: "午前病院",
            appointmentDate: appointmentDate,
            appointmentTime: morningTime,
            purpose: "午前検査"
        )
        
        let afternoonAppointment = Appointment(
            hospital: "午後病院",
            appointmentDate: appointmentDate,
            appointmentTime: afternoonTime,
            purpose: "午後検査"
        )
        
        // 同じ日の異なる時間の予約
        XCTAssertNotEqual(morningAppointment.id, afternoonAppointment.id, "異なる予約のIDは異なるはず")
        
        let morningFull = morningAppointment.fullAppointmentDate
        let afternoonFull = afternoonAppointment.fullAppointmentDate
        
        XCTAssertTrue(morningFull < afternoonFull, "午前の予約が午後の予約より早い時刻のはず")
        
        // 同じ日付の部分をチェック
        let morningDateComponents = calendar.dateComponents([.year, .month, .day], from: morningFull)
        let afternoonDateComponents = calendar.dateComponents([.year, .month, .day], from: afternoonFull)
        
        XCTAssertEqual(morningDateComponents.year, afternoonDateComponents.year)
        XCTAssertEqual(morningDateComponents.month, afternoonDateComponents.month)
        XCTAssertEqual(morningDateComponents.day, afternoonDateComponents.day)
    }
}