# 各ブートフェーズの役割と責務

🎯 **この章で学ぶこと**
- 各ブートフェーズの詳細な責務
- フェーズ間の責任分担の設計原則
- ハンドオフ機構（HOB、プロトコル）
- なぜこのような分割が必要なのか

📚 **前提知識**
- UEFI ブートフェーズの全体像（第5章）
- メモリマップ（第2章）

---

## ブートフェーズ分割の設計思想

### なぜフェーズを分けるのか

UEFIは、起動処理を**5つのフェーズに分割**しています。

```mermaid
graph TB
    A[設計原則] --> B[段階的な機能有効化]
    A --> C[責任の分離]
    A --> D[モジュール性]

    B --> E[最小限から段階的に]
    C --> F[各フェーズは明確な責務]
    D --> G[独立した実装・テスト]

    style A fill:#9f9,stroke:#333,stroke-width:2px
```

**分割の理由:**

1. **段階的な機能有効化**
   - 電源ONからOSまで、利用可能なリソースが段階的に増加
   - 各段階で必要最小限の機能のみ提供

2. **責任の分離 (Separation of Concerns)**
   - ハードウェア初期化 vs ドライバ実行 vs ブート選択
   - 各フェーズは独立した責務を持つ

3. **モジュール性と保守性**
   - フェーズごとに異なるベンダーが実装可能
   - 独立したテストと検証

### 利用可能リソースの遷移

```mermaid
graph TB
    subgraph "SEC: 最小限"
    A1[CPU Cache as RAM]
    A2[ROM アクセス]
    end

    subgraph "PEI: 基本リソース"
    B1[DRAM]
    B2[CPU/Chipset]
    B3[基本 I/O]
    end

    subgraph "DXE: フルリソース"
    C1[全デバイス]
    C2[ファイルシステム]
    C3[ネットワーク]
    end

    A1 --> B1
    A2 --> B2
    B3 --> C1

    style A1 fill:#f99,stroke:#333
    style B1 fill:#ff9,stroke:#333
    style C1 fill:#9f9,stroke:#333
```

## SEC Phase の責務

### 主要な責任

**SEC (Security) Phase** は、最も制約の多い環境で動作します。

```mermaid
graph TB
    A[SEC Phase 責務] --> B[CPU 初期化]
    A --> C[CAR 設定]
    A --> D[PEI 発見・検証]

    B --> B1[マイクロコード更新]
    B --> B2[キャッシュ有効化]
    B --> B3[モード遷移準備]

    C --> C1[No-Evict モード]
    C --> C2[一時スタック確保]

    D --> D1[FV 検索]
    D --> D2[PEI Core ロード]

    style A fill:#f99,stroke:#333,stroke-width:2px
```

### 詳細な責務

**1. CPU の最小限初期化**

| 項目 | 内容 | 目的 |
|------|------|------|
| マイクロコード更新 | CPU マイクロコードのロード | バグ修正、機能追加 |
| キャッシュ設定 | L1/L2 キャッシュ有効化 | CAR の準備 |
| モード遷移 | リアルモード → ロングモード | 64bit 環境構築 |

**2. Cache as RAM (CAR) の設定**

```
目的: DRAM 未初期化でも RAM を確保

仕組み:
1. CPU キャッシュを No-Evict モードに設定
2. 特定のアドレス範囲をキャッシュに固定
3. RAM のように使用（通常 64KB-256KB）

制約:
- サイズが限定的
- 速度は DRAM より高速
- CPU 依存（Intel/AMD で異なる）
```

**3. PEI Core の発見とロード**

```mermaid
sequenceDiagram
    participant SEC as SEC Phase
    participant FV as Firmware Volume
    participant PEI as PEI Core

    SEC->>FV: Firmware Volume 検索
    FV-->>SEC: PEI Core の位置
    SEC->>SEC: 署名検証（Secure Boot時）
    SEC->>PEI: PEI Core にジャンプ
    PEI->>PEI: PEI 環境初期化
```

