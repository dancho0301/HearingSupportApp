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
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        List {
            Section(header: Text("検査種類の表示設定")) {
                ForEach($testTypeSettings) { $setting in
                    HStack {
                        Toggle(setting.name, isOn: $setting.isEnabled)
                            .onChange(of: setting.isEnabled) { _, newValue in
                                // 最低1つは有効にする制約
                                let enabledCount = testTypeSettings.filter { $0.isEnabled }.count
                                if enabledCount == 0 && !newValue {
                                    setting.isEnabled = true
                                    return
                                }
                                saveSettings()
                            }
                    }
                }
                .onDelete(perform: deleteTestType)
                .onMove(perform: moveTestType)
                
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
                    
                    // 設定にも追加（デフォルトで有効）
                    testTypeSettings.append(TestTypeSetting(name: newTestType, isEnabled: true))
                    
                    saveSettings()
                    newTestType = ""
                }
            }
            Button("キャンセル", role: .cancel) {
                newTestType = ""
            }
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
            .map { TestTypeSetting(name: $0, isEnabled: true) }
        
        testTypeSettings.append(contentsOf: newSettings)
        
        // 削除された検査種類は設定からも削除
        testTypeSettings = testTypeSettings.filter { settings.testTypes.contains($0.name) }
        
        saveSettings()
    }
    
    private func saveSettings() {
        settings.testTypeSettings = testTypeSettings
        try? modelContext.save()
    }
    
    private func deleteTestType(at offsets: IndexSet) {
        // 削除する前に有効な検査種類が最低1つ残るかチェック
        let indicesToDelete = Set(offsets)
        let remainingSettings = testTypeSettings.enumerated().compactMap { index, setting in
            indicesToDelete.contains(index) ? nil : setting
        }
        
        let remainingEnabledCount = remainingSettings.filter { $0.isEnabled }.count
        if remainingEnabledCount == 0 {
            // 有効な検査種類がなくなる場合は削除を防ぐ
            return
        }
        
        // 検査種類リストから削除
        let namesToDelete = offsets.map { testTypeSettings[$0].name }
        settings.testTypes.removeAll { name in namesToDelete.contains(name) }
        
        // 設定からも削除
        testTypeSettings.remove(atOffsets: offsets)
        
        saveSettings()
    }
    
    private func moveTestType(from source: IndexSet, to destination: Int) {
        // 設定の順序を変更
        testTypeSettings.move(fromOffsets: source, toOffset: destination)
        
        // testTypesリストも同じ順序で更新
        settings.testTypes = testTypeSettings.map { $0.name }
        
        saveSettings()
    }
}