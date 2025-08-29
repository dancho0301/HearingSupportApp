//
//  InitialSetupView.swift
//  HearingSupportApp
//
//  初回起動時の利用者名前入力画面
//

import SwiftUI
import SwiftData

struct InitialSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var childName = ""
    @State private var birthDate = Date()
    @State private var hasBirthDate = false
    @State private var notes = ""
    
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("おみみ手帳へようこそ")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("利用者の聴力検査記録を管理しましょう")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("利用者の名前")
                            .font(.headline)
                        TextField("名前を入力してください", text: $childName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("メモ（任意）")
                            .font(.headline)
                        TextField("メモがあれば入力してください", text: $notes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...5)
                    }
                }
                .padding()
                
                Spacer()
                
                Button(action: createChild) {
                    Text("はじめる")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Spacer()
            }
            .navigationTitle("初期設定")
            .navigationBarHidden(true)
        }
    }
    
    private func createChild() {
        let name = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        do {
            let child = try Child(
                name: name,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            modelContext.insert(child)
            try modelContext.save()
            onComplete()
        } catch {
            print("利用者作成エラー: \(error.localizedDescription)")
        }
    }
}

#Preview {
    InitialSetupView {
        print("Setup completed")
    }
}