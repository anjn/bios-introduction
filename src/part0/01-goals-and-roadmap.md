# 本書のゴールと学習ロードマップ

🎯 **この章で学ぶこと**
- BIOS/UEFI とは何か、その役割
- レガシーBIOS と UEFI の違い
- x86_64 アーキテクチャでの位置づけ
- 本書で作る成果物の全体像

---

## BIOS/UEFI とは何か

**BIOS (Basic Input/Output System)** は、コンピュータの電源が入った瞬間から OS が起動するまでの「橋渡し」を担うファームウェアです。

### 主な役割

1. **ハードウェア初期化**
   - CPU、メモリ、チップセットの初期設定
   - PCIe デバイスの列挙と設定

2. **POST (Power-On Self-Test)**
   - ハードウェアの健全性チェック
   - 起動可能なデバイスの検出

3. **ブートローダへの制御移譲**
   - OS のブートローダをメモリにロード
   - 制御を渡す

### レガシーBIOS vs UEFI

| 項目 | レガシーBIOS | UEFI |
|------|-------------|------|
| 登場時期 | 1980年代 | 2000年代 |
| ビット幅 | 16bit | 32/64bit |
| ディスク | MBR (2TB制限) | GPT (大容量対応) |
| 起動方式 | INT 13h | EFI System Partition |
| セキュリティ | なし | Secure Boot 対応 |
| 拡張性 | Option ROM | ドライバモデル |

**UEFI (Unified Extensible Firmware Interface)** は、レガシーBIOS の制約を克服し、モダンなハードウェアに対応するために設計された後継規格です。

## x86_64 アーキテクチャでの位置づけ

```
電源ON
  ↓
[UEFI ファームウェア] ← 本書のテーマ
  ├─ SEC (Security Phase)
  ├─ PEI (Pre-EFI Initialization)
  ├─ DXE (Driver Execution Environment)
  ├─ BDS (Boot Device Selection)
  └─ TSL (Transient System Load)
       ↓
[OS ブートローダ] (GRUB/systemd-boot など)
  ↓
[OS カーネル] (Linux/Windows)
```

UEFI は、ハードウェアと OS の間に立ち、抽象化レイヤを提供します。

## 実機とエミュレータの使い分け

### QEMU + OVMF（本書で主に使用）

**メリット:**
- 安全：実機を壊す心配なし
- 高速：素早く試行錯誤できる
- デバッグ：gdb でステップ実行可能

**デメリット:**
- 実機特有の問題は再現できない
- 性能測定には不向き

### 実機

**メリット:**
- リアルなハードウェア挙動
- 性能評価が可能

**デメリット:**
- ブリック（文鎮化）のリスク
- 試行錯誤に時間がかかる

> **Tip**: 開発初期は QEMU、最終検証で実機を使うのが王道です。

## 本書で作る成果物

本書では、以下を段階的に作成していきます：

### Part 0-I: 基礎理解
- 環境構築
- 「Hello UEFI!」の表示

### Part II: 実装スキル
- カスタムブートローダ
- グラフィカルメニュー
- USB/ストレージからの起動

### Part III-IV: プラットフォーム対応
- 簡易プラットフォーム初期化コード
- Secure Boot 対応イメージ

### Part V-VI: 発展
- デバッグ・最適化ノウハウの習得
- coreboot ビルド
- ARM64 ブート体験

## 学習ロードマップ

```
Week 1-2:  Part 0-I   (環境構築と基礎)
Week 3-4:  Part II    (実装入門)
Week 5-6:  Part III   (プラットフォーム初期化)
Week 7:    Part IV    (セキュリティ)
Week 8:    Part V     (デバッグと最適化)
Week 9:    Part VI    (発展)
```

週に5-10時間の学習を想定していますが、自分のペースで進めてください。

## 次のステップ

次章では、開発環境をセットアップします。Linux/macOS/Windows それぞれの手順を用意しています。

---

📚 **参考資料**
- [UEFI Specification](https://uefi.org/specifications)
- [EDK II Documentation](https://github.com/tianocore/tianocore.github.io/wiki)
