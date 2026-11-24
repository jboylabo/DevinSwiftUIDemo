# DevinSwiftUIDemo

SwiftUI で作る iOS デモアプリです。現在は `ContentView` に SF Symbols の地球アイコンと `Hello, world!` を表示する最小構成で、今後はシェーダーを使った地球の回転グラフィックを実装する予定です。

## 要件

- macOS
- iOS 27 SDK を含む Xcode
- iOS 27.0 以降を対象とした検証・ビルド環境
- iPhone / iPad

このプロジェクトの `IPHONEOS_DEPLOYMENT_TARGET` は `27.0` です。

## セットアップ

1. リポジトリをクローンします。

   ```sh
   git clone https://github.com/jboylabo/DevinSwiftUIDemo.git
   cd DevinSwiftUIDemo
   ```

2. `DevinSwiftUIDemo.xcodeproj` を Xcode で開きます。

3. スキーム `DevinSwiftUIDemo` と、iOS 27 のシミュレータまたは実機を選択します。

4. `Run`（⌘R）でビルドして実行します。

## コマンドラインでのビルド

Xcode がインストールされた macOS で、プロジェクトのあるディレクトリから実行します。

```sh
xcodebuild -project DevinSwiftUIDemo.xcodeproj -target DevinSwiftUIDemo -destination 'generic/platform=iOS Simulator' build
```

利用可能なシミュレータは `xcrun simctl list devices available` で確認できます。

## プロジェクト構成

- `DevinSwiftUIDemo/DevinSwiftUIDemoApp.swift`: アプリのエントリポイント（`@main`）
- `DevinSwiftUIDemo/ContentView.swift`: メイン画面
- `DevinSwiftUIDemo/Assets.xcassets`: アプリアイコンと Accent Color
- `DevinSwiftUIDemo.xcodeproj`: Xcode プロジェクト

## 今後の実装予定

- SwiftUI のシェーダー機能を使って、地球がくるくる回転するグラフィックを作る
