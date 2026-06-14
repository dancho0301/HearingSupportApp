//
//  HearingSimulationView.swift
//  HearingSupportApp
//
//  難聴児の「聞こえ方」を保護者が疑似体験するための画面。
//  話し声を録音し、聴力検査データをもとに周波数帯ごとに音量をしぼって再生する。
//

import SwiftUI
import UIKit

struct HearingSimulationView: View {
    let child: Child

    @StateObject private var engine = HearingSimulationEngine()
    @State private var selectedSource: SimulationSource?
    @State private var showManualControls = false
    @State private var hasConfigured = false

    private let cream = Color(red: 1.0, green: 0.97, blue: 0.92)
    // アプリはライトテーマ固定のため、ダークモードでも読めるよう固定のグレーを使う
    // （.secondary は適応色でダークモード時に白背景へ埋もれてしまう）
    private let secondaryText = Color(red: 0.42, green: 0.42, blue: 0.42)

    /// シミュレーションに使える聴力データの候補（新しい順）
    private var sources: [SimulationSource] {
        SimulationSource.candidates(from: child)
    }

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    descriptionCard

                    if sources.isEmpty {
                        noDataCard
                    } else {
                        sourcePicker
                        recordSection
                        if engine.hasRecording {
                            playbackSection
                            manualSection
                        }
                    }

