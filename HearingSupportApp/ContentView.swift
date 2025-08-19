import SwiftUI

struct ContentView: View {
    @State private var records: [Record] = []
    @State private var editingIndex: Int? = nil
    @State private var showForm = false
    @State private var isEditing = false
    @State private var editingRecord: Record? = nil

    // 病院・検査名マスタ
    @State private var hospitalList: [String] = ["千葉こども耳鼻科", "東京医大", "柏総合病院"]
    @State private var testTypes: [String] = ["ABR検査", "OAE検査", "ASSR検査", "ピュアトーン聴力検査", "語音聴力検査", "インピーダンスオージオメトリー", "その他"]

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
                        .padding(.bottom, 10)
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(records.indices, id: \.self) { idx in
                                Button(action: {
                                    editingIndex = idx
                                    editingRecord = records[idx]
                                    isEditing = true
                                    showForm = true
                                }) {
                                    RecordCard(record: records[idx])
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    Spacer()
                }

                // 新規登録ボタン
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
                .padding(.bottom, 25)
            }
            .navigationBarHidden(true)
            // iOS16+推奨の画面遷移
            .navigationDestination(isPresented: $showForm) {
                RecordFormView(
                    record: editingRecord,
                    hospitalList: hospitalList,
                    testTypes: testTypes,
                    isEditing: isEditing,
                    onSave: { newRecord in
                        if isEditing, let idx = editingIndex {
                            records[idx] = newRecord
                        } else {
                            records.insert(newRecord, at: 0)
                        }
                        // 新しい病院が追加された場合はリストにも反映
                        if !hospitalList.contains(newRecord.hospital) {
                            hospitalList.append(newRecord.hospital)
                        }
                        showForm = false
                    },
                    onDelete: {
                        if let idx = editingIndex {
                            records.remove(at: idx)
                        }
                        showForm = false
                    }
                )
            }
        }
    }
}
