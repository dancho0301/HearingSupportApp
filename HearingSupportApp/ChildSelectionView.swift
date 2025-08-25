//
//  ChildSelectionView.swift
//  HearingSupportApp
//
//  こども切替画面
//

import SwiftUI
import SwiftData

struct ChildSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Child.createdAt) private var children: [Child]
    
    @Binding var selectedChild: Child?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(children.filter { $0.isActive }) { child in
                    ChildSelectionRow(
                        child: child,
                        isSelected: selectedChild?.id == child.id
                    ) {
                        selectedChild = child
                        dismiss()
                    }
                }
            }
            .navigationTitle("こどもを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("追加", destination: AddChildView())
                }
            }
        }
    }
}

struct ChildSelectionRow: View {
    let child: Child
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(child.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let birthDate = child.dateOfBirth {
                        Text("生年月日: \(birthDate, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !child.notes.isEmpty {
                        Text(child.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text("記録数: \(child.records.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }
}

struct AddChildView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var childName = ""
    @State private var birthDate = Date()
    @State private var hasBirthDate = false
    @State private var notes = ""
    
    var body: some View {
        Form {
            Section(header: Text("基本情報")) {
                TextField("お子さんの名前", text: $childName)
                
                Toggle("生年月日を設定する", isOn: $hasBirthDate)
                
                if hasBirthDate {
                    DatePicker(
                        "生年月日",
                        selection: $birthDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                }
            }
            
            Section(header: Text("メモ")) {
                TextField("メモ（任意）", text: $notes, axis: .vertical)
                    .lineLimit(3...5)
            }
        }
        .navigationTitle("こどもを追加")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveChild()
                }
                .disabled(childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private func saveChild() {
        let name = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        let child = Child(
            name: name,
            dateOfBirth: hasBirthDate ? birthDate : nil,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        modelContext.insert(child)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("こども保存エラー: \(error)")
        }
    }
}

#Preview {
    ChildSelectionView(selectedChild: .constant(nil))
}