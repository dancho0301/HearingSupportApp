//
//  SettingsView.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/08/19.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.createdAt) private var children: [Child]
    let settings: AppSettings
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("アプリについて")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("アプリ名")
                        Spacer()
                        Text("おみみ手帳")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("利用者管理")) {
                    NavigationLink("利用者一覧・編集") {
                        ChildManagementView()
                    }
                }
                
                Section(header: Text("データ管理")) {
                    NavigationLink("病院リスト管理") {
                        HospitalManagementView(settings: settings)
                    }
                    
                    NavigationLink("検査種類管理") {
                        TestTypeManagementView(settings: settings)
                    }
                }
                
                Section(header: Text("サポート")) {
                    Link("お問い合わせ", destination: URL(string: "mailto:samuraimania.d@gmail.com")!)
                    
                    NavigationLink("プライバシーポリシー") {
                        PrivacyPolicyView()
                    }
                }
            }
            .background(Color(red: 1.0, green: 0.97, blue: 0.92))
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct HospitalManagementView: View {
    @Environment(\.modelContext) private var modelContext
    let settings: AppSettings
    @State private var hospitalSettings: [HospitalSetting] = []
    @State private var newHospital = ""
    @State private var showingAddAlert = false
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        List {
            Section(header: Text("病院の表示設定")) {
                ForEach($hospitalSettings) { $setting in
                    HStack {
                        Toggle(setting.name, isOn: $setting.isEnabled)
                            .onChange(of: setting.isEnabled) { _, newValue in
                                // 最低1つは有効にする制約
                                let enabledCount = hospitalSettings.filter { $0.isEnabled }.count
                                if enabledCount == 0 && !newValue {
                                    setting.isEnabled = true
                                    return
                                }
                                saveSettings()
                            }
                    }
                }
                .onDelete(perform: deleteHospital)
                .onMove(perform: moveHospital)
                
                // 新規追加ボタン
                if editMode == .inactive {
                    Button(action: {
                        showingAddAlert = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("新しい病院を追加")
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.92))
        .navigationTitle("病院リスト管理")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(editMode == .active ? "完了" : "編集") {
                    withAnimation {
                        editMode = editMode == .active ? .inactive : .active
                    }
                }
            }
        }
        .alert("新しい病院を追加", isPresented: $showingAddAlert) {
            TextField("病院名", text: $newHospital)
            Button("追加") {
                if !newHospital.isEmpty {
                    // 病院リストに追加
                    settings.hospitalList.append(newHospital)
                    
                    // 設定にも追加（デフォルトで有効）
                    hospitalSettings.append(HospitalSetting(name: newHospital, isEnabled: true))
                    
                    saveSettings()
                    newHospital = ""
                }
            }
            Button("キャンセル", role: .cancel) {
                newHospital = ""
            }
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        hospitalSettings = settings.hospitalSettings
        
        // 既存の病院で設定がないものは有効として追加
        let existingNames = Set(hospitalSettings.map { $0.name })
        let newSettings = settings.hospitalList.filter { !existingNames.contains($0) }
            .map { HospitalSetting(name: $0, isEnabled: true) }
        
        hospitalSettings.append(contentsOf: newSettings)
        
        // 削除された病院は設定からも削除
        hospitalSettings = hospitalSettings.filter { settings.hospitalList.contains($0.name) }
        
        saveSettings()
    }
    
    private func saveSettings() {
        settings.hospitalSettings = hospitalSettings
        try? modelContext.save()
    }
    
    private func deleteHospital(at offsets: IndexSet) {
        // 削除する前に有効な病院が最低1つ残るかチェック
        let indicesToDelete = Set(offsets)
        let remainingSettings = hospitalSettings.enumerated().compactMap { index, setting in
            indicesToDelete.contains(index) ? nil : setting
        }
        
        let remainingEnabledCount = remainingSettings.filter { $0.isEnabled }.count
        if remainingEnabledCount == 0 {
            // 有効な病院がなくなる場合は削除を防ぐ
            return
        }
        
        // 病院リストから削除
        let namesToDelete = offsets.map { hospitalSettings[$0].name }
        settings.hospitalList.removeAll { name in namesToDelete.contains(name) }
        
        // 設定からも削除
        hospitalSettings.remove(atOffsets: offsets)
        
        saveSettings()
    }
    
    private func moveHospital(from source: IndexSet, to destination: Int) {
        // 設定の順序を変更
        hospitalSettings.move(fromOffsets: source, toOffset: destination)
        
        // hospitalListも同じ順序で更新
        settings.hospitalList = hospitalSettings.map { $0.name }
        
        saveSettings()
    }
}

struct TestTypeManagementView: View {
    @Environment(\.modelContext) private var modelContext
    let settings: AppSettings
    @State private var testTypeSettings: [TestTypeSetting] = []
    @State private var newTestType = ""
    @State private var showingAddAlert = false
    @State private var showingResetAlert = false
    @State private var showingLastEnabledAlert = false
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        List {
            Section(header: Text("検査種類の表示設定")) {
                // デフォルト検査種類（削除不可）
                ForEach(testTypeSettings.filter { $0.isDefault }, id: \.id) { setting in
                    HStack {
                        Toggle(setting.name, isOn: Binding(
                            get: { setting.isEnabled },
                            set: { newValue in
                                if let index = testTypeSettings.firstIndex(where: { $0.id == setting.id }) {
                                    // 最低1つは有効にする制約
                                    let enabledCount = testTypeSettings.filter { $0.isEnabled }.count
                                    if enabledCount == 1 && !newValue && testTypeSettings[index].isEnabled {
                                        // 最後の有効な検査種類を無効化しようとしている
                                        showingLastEnabledAlert = true
                                        return
                                    }
                                    testTypeSettings[index].isEnabled = newValue
                                    saveSettings()
                                }
                            }
                        ))

                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                
                // カスタム検査種類（削除可能）
                ForEach(testTypeSettings.filter { !$0.isDefault }, id: \.id) { setting in
                    HStack {
                        Toggle(setting.name, isOn: Binding(
                            get: { setting.isEnabled },
                            set: { newValue in
                                if let index = testTypeSettings.firstIndex(where: { $0.id == setting.id }) {
                                    // 最低1つは有効にする制約
                                    let enabledCount = testTypeSettings.filter { $0.isEnabled }.count
                                    if enabledCount == 1 && !newValue && testTypeSettings[index].isEnabled {
                                        // 最後の有効な検査種類を無効化しようとしている
                                        showingLastEnabledAlert = true
                                        return
                                    }
                                    testTypeSettings[index].isEnabled = newValue
                                    saveSettings()
                                }
                            }
                        ))
                    }
                }
                .onDelete(perform: deleteCustomTestType)
                
                // 新規追加ボタン
                if editMode == .inactive {
                    Button(action: {
                        showingAddAlert = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("新しい検査種類を追加")
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 初期化ボタン
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(.orange)
                            Text("初期設定に戻す")
                                .foregroundColor(.orange)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.92))
        .navigationTitle("検査種類管理")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(editMode == .active ? "完了" : "編集") {
                    withAnimation {
                        editMode = editMode == .active ? .inactive : .active
                    }
                }
            }
        }
        .alert("新しい検査種類を追加", isPresented: $showingAddAlert) {
            TextField("検査種類名", text: $newTestType)
            Button("追加") {
                if !newTestType.isEmpty {
                    // 検査種類リストに追加
                    settings.testTypes.append(newTestType)
                    
                    // 設定にも追加（デフォルトで有効、カスタム検査種類）
                    testTypeSettings.append(TestTypeSetting(name: newTestType, isEnabled: true, isDefault: false))
                    
                    saveSettings()
                    newTestType = ""
                }
            }
            Button("キャンセル", role: .cancel) {
                newTestType = ""
            }
        }
        .alert("検査種類を初期設定に戻す", isPresented: $showingResetAlert) {
            Button("初期化", role: .destructive) {
                resetToDefaultTestTypes()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("検査種類リストが初期設定に戻ります。追加した検査種類は削除されます。この操作は取り消せません。")
        }
        .alert("無効化できません", isPresented: $showingLastEnabledAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("最低1つの検査種類を有効にしておく必要があります。他の検査種類を有効にしてから無効化してください。")
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        testTypeSettings = settings.testTypeSettings
        
        // 既存の検査種類で設定がないものは有効として追加
        let existingNames = Set(testTypeSettings.map { $0.name })
        let newSettings = settings.testTypes.filter { !existingNames.contains($0) }
            .map { TestTypeSetting(name: $0, isEnabled: true, isDefault: AppSettings.defaultTestTypes.contains($0)) }
        
        testTypeSettings.append(contentsOf: newSettings)
        
        // 削除された検査種類は設定からも削除
        testTypeSettings = testTypeSettings.filter { settings.testTypes.contains($0.name) }
        
        saveSettings()
    }
    
    private func saveSettings() {
        settings.testTypeSettings = testTypeSettings
        try? modelContext.save()
    }
    
    private func deleteCustomTestType(at offsets: IndexSet) {
        // カスタム検査種類のみを対象とする
        let customSettings = testTypeSettings.filter { !$0.isDefault }
        let settingsToDelete = offsets.map { customSettings[$0] }
        
        // 削除する前に有効な検査種類が最低1つ残るかチェック
        let remainingEnabledCount = testTypeSettings.filter { setting in
            !settingsToDelete.contains { $0.id == setting.id } && setting.isEnabled
        }.count
        
        if remainingEnabledCount == 0 {
            // 有効な検査種類がなくなる場合は削除を防ぐ
            return
        }
        
        // 検査種類リストから削除
        let namesToDelete = settingsToDelete.map { $0.name }
        settings.testTypes.removeAll { name in namesToDelete.contains(name) }
        
        // 設定からも削除
        testTypeSettings.removeAll { setting in
            settingsToDelete.contains { $0.id == setting.id }
        }
        
        saveSettings()
    }
    
    
    
    private func resetToDefaultTestTypes() {
        // デフォルトの検査種類に戻す
        let defaultTypes = AppSettings.defaultTestTypes
        settings.testTypes = defaultTypes
        
        // 設定もデフォルトに戻す（全て有効、デフォルト検査種類）
        testTypeSettings = defaultTypes.map { TestTypeSetting(name: $0, isEnabled: true, isDefault: true) }
        
        saveSettings()
    }
}

struct ChildManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.createdAt) private var children: [Child]
    @State private var editMode: EditMode = .inactive
    @State private var showingAddChild = false
    @State private var childToDelete: Child? = nil
    @State private var showingDeleteAlert = false
    
    var body: some View {
        List {
            Section(header: Text("登録された利用者")) {
                ForEach(children) { child in
                    NavigationLink(destination: EditChildView(child: child)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(child.name)
                                    .font(.headline)
                                
                                Spacer()
                                
                                if !child.isActive {
                                    Text("非表示")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            
                            
                            if !child.notes.isEmpty {
                                Text(child.notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Text("記録数: \(child.records.count)件")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: requestDeleteChild)
            }
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.92))
        .navigationTitle("利用者管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("追加") {
                    showingAddChild = true
                }
            }
        }
        .sheet(isPresented: $showingAddChild) {
            NavigationView {
                AddChildView()
            }
        }
        .alert("利用者情報を削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                if let child = childToDelete {
                    modelContext.delete(child)
                    try? modelContext.save()
                    childToDelete = nil
                }
            }
            Button("キャンセル", role: .cancel) {
                childToDelete = nil
            }
        } message: {
            if let child = childToDelete {
                Text("「\(child.name)」の情報と関連する全ての記録・予定が削除されます。この操作は取り消せません。")
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }
    
    private func requestDeleteChild(at offsets: IndexSet) {
        // 削除確認のため最初の子供を選択
        if let firstOffset = offsets.first {
            childToDelete = children[firstOffset]
            showingDeleteAlert = true
        }
    }
}

struct EditChildView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let child: Child
    
    @State private var name: String
    @State private var birthDate: Date
    @State private var hasBirthDate: Bool
    @State private var notes: String
    @State private var isActive: Bool
    
    init(child: Child) {
        self.child = child
        self._name = State(initialValue: child.name)
        self._birthDate = State(initialValue: Date())
        self._hasBirthDate = State(initialValue: false)
        self._notes = State(initialValue: child.notes)
        self._isActive = State(initialValue: child.isActive)
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本情報")) {
                TextField("名前", text: $name)
                
                
                Toggle("表示する", isOn: $isActive)
            }
            
            Section(header: Text("メモ")) {
                TextField("メモ", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section(header: Text("統計")) {
                HStack {
                    Text("記録数")
                    Spacer()
                    Text("\(child.records.count)件")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("予定数")
                    Spacer()
                    Text("\(child.appointments.count)件")
                        .foregroundColor(.gray)
                }
            }
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.92))
        .navigationTitle("利用者編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveChild()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private func saveChild() {
        child.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        child.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        child.isActive = isActive
        
        try? modelContext.save()
        dismiss()
    }
}