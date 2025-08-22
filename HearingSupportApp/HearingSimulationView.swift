//
//  HearingSimulationView.swift
//  HearingSupportApp
//
//  難聴児の聞こえ方をシミュレーションするビュー
//

import SwiftUI
import AVFoundation

struct HearingSimulationView: View {
    @StateObject private var audioManager = AudioSimulationManager()
    @State private var selectedRecord: Record?
    @State private var selectedTestResult: TestResult?
    @State private var selectedEar: String = "両耳"
    @State private var isSimulationActive = false
    @State private var showRecordPicker = false
    @State private var showPermissionAlert = false
    
    let records: [Record]
    let earOptions = ["右耳のみ", "左耳のみ", "両耳"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 1.0, green: 0.97, blue: 0.92)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // ヘッダー
                    VStack(spacing: 8) {
                        Text("きこえ方シミュレーション")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.black)
                        
                        Text("お子さまの聞こえ方を体験できます")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top)
                    
                    // 検査記録選択
                    VStack(alignment: .leading, spacing: 12) {
                        Text("シミュレーションに使用する検査記録")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Button(action: {
                            showRecordPicker = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let record = selectedRecord {
                                        Text(record.title)
                                            .font(.body)
                                            .foregroundColor(.black)
                                        
                                        Text("\(record.hospital) - \(formatDate(record.date))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    } else {
                                        Text("検査記録を選択してください")
                                            .font(.body)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                    }
                    
                    // 耳の選択
                    if selectedRecord != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("対象の耳")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Picker("耳の選択", selection: $selectedEar) {
                                ForEach(earOptions, id: \.self) { ear in
                                    Text(ear).tag(ear)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: selectedEar) { _, newValue in
                                updateTestResultSelection()
                            }
                        }
                    }
                    
                    // シミュレーション設定情報
                    if let testResult = selectedTestResult {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("シミュレーション設定")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("条件: \(testResult.condition)")
                                    .font(.body)
                                    .foregroundColor(.black)
                                
                                if let thresholds = getThresholds(from: testResult) {
                                    HStack {
                                        Text("聴力閾値:")
                                            .font(.body)
                                            .foregroundColor(.black)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(0..<testResult.freqs.count, id: \.self) { index in
                                                    VStack(spacing: 4) {
                                                        Text(testResult.freqs[index])
                                                            .font(.caption2)
                                                            .foregroundColor(.gray)
                                                        
                                                        Text(thresholds[index].map { "\($0)dB" } ?? "-")
                                                            .font(.caption)
                                                            .foregroundColor(.black)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                    
                    // コントロールボタン
                    VStack(spacing: 16) {
                        // リアルタイムシミュレーション
                        Button(action: {
                            if isSimulationActive {
                                stopSimulation()
                            } else {
                                startSimulation()
                            }
                        }) {
                            HStack {
                                Image(systemName: isSimulationActive ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                
                                Text(isSimulationActive ? "シミュレーション停止" : "リアルタイムシミュレーション開始")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isSimulationActive ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(selectedTestResult == nil || !audioManager.permissionGranted)
                        
                        // 録音・再生ボタン
                        HStack(spacing: 16) {
                            Button(action: {
                                if audioManager.isRecording {
                                    // 録音は自動的に5秒で停止される
                                } else {
                                    audioManager.startRecording()
                                }
                            }) {
                                HStack {
                                    Image(systemName: audioManager.isRecording ? "stop.circle" : "mic.circle")
                                    Text(audioManager.isRecording ? "録音中..." : "5秒録音")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(audioManager.isRecording ? Color.red : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .disabled(!audioManager.permissionGranted)
                            
                            Button(action: {
                                audioManager.playRecordedAudioWithSimulation()
                            }) {
                                HStack {
                                    Image(systemName: "play.circle")
                                    Text("シミュレーション再生")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(audioManager.recordedAudioFile != nil ? Color.orange : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .disabled(audioManager.recordedAudioFile == nil || selectedTestResult == nil)
                        }
                    }
                    .padding(.bottom, 30)
                }
                .padding(.horizontal)
            }
            .navigationTitle("きこえ方シミュレーション")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await audioManager.requestMicrophonePermission()
                    if !audioManager.permissionGranted {
                        showPermissionAlert = true
                    }
                }
            }
            .onDisappear {
                // ビューが消える時に音声処理を停止
                if isSimulationActive {
                    stopSimulation()
                }
                if audioManager.isRecording {
                    // 録音中の場合は停止（ただし、自動停止に任せる）
                    print("録音は自動停止されます")
                }
            }
            .sheet(isPresented: $showRecordPicker) {
                RecordPickerView(records: records, selectedRecord: $selectedRecord)
                    .onDisappear {
                        updateTestResultSelection()
                    }
            }
            .alert("マイクロフォンのアクセス許可が必要です", isPresented: $showPermissionAlert) {
                Button("設定を開く") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("音声の録音とシミュレーションを行うため、マイクロフォンへのアクセスを許可してください。")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/M/d"
        return formatter.string(from: date)
    }
    
    private func updateTestResultSelection() {
        guard let record = selectedRecord else {
            selectedTestResult = nil
            return
        }
        
        // 選択された耳に対応するテスト結果を見つける
        selectedTestResult = record.results.first { result in
            result.ear == selectedEar
        }
        
        // 設定が変わったらシミュレーションを停止
        if isSimulationActive {
            stopSimulation()
        }
        
        // 新しい設定でシミュレーションを構成
        if let testResult = selectedTestResult {
            audioManager.configureSimulation(testResult: testResult, ear: selectedEar)
        }
    }
    
    private func getThresholds(from testResult: TestResult) -> [Int?]? {
        switch selectedEar {
        case "右耳のみ":
            return testResult.thresholdsRight
        case "左耳のみ":
            return testResult.thresholdsLeft
        case "両耳":
            return testResult.thresholdsBoth
        default:
            return nil
        }
    }
    
    private func startSimulation() {
        guard let testResult = selectedTestResult else { return }
        
        audioManager.configureSimulation(testResult: testResult, ear: selectedEar)
        audioManager.startRealTimeProcessing()
        isSimulationActive = true
    }
    
    private func stopSimulation() {
        audioManager.stopRealTimeProcessing()
        isSimulationActive = false
    }
}

// 検査記録選択用のビュー
struct RecordPickerView: View {
    let records: [Record]
    @Binding var selectedRecord: Record?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(records) { record in
                    Button(action: {
                        selectedRecord = record
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.title)
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Text("\(record.hospital) - \(formatDate(record.date))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if !record.results.isEmpty {
                                Text("検査結果: \(record.results.count)件")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("検査記録を選択")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("キャンセル") {
                dismiss()
            })
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/M/d"
        return formatter.string(from: date)
    }
}