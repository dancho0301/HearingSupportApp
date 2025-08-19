# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HearingSupportApp is a SwiftUI iOS application designed as a hearing test record management app ("おみみ手帳" - Ear Notebook). The app allows users to track hearing test results over time with visualization capabilities.

## Architecture

### Core Components

- **ContentView.swift**: Main screen displaying record cards and navigation to form view
- **Models.swift**: Data models including `Record`, `TestResult`, and `TestResultInput` structures
- **RecordFormView.swift**: Form interface for creating/editing hearing test records
- **HearingGraph.swift**: Custom SwiftUI view for visualizing hearing test results as line graphs
- **RecordCard.swift**: Reusable card component for displaying record summaries
- **TestResultInputView.swift**: Input interface for hearing test threshold values

### Data Models

The app uses three main data structures:
- `Record`: Main record containing date, hospital, title, detail, and test results
- `TestResult`: Individual test results with ear-specific threshold data
- `TestResultInput`: Input helper for collecting test data before conversion to TestResult

### SwiftData Integration

The app is configured to use SwiftData for persistence:
- ModelContainer setup in `HearingSupportAppApp.swift` 
- Schema includes `Record`, `TestResult`, and `AppSettings` models
- All data is stored locally using SwiftData with proper array serialization via Data encoding

## Development Commands

### Building the App
```bash
# Open in Xcode
open HearingSupportApp.xcodeproj

# Build from command line (requires Xcode)
xcodebuild -project HearingSupportApp.xcodeproj -scheme HearingSupportApp -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### Running Tests
```bash
# Run tests from command line
xcodebuild test -project HearingSupportApp.xcodeproj -scheme HearingSupportApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

## データ保護ポリシー（重要）

**このアプリの最重要方針：**
- **開発者・運営者は一切のデータを保存しません**
- **すべてのデータはユーザーのデバイス内のみに保存されます**
- **外部サーバーへの送信は技術的に不可能です**
- **iCloudが唯一のバックアップ先となります**
- **データ共有機能は意図的に実装していません**

### 開発時の注意事項
- 外部API呼び出し機能を追加してはいけません
- データエクスポート機能を実装してはいけません
- SNS連携機能を追加してはいけません
- アナリティクス系のライブラリを導入してはいけません
- ユーザーデータを扱う外部サービスとの連携を行ってはいけません

## Key Features

1. **Hearing Test Records**: Create and edit records with hospital, test type, and detailed results
2. **Multi-frequency Testing**: Support for 7 frequency bands (125Hz to 8kHz)
3. **Ear-specific Data**: Separate tracking for right ear, left ear, or both ears
4. **Condition Tracking**: Records for different conditions (naked ear, hearing aid, cochlear implant)
5. **Visualization**: Line graphs showing hearing threshold curves
6. **Hospital Management**: Dynamic hospital list that grows as users add new facilities
7. **Settings Management**: Built-in privacy policy and contact information
8. **Privacy-First Design**: Zero external data transmission, local-only storage

## Japanese Localization

The app is designed for Japanese users with Japanese UI text and predefined hospital/test type lists. Key Japanese terms:
- "おみみ手帳" (Ear Notebook) - App title
- Hospital list includes Japanese medical facilities
- Test types include standard audiological tests in Japanese

## UI/UX Patterns

- Uses NavigationStack for iOS 16+ navigation
- Custom cream/beige color scheme (Color(red: 1.0, green: 0.97, blue: 0.92))
- Floating action button for adding new records
- Card-based layout for record display
- Form-based input with steppers and pickers for precise data entry