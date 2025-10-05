# ACPI の目的と構造

🎯 **この章で学ぶこと**
- ACPI（Advanced Configuration and Power Interface）の目的と歴史
- ACPI のアーキテクチャと構成要素
- ACPI テーブルの概要とアクセス方法
- ACPI Namespace の構造
- AML（ACPI Machine Language）の基礎
- OS とファームウェアの協調動作

📚 **前提知識**
- [Part III: PCIe の仕組みとデバイス列挙](./05-pcie-enumeration.md)
- 電源管理の基本概念
- デバイスドライバの基礎知識

---

## ACPI とは何か

**ACPI（Advanced Configuration and Power Interface）** は、OS が主導権を持って電源管理・デバイス設定・熱管理を行うための業界標準規格です。

### ACPI の歴史

```mermaid
graph LR
    A[APM<br/>1992年] --> B[ACPI 1.0<br/>1996年]
    B --> C[ACPI 2.0<br/>2000年]
    C --> D[ACPI 3.0<br/>2004年]
    D --> E[ACPI 4.0<br/>2009年]
    E --> F[ACPI 5.0<br/>2011年]
    F --> G[ACPI 6.0<br/>2015年]
    G --> H[ACPI 6.5<br/>2022年]

    style A fill:#fcc,stroke:#333,stroke-width:2px
    style H fill:#cfc,stroke:#333,stroke-width:2px
```

**ACPI 登場の背景：**
- **APM（Advanced Power Management）時代**: BIOS が電源管理を制御
  - 問題: OS がハードウェア状態を把握できない
  - 問題: ベンダごとに異なる実装

- **ACPI の目的**: **OS Directed Power Management（OS 主導の電源管理）**
  - OS がハードウェアの状態を完全に把握
  - ベンダ非依存の標準インターフェース
  - デバイスの動的な設定変更

### ACPI の提供する機能

| カテゴリ | 機能 | 例 |
|---------|------|-----|
| **電源管理** | システム・デバイスの電源状態制御 | スリープ（S3）、休止（S4）、CPU C-State |
| **熱管理** | 温度監視と冷却制御 | ファン制御、サーマルスロットリング |
| **プラグ＆プレイ** | デバイスの動的設定 | リソース割り当て、ホットプラグ |
| **バッテリ管理** | バッテリ情報の取得 | 残量、充電状態 |
| **イベント通知** | ハードウェアイベントの伝達 | 電源ボタン、蓋開閉、ドック挿抜 |

---

## ACPI のアーキテクチャ

ACPI は **ACPI テーブル**、**ACPI Namespace**、**ACPI Machine Language (AML)** から構成されます。

### 全体構成

```mermaid
graph TD
    A[OS<br/>Operating System] --> B[ACPI ドライバ<br/>ACPI Subsystem]
    B --> C[AML インタプリタ]
    C --> D[ACPI Namespace]

    E[UEFI/BIOS] --> F[ACPI テーブル<br/>メモリ内]
    F --> G[RSDP/XSDT]
    F --> H[FADT/MADT/DSDT...]

    B --> F
    C --> F

    I[ハードウェア] --> J[ACPI レジスタ<br/>PM1a/GPE など]
    J --> B

    style E fill:#fbb,stroke:#333,stroke-width:2px
    style A fill:#bfb,stroke:#333,stroke-width:2px
    style I fill:#bbf,stroke:#333,stroke-width:2px
```

**コンポーネント：**

1. **ACPI テーブル（静的）**: UEFI/BIOS がメモリに配置
   - システム情報（CPU、割り込み、電源）
   - デバイスツリー
   - AML コード

2. **ACPI Namespace（動的）**: OS が構築
   - デバイスの階層構造
   - メソッドとオブジェクト

3. **AML インタプリタ**: OS が実行
   - AML バイトコードを解釈・実行
   - ハードウェア操作の抽象化

---

## ACPI テーブルの発見と構造

### RSDP（Root System Description Pointer）

OS は **RSDP** を起点に ACPI テーブルを発見します。

**RSDP の配置場所（UEFI）：**
- EFI Configuration Table 内の GUID: `EFI_ACPI_20_TABLE_GUID`

