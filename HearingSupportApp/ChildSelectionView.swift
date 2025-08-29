//
//  ChildSelectionView.swift
//  HearingSupportApp
//
//  利用者切替画面
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
            .navigationTitle("利用者を選択")
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
                TextField("利用者の名前", text: $childName)
                
            }
            
            Section(header: Text("メモ")) {
                TextField("メモ（任意）", text: $notes, axis: .vertical)
                    .lineLimit(3...5)
            }
        }
        .navigationTitle("利用者を追加")
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
        
        do {
            let child = try Child(
                name: name,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            modelContext.insert(child)
            try modelContext.save()
            dismiss()
        } catch {
            print("利用者作成エラー: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ChildSelectionView(selectedChild: .constant(nil))
}