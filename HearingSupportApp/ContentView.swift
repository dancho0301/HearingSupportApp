import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Record.date, order: .reverse) private var allRecords: [Record]
    @Query private var appSettings: [AppSettings]
    @Query(sort: \Appointment.appointmentDate, order: .forward) private var allAppointments: [Appointment]
    @Query(sort: \Child.createdAt) private var children: [Child]
    
    @State private var editingRecord: Record? = nil
    @State private var showForm = false
    @State private var isEditing = false
    @State private var showSettings = false
    @State private var showAppointments = false
    @State private var showChildSelection = false
    @State private var showInitialSetup = false
    @State private var selectedChild: Child? = nil
    
    private var settings: AppSettings {
        if let firstSettings = appSettings.first {
            return firstSettings
        } else {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            return newSettings
        }
    }
    
    // 現在選択中のこどもの記録のみを取得
    private var records: [Record] {
        guard let selectedChild = selectedChild else { return [] }
        return allRecords.filter { $0.child?.id == selectedChild.id }
    }
    
    // 現在選択中のこどもの予定のみを取得
    private var appointments: [Appointment] {
        guard let selectedChild = selectedChild else { return [] }
        return allAppointments.filter { $0.child?.id == selectedChild.id }
    }
    
    // アクティブなこどもを取得
    private var activeChildren: [Child] {
        return children.filter { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(red: 1.0, green: 0.97, blue: 0.92)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer().frame(height: 40)
                    
                    // ヘッダー部分（こども名前表示＋切替ボタン）
                    Button(action: {
                        showChildSelection = true
                    }) {
                        HStack {
                            if let selectedChild = selectedChild {
                                Text(selectedChild.name)
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.black)
                            } else {
                                Text("こどもを選択")
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.gray)
                            }
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
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
                        .padding(.bottom, 100)
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
                            let newRecord = Record(date: date, hospital: hospital, title: title, detail: detail, results: results, child: selectedChild)
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
            .sheet(isPresented: $showChildSelection) {
                ChildSelectionView(selectedChild: $selectedChild)
            }
            .fullScreenCover(isPresented: $showInitialSetup) {
                InitialSetupView {
                    showInitialSetup = false
                    // 作成されたこどもを自動選択
                    if let newChild = activeChildren.first {
                        selectedChild = newChild
                    }
                }
            }
            .onAppear {
                // 初回起動時の処理
                setupInitialState()
                
                // アプリ起動時に通知許可を要求
                Task {
                    let granted = await NotificationManager.shared.requestPermission()
                    if granted {
                        print("通知許可が得られました")
                        // 既存の予定のリマインダーを設定
                        await NotificationManager.shared.updateAllAppointmentReminders(appointments: allAppointments)
                    } else {
                        print("通知許可が拒否されました")
                    }
                }
            }
        }
    }
    
    private func setupInitialState() {
        // 既存のレコードでこどもが関連付けられていないものの処理
        migrateOrphanedRecords()
        
        // こどもがいない場合は初期設定画面を表示
        if activeChildren.isEmpty {
            showInitialSetup = true
        } else {
            // 既存のこどもがいる場合、最初のこどもを選択
            if selectedChild == nil {
                selectedChild = activeChildren.first
            }
        }
    }
    
    private func migrateOrphanedRecords() {
        // こどもが関連付けられていないレコードを検索
        let orphanedRecords = allRecords.filter { $0.child == nil }
        let orphanedAppointments = allAppointments.filter { $0.child == nil }
        
        guard !orphanedRecords.isEmpty || !orphanedAppointments.isEmpty else {
            return
        }
        
        // 最初のアクティブなこどもに関連付け、または新しいこどもを作成
        var targetChild: Child
        
        if let firstActiveChild = activeChildren.first {
            targetChild = firstActiveChild
        } else {
            // こどもが存在しない場合はデフォルトのこどもを作成
            targetChild = Child(name: "こども", notes: "既存のデータから自動作成")
            modelContext.insert(targetChild)
        }
        
        // 孤児レコードを関連付け
        for record in orphanedRecords {
            record.child = targetChild
        }
        
        // 孤児予定を関連付け
        for appointment in orphanedAppointments {
            appointment.child = targetChild
        }
        
        // 変更を保存
        try? modelContext.save()
        
        print("移行処理完了: \(orphanedRecords.count)件のレコードと\(orphanedAppointments.count)件の予定を\(targetChild.name)に関連付けました")
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
