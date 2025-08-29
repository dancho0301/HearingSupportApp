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
                if appointments.isEmpty {
                    Text("予定はありません")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(appointments) { appointment in
                        AppointmentRowView(appointment: appointment) {
                            editingAppointment = appointment
                            showingForm = true
                        }
                    }
                    .onDelete(perform: deleteAppointments)
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
    
    
    private func saveAppointment(hospital: String, date: Date, time: Date, purpose: String, notes: String) {
        if let editingAppointment = editingAppointment {
            // 編集
            editingAppointment.hospital = hospital
            editingAppointment.appointmentDate = date
            editingAppointment.appointmentTime = time
            editingAppointment.purpose = purpose
            editingAppointment.notes = notes
        } else {
            // 新規作成
            do {
                let newAppointment = try Appointment(
                    hospital: hospital,
                    appointmentDate: date,
                    appointmentTime: time,
                    purpose: purpose,
                    notes: notes
                )
                print("新しいAppointmentを作成: \(newAppointment.hospital) - \(newAppointment.appointmentDate)")
                modelContext.insert(newAppointment)
            } catch {
                print("Appointment作成エラー: \(error.localizedDescription)")
                return
            }
        }
        
        do {
            try modelContext.save()
            print("Appointment保存成功")
        } catch {
            print("Appointment保存エラー: \(error)")
        }
        
        
        editingAppointment = nil
        showingForm = false
    }
    
    private func deleteCurrentAppointment() {
        if let editingAppointment = editingAppointment {
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
    
    private func deleteAppointments(at offsets: IndexSet) {
        for index in offsets {
            guard index < appointments.count else { 
                print("インデックス範囲外: \(index) >= \(appointments.count)")
                continue 
            }
            let appointment = appointments[index]
            print("予定を削除: \(appointment.hospital) - \(appointment.appointmentDate)")
            modelContext.delete(appointment)
        }
        do {
            try modelContext.save()
            print("予定の削除保存成功")
        } catch {
            print("予定の削除保存エラー: \(error)")
        }
    }
}

struct AppointmentRowView: View {
    let appointment: Appointment
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
                    
                    Text(timeFormatter.string(from: appointment.appointmentTime))
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                
                Text(appointment.hospital)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(appointment.purpose)
                    .font(.body)
                
                if !appointment.notes.isEmpty {
                    Text(appointment.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
}