### なぜSECが必要なのか

**設計上の制約:**
- DRAM が未初期化 → RAM を使えない
- デバイスが未初期化 → I/O を使えない
- 最小限の機能で次のステージへ遷移する必要

**SECの役割:**
- **ブートストラップ**: 何もない状態から最初のRAMを確保
- **セキュリティの起点**: 信頼チェーンの開始点
- **プラットフォーム独立性**: CPU初期化のみに専念

## PEI Phase の責務

### 主要な責任

**PEI (Pre-EFI Initialization) Phase** は、プラットフォーム固有の初期化を担当します。

```mermaid
graph TB
    A[PEI Phase 責務] --> B[DRAM 初期化]
    A --> C[CPU/Chipset 初期化]
    A --> D[DXE 準備]

    B --> B1[Memory Controller 設定]
    B --> B2[DRAM トレーニング]
    B --> B3[Memory Map 構築]

    C --> C1[CPU 機能設定]
    C --> C2[Chipset レジスタ設定]
    C --> C3[基本 I/O 初期化]

    D --> D1[HOB 構築]
    D --> D2[DXE Core ロード]

    style A fill:#ff9,stroke:#333,stroke-width:2px
```

### 詳細な責務

**1. DRAM 初期化（最重要タスク）**

```
DRAM 初期化の流れ:

1. Memory Controller 検出
   - CPU/Chipset のメモリコントローラ特定

2. SPD (Serial Presence Detect) 読み込み
   - メモリモジュールの仕様取得
   - 容量、タイミング、電圧など

3. DRAM トレーニング
   - 信号タイミング調整
   - 読み書きマージン測定
   - 最適パラメータ決定

4. Memory Map 構築
   - E820/UEFI Memory Map 作成
   - メモリホールの設定

5. CAR → DRAM 移行
   - スタック・ヒープを DRAM へ移動
```

**2. プラットフォーム固有初期化**

| コンポーネント | 初期化内容 | 理由 |
|--------------|-----------|------|
| CPU | 高度な機能有効化 | MTRR, MSR 設定 |
| Chipset | PCH/SoC 初期化 | I/O コントローラ準備 |
| クロック | PLL, クロック設定 | デバイス動作周波数 |
| 電源 | VR (Voltage Regulator) | CPU/DRAM 電圧設定 |

**3. HOB (Hand-Off Block) の構築**

```c
// HOB の概念（実装例ではなく構造の説明）
typedef struct {
  UINT16  HobType;      // HOB の種類
  UINT16  HobLength;    // サイズ
  UINT32  Reserved;
} EFI_HOB_GENERIC_HEADER;

// HOB の種類:
// - Resource Descriptor: メモリリソース情報
// - GUID Extension: カスタムデータ
// - CPU: CPU 情報
// - Memory Allocation: メモリ割り当て情報
```

**HOBの役割:**

```mermaid
graph LR
    A[PEI Phase] -->|HOB リスト| B[DXE Phase]

    A -->|メモリ情報| B
    A -->|CPU 情報| B
    A -->|プラットフォーム設定| B

    style A fill:#ff9,stroke:#333
    style B fill:#9f9,stroke:#333
```

### PEIM (PEI Module) の役割

PEIフェーズは、**PEIM**という小さなモジュール群で構成されます。

**主なPEIM:**

| PEIM | 役割 | 依存関係 |
|------|------|---------|
| PlatformPei | プラットフォーム検出 | なし（最初） |
| CpuPei | CPU 初期化 | PlatformPei |
| MemoryInit | DRAM 初期化 | CpuPei |
| ChipsetPei | Chipset 初期化 | MemoryInit |

**PEIMの実行順序:**

```mermaid
graph TB
    A[PEI Core] --> B[Dependency 解決]
    B --> C[PEIM 1 実行]
    C --> D[PEIM 2 実行]
    D --> E[PEIM N 実行]
    E --> F[DXE Core 起動]

    style B fill:#9f9,stroke:#333
```