```c
/**
  RSDP を検索

  @retval RSDP アドレス
**/
EFI_ACPI_6_5_ROOT_SYSTEM_DESCRIPTION_POINTER *
FindRsdp (
  VOID
  )
{
  EFI_CONFIGURATION_TABLE  *ConfigTable;
  UINTN                    Index;

  ConfigTable = gST->ConfigurationTable;

  for (Index = 0; Index < gST->NumberOfTableEntries; Index++) {
    if (CompareGuid (&ConfigTable[Index].VendorGuid, &gEfiAcpi20TableGuid)) {
      // ACPI 2.0+ RSDP 発見
      return (EFI_ACPI_6_5_ROOT_SYSTEM_DESCRIPTION_POINTER *)ConfigTable[Index].VendorTable;
    }
  }

  return NULL;
}
```

**RSDP 構造体（ACPI 2.0+）：**

```c
typedef struct {
  UINT64  Signature;           // "RSD PTR " (8 bytes)
  UINT8   Checksum;            // 最初の 20 バイトのチェックサム
  UINT8   OemId[6];            // OEM 識別子
  UINT8   Revision;            // ACPI バージョン（2 = ACPI 2.0+）
  UINT32  RsdtAddress;         // RSDT 物理アドレス（32-bit、後方互換）
  // --- ACPI 2.0+ 拡張フィールド ---
  UINT32  Length;              // RSDP 構造体のサイズ
  UINT64  XsdtAddress;         // XSDT 物理アドレス（64-bit）
  UINT8   ExtendedChecksum;    // 全体のチェックサム
  UINT8   Reserved[3];
} EFI_ACPI_6_5_ROOT_SYSTEM_DESCRIPTION_POINTER;
```

### XSDT（Extended System Description Table）

**XSDT** は、他の ACPI テーブルへのポインタの配列です。

```c
typedef struct {
  EFI_ACPI_DESCRIPTION_HEADER  Header;   // シグネチャ "XSDT"
  UINT64                       Entry[1]; // 他のテーブルへの物理アドレス（可変長）
} EFI_ACPI_EXTENDED_SYSTEM_DESCRIPTION_TABLE;
```

**XSDT からテーブルを検索：**

```c
/**
  指定されたシグネチャの ACPI テーブルを検索

  @param[in]  Signature  テーブルシグネチャ（例: "FACP"）

  @retval テーブルアドレス
**/
VOID *
FindAcpiTable (
  IN UINT32  Signature
  )
{
  EFI_ACPI_6_5_ROOT_SYSTEM_DESCRIPTION_POINTER  *Rsdp;
  EFI_ACPI_EXTENDED_SYSTEM_DESCRIPTION_TABLE    *Xsdt;
  EFI_ACPI_DESCRIPTION_HEADER                   *Table;
  UINTN                                         EntryCount;
  UINTN                                         Index;

  Rsdp = FindRsdp ();
  if (Rsdp == NULL) {
    return NULL;
  }

  Xsdt = (EFI_ACPI_EXTENDED_SYSTEM_DESCRIPTION_TABLE *)(UINTN)Rsdp->XsdtAddress;
  EntryCount = (Xsdt->Header.Length - sizeof (EFI_ACPI_DESCRIPTION_HEADER)) / sizeof (UINT64);

  for (Index = 0; Index < EntryCount; Index++) {
    Table = (EFI_ACPI_DESCRIPTION_HEADER *)(UINTN)Xsdt->Entry[Index];
    if (Table->Signature == Signature) {
      return Table;
    }
  }

  return NULL;
}
```

### ACPI テーブル共通ヘッダ

すべての ACPI テーブルは共通ヘッダを持ちます。

```c
typedef struct {
  UINT32  Signature;          // テーブル識別子（例: "FACP", "APIC"）
  UINT32  Length;             // テーブル全体のサイズ
  UINT8   Revision;           // テーブルのバージョン
  UINT8   Checksum;           // チェックサム（全バイトの和が 0）
  UINT8   OemId[6];           // OEM 識別子
  UINT64  OemTableId;         // OEM テーブル ID
  UINT32  OemRevision;        // OEM リビジョン
  UINT32  CreatorId;          // テーブル作成ツール ID
  UINT32  CreatorRevision;    // 作成ツールバージョン
} EFI_ACPI_DESCRIPTION_HEADER;
```

