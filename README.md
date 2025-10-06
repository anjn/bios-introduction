# BIOS入門

BIOSの基礎から実践まで学べる入門書です。

## 📖 オンライン版

このドキュメントはGitHub Pagesで公開されています：
- https://anjn.github.io/bios-introduction/

## 🚀 ローカルで閲覧

### 必要なツール

- [mdBook](https://github.com/rust-lang/mdBook)

### インストール

```bash
# cargoを使用
cargo install mdbook
```

### ビルドと閲覧

```bash
# ローカルサーバーで閲覧（http://localhost:3000）
mdbook serve

# または静的ファイルをビルド
mdbook build
```

## 📚 目次

本書は6つのパートで構成されています（全60章以上）：

### Part 0: ウォームアップ：道具と全体像
- 開発環境のセットアップ (Linux/macOS/Windows)
- QEMU + OVMF でのデバッグ環境構築

### Part I: x86_64 ブートの基礎を最短理解
- リセットベクタからCPUモード遷移
- UEFI ブートフローの全体像
- 割り込み、タイマ、SMM 入門

### Part II: 実装に踏み込む：EDK II で手を動かす
- UEFI アプリケーション・ドライバ開発
- GOP、ストレージ、USB ブート
- 実践演習：ブートローダ作成

### Part III: プラットフォーム初期化の勘所
- DRAM/CPU/PCIe 初期化
- ACPI/SMBIOS テーブル生成
- プラットフォーム固有の設定

### Part IV: セキュリティと信頼の確立
- UEFI Secure Boot / TPM / Measured Boot
- Intel Boot Guard / AMD PSP
- SPI フラッシュ保護 / SMM セキュリティ
- CVE 事例研究

### Part V: デバッグ、最適化、実機展開
- 失敗パターン別デバッグ手法
- ブート時間短縮術
- 品質保証と自動テスト
- 実機展開と量産

### Part VI: オルタナティブと発展
- coreboot でのブート実装
- ネットワークブート (PXE/HTTP Boot)
- サーバ/組込み/ARM64 プラットフォーム
- 総合演習：ゼロから Linux 起動

### 付録
- 用語集、クイックリファレンス、参考文献

## 📝 執筆に参加

1. このリポジトリをフォーク
2. `src/` 内のMarkdownファイルを編集
3. プルリクエストを作成

## 📄 ライセンス

MIT License

## 👤 著者

Claude Sonnet 4.5
