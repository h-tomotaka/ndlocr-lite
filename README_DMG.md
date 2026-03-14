# NDLOCR-Lite macOS DMG 配布ガイド

## ユーザー向け：インストール手順

### 1. DMG ファイルのダウンロード

[Releases ページ](../../releases) から `NDLOCR-Lite.dmg` をダウンロードしてください。

### 2. アプリのインストール

1. ダウンロードした `NDLOCR-Lite.dmg` をダブルクリックして開きます。
2. 開いたウィンドウの中で `NDLOCR-Lite.app` を **Applications** フォルダにドラッグ＆ドロップします。
3. DMG ウィンドウを閉じ、Finder からマウントを解除します。

### 3. 初回起動時の注意事項

macOS のセキュリティ機能（Gatekeeper）により、初回起動時に警告が表示されることがあります。

**対処方法：**

1. Finder で `アプリケーション` フォルダを開きます。
2. `NDLOCR-Lite.app` を右クリック（または Control+クリック）します。
3. コンテキストメニューから **「開く」** を選択します。
4. 「開発元を確認できません」というダイアログが表示されたら、**「開く」** をクリックします。

> **注意：** 初回起動には 1 分程度時間がかかる場合があります。しばらくお待ちください。

詳細な手順については、以下のページも参考にしてください：  
https://zenn.dev/nakamura196/articles/c62a465537ff20

---

## 開発者向け：ビルド手順

### 前提条件

- macOS（Apple Silicon または Intel）
- Python 3.10 以上
- Flutter SDK 3.27.4

### 1. 依存パッケージのインストール

```bash
# Homebrew で create-dmg をインストール
brew install create-dmg

# Python ビルド依存パッケージをインストール
pip install -r ndlocr-lite-gui/requirements-build.txt
```

### 2. ビルドスクリプトの実行

```bash
# リポジトリルートで実行
bash build_dmg.sh
```

実行が完了すると、リポジトリルートに `NDLOCR-Lite.dmg` が生成されます。

### 3. コード署名付きビルド（オプション）

Apple Developer Account をお持ちの場合は、`--sign` オプションで署名を付与できます：

```bash
bash build_dmg.sh --sign "Developer ID Application: Your Name (XXXXXXXXXX)"
```

### ビルドの仕組み

```
build_dmg.sh
 ├── 1. src/ を ndlocr-lite-gui/src/ にコピー
 ├── 2. flet build macos で .app バンドルを生成
 ├── 3. icon.png を AppIcon.icns に変換して設定
 ├── 4. コード署名（--sign オプション指定時）
 └── 5. create-dmg で NDLOCR-Lite.dmg を生成
```

---

## GitHub Actions による自動ビルド

`.github/workflows/build-macos-dmg.yml` に定義された CI/CD ワークフローにより、以下のタイミングで自動的に DMG がビルドされます：

| トリガー | 動作 |
|---------|------|
| `main` ブランチへの push | DMG をアーティファクトとして保存（30 日間） |
| Pull Request（main 向け） | DMG をアーティファクトとして保存（30 日間） |
| Release 作成時 | DMG をリリースページにアップロード |
| 手動実行（workflow_dispatch） | DMG をアーティファクトとして保存（30 日間） |

### アーティファクトのダウンロード

GitHub Actions のワークフロー実行ページから `NDLOCR-Lite-dmg` アーティファクトをダウンロードできます。

---

## トラブルシューティング

### ビルドエラー：`flet` が見つからない

```bash
pip install "flet[all]==0.27.6"
```

### ビルドエラー：`create-dmg` が見つからない

```bash
brew install create-dmg
```

### `.app` が正常に起動しない

ビルドディレクトリをクリーンアップして再試行してください：

```bash
rm -rf macos/ ndlocr-lite-gui/src/
bash build_dmg.sh
```