**主要な ACPI テーブル：**

| シグネチャ | 名称 | 説明 |
|-----------|------|------|
| **FACP** | Fixed ACPI Description Table | 固定ハードウェア情報、DSDT ポインタ |
| **DSDT** | Differentiated System Description Table | デバイス定義、AML コード |
| **SSDT** | Secondary System Description Table | 追加デバイス定義、AML コード |
| **MADT** | Multiple APIC Description Table | CPU・割り込み情報 |
| **MCFG** | Memory Mapped Configuration Table | PCIe MMCONFIG アドレス |
| **HPET** | High Precision Event Timer Table | HPET デバイス情報 |
| **SRAT** | System Resource Affinity Table | NUMA ノード情報 |

---

## ACPI Namespace

**ACPI Namespace** は、デバイスとオブジェクトの階層的な名前空間です。

### Namespace の構造

```mermaid
graph TD
    A[\ <br/>ルート] --> B[_SB<br/>System Bus]
    B --> C[PCI0<br/>PCI Bus 0]
    C --> D[SATA<br/>SATA Controller]
    C --> E[USB0<br/>USB Controller]
    A --> F[_PR<br/>Processor]
    F --> G[CPU0]
    F --> H[CPU1]
    A --> I[_TZ<br/>Thermal Zone]
    I --> J[TZ00]

    style A fill:#fbb,stroke:#333,stroke-width:2px
    style B fill:#bfb,stroke:#333,stroke-width:2px
    style F fill:#bfb,stroke:#333,stroke-width:2px
```

**予約済みスコープ：**

| 名前 | 説明 |
|------|------|
| **\\_SB** | System Bus（デバイスツリーのルート） |
| **\\_PR** | Processor（CPU オブジェクト） |
| **\\_TZ** | Thermal Zone（温度管理） |
| **\\_SI** | System Indicator（システムインジケータ） |
| **\\_GPE** | General Purpose Events（汎用イベント） |

### オブジェクトの種類

```c
// ACPI オブジェクトの例（擬似コード）

// デバイスオブジェクト
Device (PCI0) {
  Name (_HID, EisaId ("PNP0A08"))  // Hardware ID: PCI Express Root Bridge
  Name (_CID, EisaId ("PNP0A03"))  // Compatible ID: PCI Root Bridge
  Name (_UID, 0)                   // Unique ID

  Method (_STA, 0) {               // Status: デバイスの状態
    Return (0x0F)                  // Present, Enabled, Shown, Functional
  }
}

// CPU オブジェクト
Processor (CPU0, 0x00, 0x00000410, 0x06) {
  Method (_PSS, 0) {               // Performance Supported States
    // P-State 定義
  }

  Method (_CST, 0) {               // C-States
    // C-State 定義
  }
}

// サーマルゾーン
ThermalZone (TZ00) {
  Method (_TMP, 0) {               // Temperature: 現在温度
    // 温度センサから読み取り
  }

  Method (_CRT, 0) {               // Critical Trip Point
    Return (373)                   // 100°C (Kelvin × 10)
  }
}
```

### 予約済みメソッド名

| メソッド | 用途 | 引数 |
|---------|------|------|
| **_HID** | Hardware ID | なし |
| **_UID** | Unique ID | なし |
| **_STA** | Status（デバイス状態） | なし |
| **_INI** | Initialize（初期化） | なし |
| **_ON** | Power On | なし |
| **_OFF** | Power Off | なし |
| **_PS0-_PS3** | Power State 0-3 | なし |
| **_CRS** | Current Resource Settings | なし |
| **_PRS** | Possible Resource Settings | なし |
| **_SRS** | Set Resource Settings | 1 |

---

## AML（ACPI Machine Language）

**AML** は、ACPI テーブル（DSDT/SSDT）に格納されるバイトコードです。OS の AML インタプリタが実行します。

### ASL から AML へ

**ASL（ACPI Source Language）** は人間が読み書きする言語、**AML** はそのコンパイル結果です。

