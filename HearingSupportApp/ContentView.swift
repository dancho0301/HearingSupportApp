import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Record.date, order: .reverse) private var records: [Record]
    @Query private var appSettings: [AppSettings]
    
    @State private var editingRecord: Record? = nil
    @State private var showForm = false
    @State private var isEditing = false
    @State private var showSettings = false
    
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
                    
                    // 右側のスペース（バランス用）
                    Color.clear
                        .frame(width: 56, height: 56)
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
        }
    }
}
