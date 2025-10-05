# リセットから最初の命令まで

🎯 **この章で学ぶこと**
- x86_64 CPUのリセット時の状態
- リセットベクタとは何か
- 最初の命令が実行されるまでの流れ
- ファームウェアがどこに配置されるか

📚 **前提知識**
- CPUとメモリの基本概念
- アドレス空間の概念

---

## 電源投入の瞬間

コンピュータの電源を入れた瞬間、何が起こるのでしょうか？

```mermaid
sequenceDiagram
    participant Power as 電源
    participant HW as ハードウェア
    participant CPU as CPU
    participant FW as ファームウェア

    Power->>HW: 電源ON
    HW->>HW: 電圧安定化
    HW->>CPU: リセット信号解除
    CPU->>CPU: リセット状態に初期化
    CPU->>FW: 0xFFFFFFF0番地へジャンプ
    FW->>FW: 最初の命令実行
```

この章では、CPUがリセット状態から最初の命令を実行するまでの流れを詳しく見ていきます。

## CPUリセット時の状態

### x86_64 のリセット動作

x86_64 アーキテクチャのCPUは、リセット時に**決まった状態**になります。

**主要なレジスタの初期値:**

| レジスタ | 初期値 | 意味 |
|---------|--------|------|
| **CS** (Code Segment) | 0xF000 | コードセグメント |
| **EIP** (Instruction Pointer) | 0xFFF0 | 命令ポインタ |
| **実効アドレス** | 0xFFFFFFF0 | 実際のアドレス |
| **CR0** | 0x60000010 | 制御レジスタ（リアルモード） |
| **EFLAGS** | 0x00000002 | フラグレジスタ |

### なぜ 0xFFFFFFF0 なのか

**設計上の理由:**

```mermaid
graph TB
    A[4GB アドレス空間] --> B[0xFFFFFFFF<br/>最上位]
    B --> C[0xFFFFFFF0<br/>リセットベクタ<br/>-16 bytes]
    C --> D[ファームウェアROM領域]

    style C fill:#f99,stroke:#333,stroke-width:2px
```

1. **4GB空間の最上位付近**
   - 32bit アドレス空間の上端
   - 0xFFFFFFFF から 16バイト下

2. **ファームウェアROMの位置**
   - メモリマップ上の固定位置
   - 電源ON直後でもアクセス可能

3. **後方互換性**
   - 8086以来の伝統
   - リセット時は常に最上位から

### リセットベクタ (Reset Vector)

**リセットベクタ**とは、CPUがリセット後に最初に実行する命令が配置されるアドレスです。

```
アドレス 0xFFFFFFF0:
  EA 5B E0 00 F0    ; jmp far F000:E05B
```

このアドレスには、通常**ジャンプ命令**が配置されています。

**理由:**
- 16バイトしかスペースがない
- 実際のファームウェアコードは別の場所にある
- ジャンプ命令で本体へ移動

## メモリマップとファームウェアの配置

### リセット直後のメモリマップ

```
0xFFFFFFFF ┌──────────────────┐
           │                  │
0xFFFFFFF0 │  Reset Vector    │ ← CPU が最初にここへ
           │                  │
0xFFF00000 │  BIOS ROM (1MB)  │
           │  ファームウェア    │
0xFEF00000 ├──────────────────┤
           │                  │
           │  (未使用)         │
           │                  │
0x00100000 ├──────────────────┤
           │  Extended Memory │
0x000A0000 ├──────────────────┤
           │  Video Memory    │
0x00000000 └──────────────────┘
```

### ファームウェアROMの配置

**なぜ最上位に配置されるのか:**

```mermaid
graph TB
    A[設計上の制約] --> B[電源ON直後]
    B --> C[メモリコントローラ未初期化]
    C --> D[RAMは使用不可]
    D --> E[ROMのみアクセス可能]
    E --> F[ROMは固定アドレスにマップ]

    style F fill:#9f9,stroke:#333,stroke-width:2px
```

**重要な点:**

1. **RAMは初期化されていない**
   - 電源ON直後、DRAMは未初期化
   - ファームウェアがDRAMを初期化する

2. **ROMは常にアクセス可能**
   - フラッシュメモリ（SPI ROM）
   - チップセットが固定アドレスにマップ

3. **ハードウェアによる自動マッピング**
   - CPUとチップセットの協調動作
   - ソフトウェアの介入不要

## 最初の命令の実行

### リセットベクタの命令

x86_64 では、リセットベクタに**JMP命令**が配置されます：

```asm
; アドレス 0xFFFFFFF0
jmp far 0xF000:0xE05B    ; セグメント:オフセット形式
```

**この命令の意味:**

```mermaid
graph LR
    A[0xFFFFFFF0<br/>Reset Vector] -->|jmp far| B[0xF000:0xE05B<br/>実効アドレス: 0xFE05B]
    B --> C[ファームウェア本体<br/>POST開始]

    style A fill:#f99,stroke:#333
    style B fill:#9f9,stroke:#333
    style C fill:#99f,stroke:#333
```

### セグメント:オフセット形式

x86 CPUはリセット時に**リアルモード**で起動します。

**リアルモードのアドレス計算:**

```
実効アドレス = (セグメント << 4) + オフセット
            = (0xF000 << 4) + 0xE05B
            = 0xF0000 + 0xE05B
            = 0xFE05B
```

**なぜセグメント形式なのか:**

| 理由 | 説明 |
|------|------|
| 後方互換性 | 8086 以来のアーキテクチャ |
| 20bitアドレッシング | リアルモードの制約 |
| 歴史的経緯 | 1MBメモリ空間の時代の設計 |

## ファームウェアの起動プロセス