依存関係は `.inf` ファイルの `[Depex]` セクションで定義されます。

## DXE Phase の責務

### 主要な責任

**DXE (Driver Execution Environment) Phase** は、フルスペックのドライバ実行環境を提供します。

```mermaid
graph TB
    A[DXE Phase 責務] --> B[ドライバ実行環境]
    A --> C[デバイス初期化]
    A --> D[サービス提供]

    B --> B1[Dispatcher]
    B --> B2[Protocol Database]
    B --> B3[Handle Database]

    C --> C1[PCIe 列挙]
    C --> C2[USB/Network/Storage]
    C --> C3[GOP（Graphics）]

    D --> D1[Boot Services]
    D --> D2[Runtime Services]

    style A fill:#9f9,stroke:#333,stroke-width:2px
```

### 詳細な責務

**1. DXE Dispatcher（中核機能）**

```
Dispatcher の役割:

1. Firmware Volume (FV) からドライバ検索
2. 依存関係（Depex）を解析
3. 実行可能なドライバをロード・実行
4. プロトコルが公開されたら再評価
5. すべてのドライバが実行されるまで繰り返し
```

**Dispatcherのアルゴリズム:**

```mermaid
graph TB
    A[Dispatcher 開始] --> B[FV からドライバ一覧取得]
    B --> C{未実行ドライバあり?}
    C -->|No| G[BDS へ]
    C -->|Yes| D[Depex 評価]
    D --> E{依存関係満たす?}
    E -->|Yes| F[ドライバ実行]
    E -->|No| C
    F --> C

    style F fill:#9f9,stroke:#333
```

**2. プロトコルによるサービス公開**

```c
// プロトコルの概念（UEFIの基本設計）
typedef struct {
  EFI_GUID  ProtocolGuid;  // プロトコルの識別子
  VOID      *Interface;    // 関数テーブルへのポインタ
  EFI_HANDLE Handle;       // デバイスハンドル
} EFI_PROTOCOL_ENTRY;

// 例: Simple Text Output Protocol
typedef struct {
  EFI_TEXT_RESET              Reset;
  EFI_TEXT_STRING             OutputString;
  EFI_TEXT_TEST_STRING        TestString;
  // ...
} EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL;
```

**プロトコルの種類:**

| カテゴリ | プロトコル例 | 役割 |
|---------|------------|------|
| Console | Simple Text Input/Output | コンソール I/O |
| Graphics | Graphics Output Protocol (GOP) | 画面描画 |
| Storage | Block I/O, Disk I/O | ストレージアクセス |
| Network | Simple Network Protocol | ネットワーク通信 |
| File System | Simple File System | ファイル操作 |

**3. デバイス初期化の流れ**

```mermaid
sequenceDiagram
    participant Dispatcher as DXE Dispatcher
    participant BusDrv as Bus Driver
    participant DevDrv as Device Driver
    participant Device as デバイス

    Dispatcher->>BusDrv: ドライバロード
    BusDrv->>BusDrv: バススキャン（PCIe等）
    BusDrv->>Device: デバイス発見
    BusDrv->>BusDrv: Handle作成
    Dispatcher->>DevDrv: ドライバロード
    DevDrv->>BusDrv: Handle検索
    DevDrv->>Device: デバイス初期化
    DevDrv->>DevDrv: プロトコル公開
```

**4. Boot Services と Runtime Services**

```
Boot Services（OS起動前のみ）:
- メモリ管理（AllocatePool, AllocatePages）
- プロトコル操作（InstallProtocol, LocateProtocol）
- イベント・タイマ
- ドライバ管理

Runtime Services（OS実行中も利用可能）:
- NVRAM変数アクセス（GetVariable, SetVariable）
- 時刻取得・設定（GetTime, SetTime）
- システムリセット（ResetSystem）
- カプセル更新（UpdateCapsule）
```

### DXEドライバの種類と役割

