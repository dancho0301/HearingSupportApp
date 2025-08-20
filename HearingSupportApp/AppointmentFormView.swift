//
//  AppointmentFormView.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/08/19.
//

import SwiftUI
import SwiftData

struct AppointmentFormView: View {
    @Environment(\.dismiss) var dismiss
    @Query private var appSettings: [AppSettings]
    
    let appointment: Appointment?
    let onSave: (String, Date, Date, String, String, Bool) -> Void
    let onDelete: (() -> Void)?
    let onCancel: () -> Void
    
    @State private var selectedHospitalIndex: Int = 0
    @State private var newHospital: String = ""
    @State private var appointmentDate: Date = Date()
    @State private var appointmentTime: Date = Date()
    @State private var purpose: String = ""
    @State private var notes: String = ""
    @State private var reminderEnabled: Bool = true
    
    private var settings: AppSettings? {
        appSettings.first
    }
    
    private let purposeOptions = [
        "定期検査",
        "聴力検査",
        "補聴器調整",
        "人工内耳調整",
        "診察・相談",
        "その他"
    ]
    
    init(appointment: Appointment?, onSave: @escaping (String, Date, Date, String, String, Bool) -> Void, onDelete: (() -> Void)? = nil, onCancel: @escaping () -> Void) {
        self.appointment = appointment
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        
        if let appointment = appointment {
            _appointmentDate = State(initialValue: appointment.appointmentDate)
            _appointmentTime = State(initialValue: appointment.appointmentTime)
            _purpose = State(initialValue: appointment.purpose)
            _notes = State(initialValue: appointment.notes)
            _reminderEnabled = State(initialValue: appointment.reminderEnabled)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本情報")) {
                    // 病院選択
                    if let settings = settings {
                        Picker("病院", selection: $selectedHospitalIndex) {
                            ForEach(0..<(settings.hospitalList.count + 1), id: \.self) { idx in
                                if idx < settings.hospitalList.count && idx >= 0 {
                                    Text(settings.hospitalList[idx])
                                } else {
                                    Text("新規入力")
                                }
                            }
                        }
                        
                        if selectedHospitalIndex == settings.hospitalList.count {
                            TextField("新しい病院名を入力", text: $newHospital)
                        }
                    }
                    
                    // 日付選択
                    DatePicker("予定日", selection: $appointmentDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                    
                    // 時間選択
                    DatePicker("時間", selection: $appointmentTime, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                }
                
                Section(header: Text("内容")) {
                    Picker("目的", selection: $purpose) {
                        ForEach(purposeOptions, id: \.self) { purpose in
                            Text(purpose)
                        }
                    }
                    
                    TextField("メモ・備考", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("リマインダー")) {
                    Toggle("リマインダーを有効にする", isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        Text("予約時間の1時間前に通知します")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button("保存") {
                        let hospitalName: String
                        if let settings = settings {
                            if selectedHospitalIndex == settings.hospitalList.count {
                                hospitalName = newHospital
                            } else if selectedHospitalIndex < settings.hospitalList.count {
                                hospitalName = settings.hospitalList[selectedHospitalIndex]
                            } else {
                                hospitalName = newHospital
                            }
                        } else {
                            hospitalName = newHospital
                        }
                        
                        onSave(hospitalName, appointmentDate, appointmentTime, purpose, notes, reminderEnabled)
                    }
                    .disabled(purpose.isEmpty || (selectedHospitalIndex == (settings?.hospitalList.count ?? 0) && newHospital.isEmpty))
                    
                    if appointment != nil, let onDelete = onDelete {
                        Button("削除", role: .destructive) {
                            print("削除ボタンが押されました")
                            onDelete()
                        }
                    }
                }
            }
            .navigationTitle(appointment == nil ? "予定の追加" : "予定の編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        print("🔥 AppointmentFormView: キャンセルボタンがタップされました")
                        onCancel()
                        print("🔥 AppointmentFormView: onCancel()実行完了")
                    }) {
                        Text("キャンセル")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            if let appointment = appointment, let settings = settings {
                if let hospitalIndex = settings.hospitalList.firstIndex(of: appointment.hospital) {
                    selectedHospitalIndex = hospitalIndex
                } else {
                    selectedHospitalIndex = settings.hospitalList.count
                    newHospital = appointment.hospital
                }
            } else if let settings = settings {
                // 新規作成時に確実に有効なインデックスを設定
                selectedHospitalIndex = min(selectedHospitalIndex, settings.hospitalList.count)
            }
        }
    }
}