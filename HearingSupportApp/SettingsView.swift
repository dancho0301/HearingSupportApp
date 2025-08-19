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
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("アプリ名")
                        Spacer()
                        Text("おみみ手帳")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("データ管理")) {
                    NavigationLink("病院リスト管理") {
                        HospitalListView(settings: settings)
                    }
                    
                    NavigationLink("検査種類管理") {
                        TestTypeListView(settings: settings)
                    }
                }
                
                Section(header: Text("サポート")) {
                    Link("お問い合わせ", destination: URL(string: "mailto:samuraimania.d@gmail.com")!)
                    
                    NavigationLink("プライバシーポリシー") {
                        PrivacyPolicyView()
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HospitalListView: View {
    @Environment(\.modelContext) private var modelContext
    let settings: AppSettings
    @State private var newHospital = ""
    @State private var showingAddAlert = false
    
    var body: some View {
        List {
            ForEach(settings.hospitalList, id: \.self) { hospital in
                Text(hospital)
            }
            .onDelete(perform: deleteHospital)
        }
        .navigationTitle("病院リスト")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("追加") {
                    showingAddAlert = true
                }
            }
        }
        .alert("新しい病院を追加", isPresented: $showingAddAlert) {
            TextField("病院名", text: $newHospital)
            Button("追加") {
                if !newHospital.isEmpty {
                    settings.hospitalList.append(newHospital)
                    try? modelContext.save()
                    newHospital = ""
                }
            }
            Button("キャンセル", role: .cancel) {
                newHospital = ""
            }
        }
    }
    
    private func deleteHospital(at offsets: IndexSet) {
        settings.hospitalList.remove(atOffsets: offsets)
        try? modelContext.save()
    }
}

struct TestTypeListView: View {
    @Environment(\.modelContext) private var modelContext
    let settings: AppSettings
    @State private var newTestType = ""
    @State private var showingAddAlert = false
    
    var body: some View {
        List {
            ForEach(settings.testTypes, id: \.self) { testType in
                Text(testType)
            }
            .onDelete(perform: deleteTestType)
        }
        .navigationTitle("検査種類リスト")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("追加") {
                    showingAddAlert = true
                }
            }
        }
        .alert("新しい検査種類を追加", isPresented: $showingAddAlert) {
            TextField("検査種類名", text: $newTestType)
            Button("追加") {
                if !newTestType.isEmpty {
                    settings.testTypes.append(newTestType)
                    try? modelContext.save()
                    newTestType = ""
                }
            }
            Button("キャンセル", role: .cancel) {
                newTestType = ""
            }
        }
    }
    
    private func deleteTestType(at offsets: IndexSet) {
        settings.testTypes.remove(atOffsets: offsets)
        try? modelContext.save()
    }
}