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
            // 既存のデータベースに問題がある場合、詳細なエラー情報を出力
            print("ModelContainer作成エラー: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

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
