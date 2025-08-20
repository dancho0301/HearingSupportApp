//
//  NotificationManager.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/08/19.
//

import Foundation
import UserNotifications
import SwiftData

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    // 通知許可の要求
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("通知許可の要求でエラー: \(error)")
            return false
        }
    }
    
    // 通院予定のリマインダーを設定
    func scheduleAppointmentReminder(for appointment: Appointment) async {
        let center = UNUserNotificationCenter.current()
        
        // 通知許可を確認
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("通知許可がありません")
            return
        }
        
        // 既存の通知を削除
        center.removePendingNotificationRequests(withIdentifiers: [appointment.id.uuidString])
        
        guard appointment.reminderEnabled,
              let reminderTime = appointment.reminderTime,
              reminderTime > Date() else {
            print("リマインダーが無効、または過去の日時です: \(appointment.hospital)")
            return
        }
        
        // 通知内容を作成
        let content = UNMutableNotificationContent()
        content.title = "通院予定のお知らせ"
        content.body = "\(appointment.hospital)での\(appointment.purpose)の予定があります"
        content.sound = .default
        content.badge = 1
        
        // 日時を指定して通知をスケジュール
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // 通知リクエストを作成
        let request = UNNotificationRequest(
            identifier: appointment.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("通知をスケジュールしました: \(appointment.hospital) - \(reminderTime)")
            
            // 確認のため現在の予定通知数をチェック
            let pendingRequests = await center.pendingNotificationRequests()
            print("現在の予定通知数: \(pendingRequests.count)")
        } catch {
            print("通知のスケジュールでエラー: \(error)")
        }
    }
    
    // 通院予定の通知をキャンセル
    func cancelAppointmentReminder(for appointment: Appointment) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [appointment.id.uuidString])
    }
    
    // すべての通院予定の通知を更新
    func updateAllAppointmentReminders(appointments: [Appointment]) async {
        let center = UNUserNotificationCenter.current()
        
        // 現在の許可状況を確認
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("通知許可がありません")
            return
        }
        
        // 既存の通院予定関連の通知をすべてキャンセル
        let pendingRequests = await center.pendingNotificationRequests()
        let appointmentIds = appointments.map { $0.id.uuidString }
        let idsToRemove = pendingRequests.compactMap { request in
            appointmentIds.contains(request.identifier) ? request.identifier : nil
        }
        center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        
        // 新しい通知をスケジュール
        for appointment in appointments {
            if !appointment.isCompleted {
                await scheduleAppointmentReminder(for: appointment)
            }
        }
    }
    
    // 通知許可状況の確認
    func checkNotificationStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
}