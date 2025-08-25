//
//  AppointmentListView.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/08/19.
//

import SwiftUI
import SwiftData

struct AppointmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Appointment.appointmentDate, order: .forward) private var appointments: [Appointment]
    @State private var showingForm = false
    @State private var editingAppointment: Appointment?
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("今後の予定")) {
                    if upcomingAppointments.isEmpty {
                        Text("今後の予定はありません")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(upcomingAppointments) { appointment in
                            AppointmentRowView(appointment: appointment) {
                                editingAppointment = appointment
                                showingForm = true
                            }
                        }
                        .onDelete(perform: deleteUpcomingAppointments)
                    }
                }
                
                if !completedAppointments.isEmpty {
                    Section(header: Text("完了した予定")) {
                        ForEach(completedAppointments) { appointment in
                            AppointmentRowView(appointment: appointment, isCompleted: true) {
                                editingAppointment = appointment
                                showingForm = true
                            }
                        }
                        .onDelete(perform: deleteCompletedAppointments)
                    }
                }
            }
            .navigationTitle("通院予定")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                print("AppointmentListView: appointments count = \(appointments.count)")
                for (index, appointment) in appointments.enumerated() {
                    print("Appointment \(index): \(appointment.hospital) - \(appointment.appointmentDate)")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        editingAppointment = nil
                        showingForm = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                NavigationStack {
                    AppointmentFormView(
                        appointment: editingAppointment,
                        onSave: saveAppointment,
                        onDelete: deleteCurrentAppointment,
                        onCancel: {
                            print("AppointmentListView: onCancel が呼ばれました - showingForm: \(showingForm)")
                            editingAppointment = nil
                            showingForm = false
                            print("AppointmentListView: 状態リセット完了 - showingForm: \(showingForm)")
                        }
                    )
                }
            }
        }
    }
    
    private var upcomingAppointments: [Appointment] {
        return appointments.filter { !$0.isCompleted }
    }
    
    private var completedAppointments: [Appointment] {
        return appointments.filter { $0.isCompleted }
    }
    
    private func saveAppointment(hospital: String, date: Date, time: Date, purpose: String, notes: String, reminderEnabled: Bool) {
        if let editingAppointment = editingAppointment {
            // 編集
            editingAppointment.hospital = hospital
            editingAppointment.appointmentDate = date
            editingAppointment.appointmentTime = time
            editingAppointment.purpose = purpose
            editingAppointment.notes = notes
            editingAppointment.reminderEnabled = reminderEnabled
            
            // リマインダー時間を再計算
            if reminderEnabled {
                let calendar = Calendar.current
                if let appointmentDateTime = calendar.date(
                    bySettingHour: calendar.component(.hour, from: time),
                    minute: calendar.component(.minute, from: time),
                    second: 0,
                    of: date
                ) {
                    editingAppointment.reminderTime = calendar.date(byAdding: .hour, value: -1, to: appointmentDateTime)
                }
            } else {
                editingAppointment.reminderTime = nil
            }
        } else {
            // 新規作成
            let newAppointment = Appointment(
                hospital: hospital,
                appointmentDate: date,
                appointmentTime: time,
                purpose: purpose,
                notes: notes,
                reminderEnabled: reminderEnabled
            )
            print("新しいAppointmentを作成: \(newAppointment.hospital) - \(newAppointment.appointmentDate)")
            modelContext.insert(newAppointment)
        }
        
        do {
            try modelContext.save()
            print("Appointment保存成功")
        } catch {
            print("Appointment保存エラー: \(error)")
        }
        
        // 個別の通知を設定
        Task {
            if let editingAppointment = editingAppointment {
                await NotificationManager.shared.scheduleAppointmentReminder(for: editingAppointment)
            } else {
                // 新規作成の場合、最後に追加されたアポイントメントの通知を設定
                if let lastAppointment = appointments.last {
                    await NotificationManager.shared.scheduleAppointmentReminder(for: lastAppointment)
                }
            }
        }
        
        editingAppointment = nil
        showingForm = false
    }
    
    private func deleteCurrentAppointment() {
        if let editingAppointment = editingAppointment {
            NotificationManager.shared.cancelAppointmentReminder(for: editingAppointment)
            modelContext.delete(editingAppointment)
            do {
                try modelContext.save()
                print("削除成功: \(editingAppointment.hospital) - \(editingAppointment.appointmentDate)")
            } catch {
                print("削除エラー: \(error)")
            }
        }
        editingAppointment = nil
        showingForm = false
    }
    
    private func deleteUpcomingAppointments(at offsets: IndexSet) {
        let upcomingList = upcomingAppointments
        for index in offsets {
            guard index < upcomingList.count else { 
                print("インデックス範囲外: \(index) >= \(upcomingList.count)")
                continue 
            }
            let appointment = upcomingList[index]
            print("今後の予定を削除: \(appointment.hospital) - \(appointment.appointmentDate)")
            NotificationManager.shared.cancelAppointmentReminder(for: appointment)
            modelContext.delete(appointment)
        }
        do {
            try modelContext.save()
            print("今後の予定の削除保存成功")
        } catch {
            print("今後の予定の削除保存エラー: \(error)")
        }
    }
    
    private func deleteCompletedAppointments(at offsets: IndexSet) {
        let completedList = completedAppointments
        for index in offsets {
            guard index < completedList.count else { 
                print("インデックス範囲外: \(index) >= \(completedList.count)")
                continue 
            }
            let appointment = completedList[index]
            print("完了した予定を削除: \(appointment.hospital) - \(appointment.appointmentDate)")
            NotificationManager.shared.cancelAppointmentReminder(for: appointment)
            modelContext.delete(appointment)
        }
        do {
            try modelContext.save()
            print("完了した予定の削除保存成功")
        } catch {
            print("完了した予定の削除保存エラー: \(error)")
        }
    }
}

struct AppointmentRowView: View {
    let appointment: Appointment
    var isCompleted: Bool = false
    let onEdit: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(dateFormatter.string(from: appointment.appointmentDate))
                        .font(.headline)
                        .foregroundColor(isCompleted ? .secondary : .primary)
                    
                    Text(timeFormatter.string(from: appointment.appointmentTime))
                        .font(.subheadline)
                        .foregroundColor(isCompleted ? .secondary : .orange)
                }
                
                Text(appointment.hospital)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(appointment.purpose)
                    .font(.body)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                
                if !appointment.notes.isEmpty {
                    Text(appointment.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if appointment.reminderEnabled && !isCompleted {
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("リマインダー設定済み")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            if !isCompleted {
                Button(action: {
                    appointment.isCompleted = true
                    try? modelContext.save()
                }) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
}