```mermaid
graph TB
    A[DXEドライバ] --> B[Core Driver]
    A --> C[Bus Driver]
    A --> D[Device Driver]
    A --> E[Application]

    B --> B1[DXE Core<br/>Dispatcher<br/>Protocol DB]
    C --> C1[PCIe Bus<br/>USB Bus<br/>SCSI Bus]
    D --> D1[NIC Driver<br/>Storage Driver<br/>Video Driver]
    E --> E1[UEFI Shell<br/>Setup UI<br/>診断ツール]

    style B fill:#f99,stroke:#333
    style C fill:#ff9,stroke:#333
    style D fill:#9f9,stroke:#333
    style E fill:#99f,stroke:#333
```

## BDS Phase の責務

### 主要な責任

**BDS (Boot Device Selection) Phase** は、ブートデバイスを選択しOSを起動します。

```mermaid
graph TB
    A[BDS Phase 責務] --> B[ブートオプション管理]
    A --> C[ブート試行]
    A --> D[ユーザーインターフェース]

    B --> B1[BootOrder 読み込み]
    B --> B2[デバイスパス解決]

    C --> C1[ブートローダ検索]
    C --> C2[ブートローダ実行]

    D --> D1[Setup UI]
    D --> D2[Boot Menu]

    style A fill:#99f,stroke:#333,stroke-width:2px
```

### 詳細な責務

**1. ブートオプションの管理**

```
NVRAM 変数の構造:

BootOrder: UINT16[]
  - ブート試行順序（例: [0x0000, 0x0003, 0x0001]）

Boot0000, Boot0001, ...: EFI_LOAD_OPTION
  - 各ブートオプションの詳細
  - デバイスパス
  - 説明文字列
  - オプショナルデータ

BootCurrent: UINT16
  - 現在起動中のオプション
```

**BootOrderの処理フロー:**

```mermaid
graph TB
    A[BDS 開始] --> B[BootOrder 取得]
    B --> C[Boot0000 取得]
    C --> D{デバイスパス解決可能?}
    D -->|Yes| E[ブートローダ実行]
    D -->|No| F[次のオプション]
    E --> G{ブート成功?}
    G -->|Yes| H[OS起動]
    G -->|No| F
    F --> C

    style E fill:#9f9,stroke:#333
    style H fill:#9f9,stroke:#333,stroke-width:2px
```

**2. デバイスパスの解決**

デバイスパスは、デバイスの位置を階層的に表現します。

```
例: USB メモリのブートローダ

PciRoot(0x0)/Pci(0x14,0x0)/USB(0x3,0x0)/HD(1,GPT,...)/\EFI\BOOT\BOOTX64.EFI

解釈:
1. PCI Root Bridge
2. PCI(0x14,0x0): USB Controller
3. USB(0x3,0x0): ポート3のデバイス
4. HD(1,...): パーティション1（GPT）
5. \EFI\BOOT\BOOTX64.EFI: ファイルパス
```

**3. フォールバック機構**

```mermaid
graph TB
    A[ブート試行] --> B{BootOrder 成功?}
    B -->|No| C[リムーバブルメディア検索]
    C --> D{見つかった?}
    D -->|Yes| E[デフォルトパス試行<br/>\EFI\BOOT\BOOTX64.EFI]
    D -->|No| F[ネットワークブート試行<br/>PXE]
    E --> G{成功?}
    G -->|Yes| H[OS起動]
    G -->|No| F
    F --> I{成功?}
    I -->|Yes| H
    I -->|No| J[エラー表示]

    style H fill:#9f9,stroke:#333
```

**4. ユーザーインターフェース**

| UI | 役割 | 起動条件 |
|-----|------|---------|
| Setup UI | BIOS設定画面 | Del/F2キー |
| Boot Menu | ブートデバイス選択 | F12キー |
| Boot Manager | ブートオプション管理 | NVRAM設定 |

### BDSの設計思想

**なぜBDSが独立しているのか:**

1. **ポリシーとメカニズムの分離**
   - DXE: デバイスを使える状態にする（メカニズム）
   - BDS: どのデバイスから起動するか決定（ポリシー）

