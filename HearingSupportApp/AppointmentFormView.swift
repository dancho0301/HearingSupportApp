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
    let onSave: (String, Date, Date, String, String) -> Void
    let onDelete: (() -> Void)?
    let onCancel: () -> Void
    
    @State private var selectedHospitalIndex: Int = 0
    @State private var newHospital: String = ""
    @State private var appointmentDate: Date = Date()
    @State private var appointmentTime: Date = Date()
    @State private var purpose: String = "定期検査"
    @State private var notes: String = ""
    @State private var showExitAlert = false
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    
    // 初期値を保持するプロパティ
    private let initialHospitalIndex: Int
    private let initialNewHospital: String
    private let initialAppointmentDate: Date
    private let initialAppointmentTime: Date
    private let initialPurpose: String
    private let initialNotes: String
    
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
    
    init(appointment: Appointment?, onSave: @escaping (String, Date, Date, String, String) -> Void, onDelete: (() -> Void)? = nil, onCancel: @escaping () -> Void) {
        self.appointment = appointment
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        
        if let appointment = appointment {
            let dateValue = appointment.appointmentDate
            let timeValue = appointment.appointmentTime
            let purposeValue = appointment.purpose
            let notesValue = appointment.notes
            
            _appointmentDate = State(initialValue: dateValue)
            _appointmentTime = State(initialValue: timeValue)
            _purpose = State(initialValue: purposeValue)
            _notes = State(initialValue: notesValue)
            
            self.initialAppointmentDate = dateValue
            self.initialAppointmentTime = timeValue
            self.initialPurpose = purposeValue
            self.initialNotes = notesValue
            self.initialHospitalIndex = 0
            self.initialNewHospital = ""
        } else {
            let dateValue = Date()
            let timeValue = Date()
            let purposeValue = "定期検査"
            let notesValue = ""
            
            _appointmentDate = State(initialValue: dateValue)
            _appointmentTime = State(initialValue: timeValue)
            _purpose = State(initialValue: purposeValue)
            _notes = State(initialValue: notesValue)
            
            self.initialAppointmentDate = dateValue
            self.initialAppointmentTime = timeValue
            self.initialPurpose = purposeValue
            self.initialNotes = notesValue
            self.initialHospitalIndex = 0
            self.initialNewHospital = ""
        }
    }
    
    // 変更があったかどうかをチェックする関数
    private var hasChanges: Bool {
        return selectedHospitalIndex != initialHospitalIndex ||
               newHospital != initialNewHospital ||
               appointmentDate != initialAppointmentDate ||
               appointmentTime != initialAppointmentTime ||
               purpose != initialPurpose ||
               notes != initialNotes
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
                        ForEach(purposeOptions, id: \.self) { purposeOption in
                            Text(purposeOption).tag(purposeOption)
                        }
                    }
                    
                    TextField("メモ・備考", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
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
                        
                        // バリデーション
                        if hospitalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            validationMessage = "病院名を入力してください"
                            showValidationAlert = true
                            return
                        }
                        
                        if purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            validationMessage = "予約目的を入力してください"
                            showValidationAlert = true
                            return
                        }
                        
                        onSave(hospitalName, appointmentDate, appointmentTime, purpose, notes)
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
            .alert("変更を破棄", isPresented: $showExitAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("破棄", role: .destructive) {
                    onCancel()
                }
            } message: {
                Text("変更された内容が保存されていません。変更を破棄して戻りますか？")
            }
            .alert("入力エラー", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
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