```
ASL ソースコード → iasl コンパイラ → AML バイトコード
```

**ASL 例：**

```c
DefinitionBlock ("dsdt.aml", "DSDT", 2, "VENDOR", "BOARD", 0x00000001)
{
  Scope (\_SB)
  {
    Device (PCI0)
    {
      Name (_HID, EisaId ("PNP0A08"))
      Name (_CID, EisaId ("PNP0A03"))
      Name (_UID, 0)

      Method (_STA, 0, NotSerialized)
      {
        Return (0x0F)
      }

      // PCIe MMCONFIG 領域
      Name (_CRS, ResourceTemplate ()
      {
        WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
          0x0000,             // Granularity
          0x0000,             // Range Minimum (Bus 0)
          0x00FF,             // Range Maximum (Bus 255)
          0x0000,             // Translation Offset
          0x0100,             // Length (256 buses)
        )

        DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, NonCacheable, ReadWrite,
          0x00000000,         // Granularity
          0xE0000000,         // Range Minimum
          0xEFFFFFFF,         // Range Maximum
          0x00000000,         // Translation Offset
          0x10000000,         // Length (256 MB)
        )
      })
    }
  }
}
```

**対応する AML バイトコード（一部）：**

```
10 45 05 44 53 44 54  // DefinitionBlock header
02 56 45 4E 44 4F 52  // OEM ID: "VENDOR"
...
5B 82 41 04 50 43 49 30  // Device (PCI0)
08 5F 48 49 44 0C 41 D0 0A 08  // Name (_HID, EisaId("PNP0A08"))
14 09 5F 53 54 41 00 A4 0A 0F   // Method (_STA) { Return (0x0F) }
```

### AML オペコード

**主要な AML オペコード：**

| オペコード | 名前 | 説明 |
|-----------|------|------|
| 0x10 | Scope | スコープ定義 |
| 0x14 | Method | メソッド定義 |
| 0x5B 0x82 | Device | デバイスオブジェクト |
| 0x5B 0x83 | Processor | プロセッサオブジェクト |
| 0x08 | Name | 名前付きオブジェクト |
| 0xA4 | Return | 戻り値 |
| 0x70 | Store | 値の代入 |
| 0x7B | And | ビット AND |

### AML のデバッグ

```c
// ASL にデバッグ出力を追加
Method (_STA, 0)
{
  Store ("PCI0._STA called", Debug)  // カーネルログに出力
  Return (0x0F)
}
```

Linux では `dmesg | grep ACPI` でログ確認可能。

---

## 電源管理と ACPI

### システム電源状態（S-State）

| 状態 | 名称 | 説明 | 復帰方法 |
|------|------|------|---------|
| **S0** | Working | 通常動作 | - |
| **S1** | Standby | CPU 停止、コンテキスト保持 | 任意のイベント |
| **S2** | Standby | CPU 電源 OFF（ほぼ未使用） | 任意のイベント |
| **S3** | Suspend to RAM | RAM のみ通電、他は OFF | ウェイクイベント |
| **S4** | Suspend to Disk (Hibernate) | RAM 内容をディスク保存、全 OFF | 電源ボタン |
| **S5** | Soft Off | システム OFF、Wake-on-LAN 可 | 電源ボタン、WOL |
| **G3** | Mechanical Off | 完全 OFF | 物理スイッチ |

### デバイス電源状態（D-State）

| 状態 | 説明 | 消費電力 |
|------|------|---------|
| **D0** | Fully On | 100% |
| **D1** | Intermediate | 中間 |
| **D2** | Intermediate | 中間 |
| **D3 Hot** | Off, wake capable | 低（ウェイク可能） |
| **D3 Cold** | Off, no wake | 0% |

### プロセッサ電源状態（C-State）

| 状態 | 名称 | 説明 | 復帰時間 |
|------|------|------|---------|
| **C0** | Active | 実行中 | - |
| **C1** | Halt | HLT 命令、即座に復帰 | < 1 μs |
| **C2** | Stop Clock | クロック停止、L2 キャッシュ保持 | < 10 μs |
| **C3** | Sleep | キャッシュフラッシュ | < 100 μs |
| **C6** | Deep Sleep | コア電源 OFF | < 1 ms |