2. **柔軟性**
   - OEM ごとに異なるブートポリシー
   - カスタム UI の実装が容易

3. **セキュリティ**
   - Secure Boot の検証はここで実施
   - ユーザー認証もここで可能

## TSL/RT の責務

### TSL (Transient System Load)

**OSへの制御移譲:**

```mermaid
sequenceDiagram
    participant BDS as BDS Phase
    participant Loader as ブートローダ
    participant Kernel as OSカーネル
    participant UEFI as UEFI環境

    BDS->>Loader: LoadImage()
    BDS->>Loader: StartImage()
    Loader->>Loader: カーネルロード
    Loader->>Loader: 設定読み込み
    Loader->>UEFI: ExitBootServices()
    Note over UEFI: Boot Services 終了
    Loader->>Kernel: カーネルエントリ
    Kernel->>Kernel: OS 初期化
```

**ExitBootServices() の影響:**

```
終了するサービス:
- Boot Services のすべて
- ほとんどのドライバ
- イベント・タイマ
- メモリ管理サービス

継続するサービス:
- Runtime Services のみ
- 一部のドライバ（Runtime Driver）
```

### Runtime Services の役割

**OS実行中も提供されるサービス:**

| サービス | 機能 | 使用例 |
|---------|------|--------|
| Variable Services | NVRAM 変数アクセス | ブート設定保存 |
| Time Services | RTC 時刻取得・設定 | システム時刻 |
| Reset Services | システムリセット | シャットダウン |
| Capsule Services | ファームウェア更新 | BIOS 更新 |

**Runtime Servicesのメモリレイアウト:**

```
OS起動後のメモリマップ:

┌─────────────────┐
│ OS カーネル      │
├─────────────────┤
│ アプリケーション  │
├─────────────────┤
│ Runtime Services │ ← UEFI が提供
│ (MMIO領域)       │    仮想アドレスにマップ
├─────────────────┤
│ Runtime Driver   │
└─────────────────┘
```

**SetVirtualAddressMap():**

OSは、Runtime Servicesを仮想アドレス空間にマップします。

```c
// 概念的な流れ
// 1. OS がページテーブル構築
// 2. Runtime Services を仮想アドレスへマップ
// 3. UEFI に新しいアドレスを通知
Status = RuntimeServices->SetVirtualAddressMap(
  MemoryMapSize,
  DescriptorSize,
  DescriptorVersion,
  VirtualMap
);
// 4. 以降、仮想アドレスで Runtime Services を呼び出し
```

## フェーズ間ハンドオフの仕組み

### 情報の受け渡し方法

```mermaid
graph LR
    A[SEC] -->|一時RAM領域| B[PEI]
    B -->|HOB リスト| C[DXE]
    C -->|Configuration Table| D[BDS]
    D -->|Configuration Table| E[OS]

    style A fill:#f99,stroke:#333
    style B fill:#ff9,stroke:#333
    style C fill:#9f9,stroke:#333
    style D fill:#99f,stroke:#333
    style E fill:#f9f,stroke:#333
```

**各ハンドオフ機構:**

| 遷移 | 機構 | 内容 |
|------|------|------|
| SEC → PEI | スタック | 最小限の情報（CAR領域） |
| PEI → DXE | HOB | メモリマップ、CPU情報、設定 |
| DXE → BDS | Protocol | すべてのデバイス・サービス |
| BDS → OS | Configuration Table | ACPI、SMBIOS、メモリマップ |

### Configuration Table

**OSへ渡されるテーブル:**

```c
// UEFI Configuration Table の構造
typedef struct {
  EFI_GUID  VendorGuid;     // テーブルの種類
  VOID      *VendorTable;   // テーブルへのポインタ
} EFI_CONFIGURATION_TABLE;

// 主なテーブル:
// - ACPI Table: ACPI_20_TABLE_GUID
// - SMBIOS Table: SMBIOS_TABLE_GUID
// - Device Tree: DEVICE_TREE_GUID (ARM)
```