                    disclaimerCard
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("聞こえ方シミュレーション")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !hasConfigured {
                selectedSource = sources.first
                configureIfNeeded()
                hasConfigured = true
            }
        }
        .onChange(of: selectedSource?.id) { _ in
            // 聴力データを切り替えても録音は保持する。
            // 再生中なら一旦止めて、新しいデータでEQを構成し直すだけにする。
            engine.stopPlayback()
            configureIfNeeded()
        }
        .alert("マイクへのアクセスが必要です",
               isPresented: Binding(get: { engine.permissionDenied }, set: { _ in })) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("閉じる", role: .cancel) {}
        } message: {
            Text("録音するには「設定」アプリでマイクの使用を許可してください。録音した音声は端末内のみで処理され、外部に送信されることはありません。")
        }
        .alert("エラー",
               isPresented: Binding(get: { engine.errorMessage != nil },
                                    set: { if !$0 { engine.errorMessage = nil } })) {
            Button("OK", role: .cancel) { engine.errorMessage = nil }
        } message: {
            Text(engine.errorMessage ?? "")
        }
    }

    private func configureIfNeeded() {
        guard let source = selectedSource else { return }
        engine.configureBands(thresholds: source.thresholds, freqLabels: source.freqs)
    }

    // MARK: - 説明

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "ear.badge.waveform")
                    .foregroundColor(.orange)
                Text("お子さまの聞こえ方を体験")
                    .font(.headline)
            }
            Text("普段の話しかけ方で話し声を録音すると、登録された聴力検査の結果をもとに、お子さまにどのように聞こえているかを再現して聞くことができます。")
                .font(.subheadline)
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
    }

    private var noDataCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.gray)
            Text("聴力検査データがありません")
                .font(.headline)
            Text("「\(child.name)」さんの聴力検査の記録を登録すると、その結果をもとに聞こえ方を再現できます。")
                .font(.subheadline)
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal)
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - データ選択

    private var sourcePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("再現に使う聴力データ")
                .font(.subheadline).bold()
            Menu {
                ForEach(sources) { source in
                    Button {
                        selectedSource = source
                    } label: {
                        Label(source.menuLabel, systemImage: selectedSource?.id == source.id ? "checkmark" : "")
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedSource?.title ?? "選択してください")
                            .foregroundColor(.black)
                        if let subtitle = selectedSource?.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(secondaryText)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
            }
        }
    }

    // MARK: - 録音

    private var recordSection: some View {
        VStack(spacing: 14) {
            if engine.isRecording {
                Text(timeString(engine.recordingDuration))
                    .font(.system(size: 34, weight: .semibold, design: .monospaced))
                    .foregroundColor(.red)
                Button {
                    engine.stopRecording()
                } label: {
                    Label("録音を停止", systemImage: "stop.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
            } else if engine.hasRecording {
                Text("録音時間: \(timeString(engine.recordingDuration))")
                    .font(.subheadline)
                    .foregroundColor(secondaryText)
                Button {
                    engine.discardRecording()
                } label: {
                    Label("録音し直す", systemImage: "arrow.counterclockwise")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(10)
                }
            } else {
                Button {
                    engine.requestPermissionAndStartRecording()
                } label: {
                    Label("話し声を録音する", systemImage: "mic.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                }
                Text("マイクに向かって、いつものように話しかけてみてください。")
                    .font(.caption)
                    .foregroundColor(secondaryText)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
    }

    // MARK: - 再生

    private var playbackSection: some View {
        VStack(spacing: 12) {
            Text("聞き比べる")
                .font(.subheadline).bold()
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                playbackButton(
                    title: "原音",
                    systemImage: "speaker.wave.2.fill",
                    color: .blue,
                    active: engine.playbackMode == .original
                ) {
                    engine.playOriginal()
                }
                playbackButton(
                    title: "ゆがみ",
                    systemImage: "waveform.path",
                    color: .green,
                    active: engine.playbackMode == .balanced
                ) {
                    engine.playBalanced()
                }
                playbackButton(
                    title: "聞こえ方",
                    systemImage: "ear.fill",
                    color: .orange,
                    active: engine.playbackMode == .simulated
                ) {
                    engine.playSimulated()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                modeLegend(color: .blue, title: "原音", detail: "録音したそのままの音")
                modeLegend(color: .green, title: "ゆがみ", detail: "全体の音量は保ち、周波数バランスの崩れ（音のゆがみ）だけを再現")
                modeLegend(color: .orange, title: "聞こえ方", detail: "実際の音量の小ささも含めて再現")
            }
            .padding(.top, 4)

            if engine.isPlaying {
                Button {
                    engine.stopPlayback()
                } label: {
                    Label("停止", systemImage: "stop.fill")
                        .font(.subheadline)
                        .foregroundColor(secondaryText)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
    }

    private func modeLegend(color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .padding(.top, 4)
            (Text(title).bold() + Text("：\(detail)"))
                .font(.caption2)
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func playbackButton(title: String, systemImage: String, color: Color, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                Text(title)
                    .font(.footnote).bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(active ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(active ? color : color.opacity(0.12))
            .cornerRadius(12)
        }
    }

    // MARK: - 手動調整

    private var manualSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation { showManualControls.toggle() }
            } label: {
                HStack {
                    Text("周波数帯ごとに微調整")
                        .font(.subheadline).bold()
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: showManualControls ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }

            if showManualControls {
                Text("各周波数の音量のしぼり具合を手動で変えて、聞こえ方を試せます。")
                    .font(.caption)
                    .foregroundColor(secondaryText)

                ForEach(engine.bands) { band in
                    VStack(spacing: 2) {
                        HStack {
                            Text(band.label)
                                .font(.caption).bold()
                                .frame(width: 50, alignment: .leading)
                            Spacer()
                            Text("\(Int(band.gainDB)) dB")
                                .font(.caption)
                                .foregroundColor(secondaryText)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(band.gainDB) },
                                set: { engine.updateGain(bandID: band.id, gainDB: Float($0)) }
                            ),
                            in: -96...0
                        )
                        .tint(.orange)
                    }
                }

                Button {
                    engine.resetToAuto()
                } label: {
                    Text("検査データから自動設定に戻す")
                        .font(.caption).bold()
                        .foregroundColor(.orange)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
    }

    // MARK: - 注意書き

    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(.gray)
            Text("この再現はあくまで周波数帯ごとの音量を調整した簡易的なシミュレーションです。実際の聞こえ方は個人差が大きく、医学的な診断・評価の代わりにはなりません。")
                .font(.caption)
                .foregroundColor(secondaryText)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

/// シミュレーションに使う聴力データ1件分
struct SimulationSource: Identifiable {
    let id = UUID()
    let date: Date
    let hospital: String
    let earCondition: String   // 例: "両耳・裸耳"
    let thresholds: [Int?]
    let freqs: [String]

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日"
        return f
    }()

    var title: String { earCondition }
    var subtitle: String { "\(Self.dateFormatter.string(from: date))・\(hospital)" }
    var menuLabel: String { "\(Self.dateFormatter.string(from: date))  \(earCondition)" }

    /// 利用者の記録から、データのある検査結果を新しい順に列挙する。
    /// 裸耳の結果を優先的に先頭へ並べる。
    static func candidates(from child: Child) -> [SimulationSource] {
        let sortedRecords = child.records.sorted { $0.date > $1.date }
        var result: [SimulationSource] = []

        for record in sortedRecords {
            for testResult in record.results {
                guard let data = testResult.graphData,
                      data.contains(where: { $0 != nil }) else { continue }
                result.append(
                    SimulationSource(
                        date: record.date,
                        hospital: record.hospital,
                        earCondition: testResult.displayLabel,
                        thresholds: data,
                        freqs: testResult.freqs
                    )
                )
            }
        }

        // 裸耳を優先（新しい順は維持）
        return result.sorted { lhs, rhs in
            let lNaked = lhs.earCondition.contains("裸耳")
            let rNaked = rhs.earCondition.contains("裸耳")
            if lNaked != rNaked { return lNaked }
            return lhs.date > rhs.date
        }
    }
}
