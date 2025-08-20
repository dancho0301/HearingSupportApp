import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Record.date, order: .reverse) private var records: [Record]
    @Query private var appSettings: [AppSettings]
    @Query(sort: \Appointment.appointmentDate, order: .forward) private var appointments: [Appointment]
    
    @State private var editingRecord: Record? = nil
    @State private var showForm = false
    @State private var isEditing = false
    @State private var showSettings = false
    @State private var showAppointments = false
    
    private var settings: AppSettings {
        if let firstSettings = appSettings.first {
            return firstSettings
        } else {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            return newSettings
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(red: 1.0, green: 0.97, blue: 0.92)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer().frame(height: 40)
                    Text("おみみ手帳")
                        .font(.title)
                        .bold()
                        .foregroundColor(.black)
                        .padding(.bottom, 10)
                    ScrollView {
                        VStack(spacing: 16) {
                            // 次回の通院予定表示
                            if let nextAppointment = nextUpcomingAppointment {
                                UpcomingAppointmentCard(appointment: nextAppointment) {
                                    showAppointments = true
                                }
                            }
                            
                            ForEach(records) { record in
                                Button(action: {
                                    editingRecord = record
                                    isEditing = true
                                    showForm = true
                                }) {
                                    RecordCard(record: record)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    Spacer()
                }

                HStack {
                    // 設定ボタン（左下）
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    
                    Spacer()
                    
                    // 新規登録ボタン（中央下）
                    Button(action: {
                        editingRecord = nil
                        isEditing = false
                        showForm = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.orange)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    
                    Spacer()
                    
                    // 通院予定ボタン（右下）
                    Button(action: {
                        showAppointments = true
                    }) {
                        Image(systemName: "calendar")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 25)
            }
            .navigationBarHidden(true)
            // iOS16+推奨の画面遷移
            .navigationDestination(isPresented: $showForm) {
                RecordFormView(
                    record: editingRecord,
                    settings: settings,
                    isEditing: isEditing,
                    onSave: { hospital, title, date, detail, results in
                        if isEditing, let editingRecord = editingRecord {
                            editingRecord.hospital = hospital
                            editingRecord.title = title
                            editingRecord.date = date
                            editingRecord.detail = detail
                            editingRecord.results = results
                        } else {
                            let newRecord = Record(date: date, hospital: hospital, title: title, detail: detail, results: results)
                            modelContext.insert(newRecord)
                        }
                        
                        // 新しい病院が追加された場合はリストにも反映
                        if !settings.hospitalList.contains(hospital) {
                            settings.hospitalList.append(hospital)
                        }
                        
                        try? modelContext.save()
                        showForm = false
                    },
                    onDelete: {
                        if let editingRecord = editingRecord {
                            modelContext.delete(editingRecord)
                            try? modelContext.save()
                        }
                        showForm = false
                    }
                )
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView(settings: settings)
            }
            .navigationDestination(isPresented: $showAppointments) {
                AppointmentListView()
            }
            .onAppear {
                // アプリ起動時に通知許可を要求
                Task {
                    let granted = await NotificationManager.shared.requestPermission()
                    if granted {
                        print("通知許可が得られました")
                        // 既存の予定のリマインダーを設定
                        await NotificationManager.shared.updateAllAppointmentReminders(appointments: appointments)
                    } else {
                        print("通知許可が拒否されました")
                    }
                }
            }
        }
    }
    
    private var nextUpcomingAppointment: Appointment? {
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        
        // シンプルな日付比較で最適化
        return appointments
            .filter { !$0.isCompleted && $0.appointmentDate >= today }
            .first
    }
}

struct UpcomingAppointmentCard: View {
    let appointment: Appointment
    let onTap: () -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E) HH:mm"
        return formatter
    }()
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.blue)
                    Text("次回の通院予定")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.blue)
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateFormatter.string(from: appointment.fullAppointmentDate))
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text(appointment.hospital)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(appointment.purpose)
                            .font(.body)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