**Linuxカーネルでの利用例:**

```
Linuxカーネル起動時:
1. UEFI から Configuration Table 取得
2. ACPI Table を解析 → デバイス情報
3. SMBIOS Table を解析 → ハードウェア情報
4. Memory Map を取得 → メモリ管理
```

## 責務分担の設計原則

### 各フェーズの設計指針

```mermaid
graph TB
    A[設計原則] --> B[最小特権の原則]
    A --> C[段階的複雑化]
    A --> D[独立性とテスト容易性]

    B --> B1[各フェーズは必要最小限の権限]
    C --> C1[機能を段階的に追加]
    D --> D1[フェーズ間の疎結合]

    style A fill:#9f9,stroke:#333,stroke-width:2px
```

**1. 最小特権の原則**

| フェーズ | 利用可能リソース | 理由 |
|---------|-----------------|------|
| SEC | CPU、ROM | セキュリティの起点、最小限 |
| PEI | + DRAM、基本I/O | プラットフォーム初期化に必要 |
| DXE | + 全デバイス | ドライバ実行環境 |
| BDS | すべて | ブート処理のため |

**2. 段階的複雑化**

```
複雑さの遷移:

SEC:    シンプル（数KB）
  ↓
PEI:    中程度（数十～数百KB）
  ↓
DXE:    複雑（数MB）
  ↓
BDS:    中程度（ポリシーのみ）
```

**3. 疎結合の実現**

```mermaid
graph LR
    A[PEI] -->|HOB<br/>標準インターフェース| B[DXE]
    B -->|Protocol<br/>標準インターフェース| C[BDS]

    style A fill:#ff9,stroke:#333
    style B fill:#9f9,stroke:#333
    style C fill:#99f,stroke:#333
```

インターフェースを標準化することで：
- 各フェーズの独立実装が可能
- ベンダー固有部分とコア部分を分離
- テストとデバッグが容易

## まとめ

この章では、各ブートフェーズの詳細な責務を説明しました。

**重要なポイント:**

**フェーズごとの主要責務:**

| フェーズ | 主要責務 | 成果物 |
|---------|---------|--------|
| **SEC** | CPU初期化、CAR設定 | PEI Core起動 |
| **PEI** | DRAM初期化、プラットフォーム初期化 | HOBリスト、DXE Core起動 |
| **DXE** | ドライバ実行、デバイス初期化 | Boot/Runtime Services |
| **BDS** | ブートデバイス選択、ブート実行 | OS起動 |
| **TSL/RT** | OSへ制御移譲、Runtime Services提供 | OS実行環境 |

**設計原則:**

- **段階的機能有効化**: リソースを段階的に利用可能にする
- **責任の分離**: 各フェーズは明確な責務を持つ
- **モジュール性**: 独立した実装・テストが可能
- **標準インターフェース**: HOB、Protocol、Configuration Tableで疎結合

**ハンドオフ機構:**

```mermaid
graph LR
    A[SEC<br/>CAR] --> B[PEI<br/>DRAM + HOB]
    B --> C[DXE<br/>Protocol DB]
    C --> D[BDS<br/>Boot Policy]
    D --> E[OS<br/>Config Table]

    style A fill:#f99,stroke:#333
    style E fill:#f9f,stroke:#333
```

各フェーズは、前のフェーズから情報を受け取り、次のフェーズへ渡す責任を持ちます。

---

**次章では、Part I 全体のまとめを行います。**

📚 **参考資料**
- [UEFI Specification v2.10 - Chapter 2: Boot Phases](https://uefi.org/specifications)
- [UEFI PI Specification v1.8 - Volume 1-5](https://uefi.org/specifications)
- [EDK II Module Writer's Guide](https://tianocore-docs.github.io/edk2-ModuleWriteGuide/)
- [Intel® 64 and IA-32 Architectures Software Developer's Manual](https://www.intel.com/sdm)
