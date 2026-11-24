# DevinSwiftUIDemo

SwiftUI と Metal シェーダー（`ShaderLibrary` / `colorEffect` + `TimelineView`）を使って、宇宙空間で地球がくるくる回転する 3D グラフィックを描画する iOS デモアプリです。

## 主な機能

- **Metal プロシージャル地球シェーダー（`EarthShader.metal`）**:
  - 球体との交差・法線計算による立体表現と、地軸の傾き（約 23.4°）を考慮した自転アニメーション
  - 3D FBM ノイズによる海・大陸・砂漠・森林・山脈・極冠・雲レイヤーのプロシージャル生成
  - 太陽光による陰影・海洋のスペキュラ反射・昼夜境界（ターミネーター）の夕焼け表現・夜側の都市の明かり
  - 大気のフレネル発光・外周ハロー・星空背景
- **インタラクティブ操作（`EarthView.swift`）**:
  - ドラッグ操作による手動回転・チルト調整
  - 再生 / 一時停止、回転速度切替（`0.5x` / `1x` / `2x`）、リセットボタン

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
- `DevinSwiftUIDemo/ContentView.swift`: ルート画面（`EarthView` を表示）
- `DevinSwiftUIDemo/EarthView.swift`: `TimelineView` とドラッグ操作・コントロールを備えた地球ビュー
- `DevinSwiftUIDemo/EarthShader.metal`: SwiftUI `colorEffect` 向け Metal シェーダー（`earthShader`）
- `DevinSwiftUIDemo/Assets.xcassets`: アプリアイコンと Accent Color
- `DevinSwiftUIDemo.xcodeproj`: Xcode プロジェクト