### ステージ1: リセットベクタ

```mermaid
graph TB
    A[電源ON] --> B[CPUリセット]
    B --> C[CS=0xF000<br/>EIP=0xFFF0]
    C --> D[0xFFFFFFF0 実行]
    D --> E[JMP命令]
    E --> F[ファームウェアエントリポイント]

    style D fill:#f99,stroke:#333,stroke-width:2px
    style F fill:#9f9,stroke:#333,stroke-width:2px
```

### ステージ2: ファームウェアエントリポイント

ジャンプ先で、ファームウェアが本格的に動作を開始します：

```asm
; 0xFE05B (例)
cli                      ; 割り込み禁止
cld                      ; 方向フラグクリア
mov  ax, 0xF000          ; データセグメント設定
mov  ds, ax
mov  es, ax
mov  ss, ax
; ... 初期化処理継続
```

**主な処理:**

1. **レジスタ初期化**
   - セグメントレジスタ設定
   - スタックポインタ設定

2. **基本的なハードウェアチェック**
   - CPU IDの確認
   - キャッシュの設定

3. **次のステージへ遷移**
   - UEFIの場合: SEC フェーズ
   - レガシーBIOSの場合: POST

## UEFI と レガシーBIOS の違い

### リセットベクタの扱い

```mermaid
graph TB
    subgraph "UEFI"
    A1[Reset Vector] --> A2[SEC Entry]
    A2 --> A3[一時RAM設定]
    A3 --> A4[PEI Phase]
    end

    subgraph "Legacy BIOS"
    B1[Reset Vector] --> B2[POST開始]
    B2 --> B3[ハードウェアチェック]
    B3 --> B4[MBR読み込み]
    end

    style A2 fill:#9f9,stroke:#333
    style B2 fill:#f99,stroke:#333
```

### 共通点と相違点

| 項目 | UEFI | レガシーBIOS |
|------|------|-------------|
| **リセットベクタ** | 0xFFFFFFF0 | 0xFFFFFFF0（同じ） |
| **初期モード** | リアルモード | リアルモード（同じ） |
| **次のフェーズ** | SEC → PEI | POST |
| **メモリ初期化** | PEI で実施 | POST で実施 |
| **モード遷移** | 早期に64bitへ | 16bitを継続 |

## ハードウェアの役割

### チップセットの責務

```mermaid
graph TB
    subgraph "チップセット"
    A[SPI ROM Controller]
    B[Memory Map管理]
    end

    subgraph "SPI ROM"
    C[ファームウェアイメージ]
    end

    A -->|アドレスマッピング| B
    B -->|0xFFF00000-0xFFFFFFFF| C
    C -->|コード提供| D[CPU]

    style B fill:#9f9,stroke:#333,stroke-width:2px
```

**チップセットの役割:**

1. **SPIフラッシュROMのマッピング**
   - 物理デバイスをメモリ空間に配置
   - 固定アドレス（通常 4GB 付近）

2. **電源シーケンス制御**
   - 電圧の安定化
   - リセット信号の管理

3. **初期バス設定**
   - CPU-メモリ間のバス
   - 低速デバイスへのアクセス

### SPI ROM (Flash Memory)

**SPIフラッシュの特性:**

```mermaid
graph LR
    A[SPI ROM] --> B[不揮発性<br/>電源OFFでもデータ保持]
    A --> C[読み出し高速<br/>書き込み低速]
    A --> D[固定マッピング<br/>ハードウェアが自動設定]

    style A fill:#9f9,stroke:#333,stroke-width:2px
```

## なぜこの設計なのか

### 設計思想

```mermaid
graph TB
    A[設計目標] --> B[確実性<br/>必ず起動する]
    A --> C[単純性<br/>最小限の依存]
    A --> D[互換性<br/>歴史的継承]

    B --> E[固定アドレス]
    C --> E
    D --> E

    style E fill:#9f9,stroke:#333,stroke-width:2px
```

**重要な設計原則:**

1. **決定論的動作**
   - リセット時の状態は完全に決まっている
   - デバッグ容易

2. **最小限の依存**
   - RAM不要
   - 他のハードウェア不要

3. **後方互換性**
   - 30年以上継承されている
   - 既存のツール・知識が使える

## まとめ

この章では、CPUリセットから最初の命令実行までを説明しました。

**重要なポイント:**

- x86_64 CPUはリセット時に**0xFFFFFFF0**から実行開始
- この位置を**リセットベクタ**と呼ぶ
- リセットベクタには**JMP命令**が配置され、ファームウェア本体へジャンプ
- ファームウェアは**SPI ROMに配置**され、チップセットが固定アドレスにマップ
- リセット直後はRAM未初期化なので、**ROMのみアクセス可能**

**流れの要約:**

```mermaid
graph LR
    A[電源ON] --> B[CPU リセット]
    B --> C[0xFFFFFFF0]
    C --> D[JMP命令]
    D --> E[ファームウェア<br/>エントリポイント]
    E --> F[次フェーズへ]

    style C fill:#f99,stroke:#333,stroke-width:2px
    style E fill:#9f9,stroke:#333,stroke-width:2px
```

---

**次章では、メモリマップと E820 の仕組みを見ていきます。**

📚 **参考資料**
- [Intel® 64 and IA-32 Architectures Software Developer's Manual - Volume 3, Chapter 9: Processor Management and Initialization](https://www.intel.com/sdm)
- [AMD64 Architecture Programmer's Manual - Volume 2, Chapter 14: Processor Initialization and Long Mode](https://www.amd.com/en/support/tech-docs)
- [UEFI Specification v2.10 - Section 2.3: Boot Phases](https://uefi.org/specifications)
