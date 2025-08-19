//
//  PrivacyPolicyView.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/08/19.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("プライバシーポリシー")
                    .font(.title)
                    .bold()
                    .padding(.bottom, 10)
                
                Group {
                    policySection(
                        title: "1. アプリの概要",
                        content: "「おみみ手帳」は、聴力検査の記録を管理するためのアプリです。お子様やご家族の聴力検査結果を記録し、経過を把握することを目的としています。"
                    )
                    
                    policySection(
                        title: "2. データ保存の基本方針",
                        content: """
                        【重要】本アプリは以下の厳格なデータ保護方針に基づいて設計されています：
                        
                        ✓ アプリ開発者・運営者は一切のデータを保存しません
                        ✓ すべてのデータはお客様のデバイス内のみに保存されます
                        ✓ 外部サーバーへの送信は一切行いません
                        ✓ iCloudが唯一のバックアップ先となります
                        ✓ データの共有機能は提供いたしません
                        
                        この方針により、お客様の大切な医療情報を最高レベルで保護いたします。
                        """
                    )
                    
                    policySection(
                        title: "3. 収集・保存する情報",
                        content: """
                        本アプリでは以下の情報をお客様のデバイス内にのみ保存します：
                        • 検査日時
                        • 病院名
                        • 検査の種類
                        • 聴力検査結果（各周波数の聴力閾値）
                        • 検査条件（裸耳、補聴器、人工内耳等）
                        • メモ・所見
                        • 病院リスト・検査種類リストの設定情報
                        
                        これらの情報は100%お客様のデバイス内に留まり、開発者が知ることはありません。
                        """
                    )
                    
                    policySection(
                        title: "4. 情報の利用目的",
                        content: """
                        保存された情報は以下の目的でのみ、お客様のデバイス内で利用されます：
                        • 聴力検査記録の表示・管理
                        • 検査結果のグラフ表示
                        • 過去の検査履歴の参照
                        • アプリ設定の保存
                        
                        開発者がこれらの情報にアクセスすることは技術的に不可能です。
                        """
                    )
                    
                    policySection(
                        title: "5. 第三者への提供・データ共有",
                        content: """
                        本アプリでは以下を厳格に禁止しています：
                        • 第三者への個人情報・検査データの提供
                        • 外部サービスとのデータ共有
                        • データエクスポート機能
                        • SNS投稿機能
                        
                        お客様のプライバシーを最優先に、データ共有機能は意図的に実装していません。
                        """
                    )
                }
                
                Group {
                    policySection(
                        title: "6. データの保存と管理",
                        content: """
                        【データ保存場所】
                        • 100%お客様のデバイス内のみに保存
                        • 開発者・運営者のサーバーには一切保存されません
                        • 外部クラウドサービスへの自動送信はありません
                        
                        【バックアップ】
                        • iCloudが唯一のバックアップ先です
                        • iCloud設定はお客様ご自身で管理してください
                        • 他のバックアップ方法は提供していません
                        
                        【データ削除】
                        • アプリを削除すると、すべてのデータが完全に削除されます
                        • 削除されたデータの復旧は不可能です
                        • データ復旧サポートは提供できません
                        """
                    )
                    
                    policySection(
                        title: "7. ソースコード公開による透明性確保",
                        content: """
                        【オープンソース】
                        • 本アプリは完全なオープンソースとしてGitHubで公開されています
                        • どなたでもソースコードを検証できます
                        • データ保護方針が技術的に担保されていることを確認可能です
                        • 第三者による監査・検証を歓迎しています
                        
                        【透明性の証明】
                        • 外部通信機能が存在しないことをコードで確認できます
                        • データがローカルのみに保存されることを検証できます
                        • 依存ライブラリがゼロであることを確認できます
                        """
                    )
                    
                    policySection(
                        title: "8. セキュリティ",
                        content: """
                        【技術的セキュリティ】
                        • データはデバイス内のセキュアな領域に保存されます
                        • 外部通信は一切行わないため、通信傍受のリスクがありません
                        • 開発者がデータにアクセスする手段は存在しません
                        
                        【推奨セキュリティ対策】
                        • デバイスのパスコード・Face ID・Touch IDの設定
                        • 定期的なiCloudバックアップの確認
                        • 信頼できないWi-Fiでの使用時の注意
                        """
                    )
                    
                    policySection(
                        title: "9. 免責事項",
                        content: """
                        • 本アプリは医療診断を目的としたものではありません
                        • 医療に関する判断は必ず医師にご相談ください
                        • アプリの使用によって生じた損害について、開発者は責任を負いません
                        • データの紛失に備え、定期的なバックアップを推奨します
                        """
                    )
                    
                    policySection(
                        title: "10. プライバシーポリシーの変更",
                        content: "本プライバシーポリシーは、必要に応じて変更される場合があります。重要な変更がある場合は、アプリ内でお知らせいたします。"
                    )
                    
                    policySection(
                        title: "11. お問い合わせ",
                        content: """
                        本プライバシーポリシーに関するご質問やご意見がございましたら、以下までお問い合わせください。
                        
                        メールアドレス：samuraimania.d@gmail.com
                        """
                    )
                }
                
                Text("最終更新日：2025年8月19日")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .bold()
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}