---

## OS と UEFI の協調

### ブート時の ACPI テーブル構築

```mermaid
sequenceDiagram
    participant UEFI as UEFI BIOS
    participant ACPI as ACPI Driver
    participant OS as OS Loader
    participant Kernel as OS Kernel

    UEFI->>ACPI: プラットフォーム情報収集
    ACPI->>ACPI: ACPI テーブル生成<br/>(RSDP/XSDT/FADT/MADT/DSDT...)
    ACPI->>UEFI: テーブルをメモリに配置
    UEFI->>UEFI: EFI Config Table に RSDP 登録

    OS->>UEFI: ExitBootServices()
    UEFI-->>OS: メモリマップ返却

    Kernel->>Kernel: RSDP を EFI Config Table から取得
    Kernel->>Kernel: ACPI テーブル解析
    Kernel->>Kernel: AML 実行、Namespace 構築
    Kernel->>Kernel: デバイス列挙・設定
```

### ランタイムサービスとの連携

**SetVariable()/GetVariable()** で ACPI と UEFI が連携：

```c
// ACPI から UEFI 変数を操作する例（ASL）
Method (GWAK, 0) {
  // UEFI 変数 "WakeType" を読み取り
  Store (\UEFI.GetVariable ("WakeType"), Local0)
  Return (Local0)
}
```

---

## 演習問題

### 基本演習

1. **ACPI の目的**
   ACPI が APM に対して改善した主なポイントを3つ挙げてください。

2. **RSDP 検索**
   UEFI 環境で RSDP を検索し、そのアドレスと Revision を表示するプログラムを書いてください。

### 応用演習

3. **FADT 解析**
   FADT テーブルを検索し、PM1a Event Register のアドレスを取得するコードを書いてください。

4. **ASL 記述**
   簡単なデバイス（例: LED コントローラ）を ASL で記述し、`_STA` と `_ON`/`_OFF` メソッドを実装してください。

### チャレンジ演習

5. **ACPI Namespace ダンプ**
   Linux の `/sys/firmware/acpi/` を使って、システムの ACPI Namespace をダンプし、主要なデバイスオブジェクトを確認してください。

6. **カスタムテーブル追加**
   独自の ACPI テーブル（SSDT）を作成し、UEFI ファームウェアに組み込んで OS から認識させてください。

---

## まとめ

この章では、ACPI の目的と構造について学びました。

🔑 **重要なポイント：**

1. **ACPI の目的**
   - OS 主導の電源管理（OS Directed Power Management）
   - ベンダ非依存の標準インターフェース
   - デバイス設定の動的変更

2. **ACPI アーキテクチャ**
   - **ACPI テーブル**: UEFI/BIOS が提供する静的情報
   - **ACPI Namespace**: OS が構築する階層的デバイスツリー
   - **AML**: バイトコード形式のデバイス記述言語

3. **テーブルの発見**
   - RSDP → XSDT → 各種テーブル（FADT, MADT, DSDT など）
   - UEFI では EFI Configuration Table から RSDP 取得

4. **電源管理**
   - **S-State**: システム全体の電源状態（S0-S5, G3）
   - **D-State**: デバイスの電源状態（D0-D3）
   - **C-State**: プロセッサのアイドル状態（C0-C6）

5. **OS との協調**
   - UEFI がブート時に ACPI テーブルを構築
   - OS が AML を実行してデバイスを制御
   - ランタイムサービスで変数を共有

**次章では、各 ACPI テーブルの詳細な役割について学びます。**

---

📚 **参考資料**
- [ACPI Specification 6.5](https://uefi.org/specifications) - ACPI 公式仕様書
- [Intel® ACPI Component Architecture (ACPICA)](https://acpica.org/) - ACPI リファレンス実装
- [ASL Tutorial](https://acpica.org/documentation) - ASL プログラミングガイド
- [Linux ACPI Documentation](https://www.kernel.org/doc/html/latest/firmware-guide/acpi/index.html) - Linux の ACPI 実装
- [Windows ACPI Debugging](https://docs.microsoft.com/en-us/windows-hardware/drivers/bringup/acpi-debugging) - Windows ACPI デバッグ
