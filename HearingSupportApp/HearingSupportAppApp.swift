//
//  HearingSupportAppApp.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/05/27.
//

import SwiftUI
import SwiftData

@main
struct HearingSupportAppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Child.self,
            Record.self,
            TestResult.self,
            AppSettings.self,
            Appointment.self,
        ])
        
        // データベースを強制的にリセットするための設定
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 既存ストアがスキーマと非互換で読み込めない場合、
            // 破損ストアを削除してから再生成を試みる（アプリが起動不能になるのを防ぐ）。
            print("ModelContainer作成エラー: \(error)")
            if let recovered = Self.recreateContainerByResettingStore(schema: schema, configuration: modelConfiguration) {
                return recovered
            }
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    /// 既定のストアファイルを削除してから ModelContainer を作り直す。
    /// マイグレーション不能でアプリが起動できなくなる最悪ケースの回避策。
    private static func recreateContainerByResettingStore(
        schema: Schema,
        configuration: ModelConfiguration
    ) -> ModelContainer? {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        // SwiftData の既定ストア名は default.store（付随ファイル -shm / -wal を含む）
        let storeURLs = ["default.store", "default.store-shm", "default.store-wal"].map {
            appSupport.appendingPathComponent($0)
        }
        for url in storeURLs where fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
        return try? ModelContainer(for: schema, configurations: [configuration])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // アプリはクリーム/白の背景に黒文字のライトテーマ前提でデザインされているため、
                // ダークモードでも文字が読めるよう常にライトテーマで表示する
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
