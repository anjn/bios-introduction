# 仕様書クイックリファレンス

頻繁に参照する仕様書の重要なセクションをクイックリファレンスとしてまとめました。

---

## 📘 UEFI Specification 2.10

### 主要な章構成

| 章 | タイトル | 内容 |
|---|---------|------|
| **2** | Overview | UEFI の概要とアーキテクチャ |
| **3** | Boot Manager | ブートマネージャの動作 |
| **4** | EFI System Table | システムテーブルの構造 |
| **6** | Protocol Handler Services | プロトコルサービス |
| **7** | Services - Boot Services | ブートサービス |
| **8** | Services - Runtime Services | ランタイムサービス |
| **12** | Protocols - Console Support | コンソール入出力プロトコル |
| **13** | Protocols - Media Access | ストレージアクセスプロトコル |
| **14** | Protocols - PCI Bus Support | PCI バスプロトコル |
| **15** | Protocols - SCSI Driver Models | SCSI/SATA プロトコル |
| **32** | Secure Boot and Driver Signing | Secure Boot の仕様 |

### 重要な構造体

#### EFI_SYSTEM_TABLE

```c
typedef struct {
  EFI_TABLE_HEADER                 Hdr;
  CHAR16                           *FirmwareVendor;
  UINT32                           FirmwareRevision;
  EFI_HANDLE                       ConsoleInHandle;
  EFI_SIMPLE_TEXT_INPUT_PROTOCOL   *ConIn;
  EFI_HANDLE                       ConsoleOutHandle;
  EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL  *ConOut;
  EFI_HANDLE                       StandardErrorHandle;
  EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL  *StdErr;
  EFI_RUNTIME_SERVICES             *RuntimeServices;
  EFI_BOOT_SERVICES                *BootServices;
  UINTN                            NumberOfTableEntries;
  EFI_CONFIGURATION_TABLE          *ConfigurationTable;
} EFI_SYSTEM_TABLE;
```

**参照**: UEFI Spec 2.10, Section 4.3

#### EFI_BOOT_SERVICES

主要なサービス関数:

| サービス | 説明 | 参照 |
|---------|------|------|
| `AllocatePool()` | メモリ割り当て | 7.2 |
| `FreePool()` | メモリ解放 | 7.2 |
| `InstallProtocolInterface()` | プロトコルインストール | 7.3 |
| `LocateProtocol()` | プロトコル検索 | 7.3 |
| `LoadImage()` | イメージロード | 7.4 |
| `StartImage()` | イメージ実行 | 7.4 |
| `Exit()` | アプリケーション終了 | 7.4 |

**参照**: UEFI Spec 2.10, Section 7

#### EFI_RUNTIME_SERVICES

主要なサービス関数:

| サービス | 説明 | 参照 |
|---------|------|------|
| `GetVariable()` | UEFI 変数取得 | 8.2 |
| `SetVariable()` | UEFI 変数設定 | 8.2 |
| `GetTime()` | 時刻取得 | 8.3 |
| `SetTime()` | 時刻設定 | 8.3 |
| `ResetSystem()` | システムリセット | 8.4 |

**参照**: UEFI Spec 2.10, Section 8

### 主要なプロトコル GUID

```c
// Graphics Output Protocol
#define EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID \
  {0x9042a9de,0x23dc,0x4a38,{0x96,0xfb,0x7a,0xde,0xd0,0x80,0x51,0x6a}}

// Simple File System Protocol
#define EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID \
  {0x0964e5b22,0x6459,0x11d2,{0x8e,0x39,0x00,0xa0,0xc9,0x69,0x72,0x3b}}

// Block I/O Protocol
#define EFI_BLOCK_IO_PROTOCOL_GUID \
  {0x964e5b21,0x6459,0x11d2,{0x8e,0x39,0x00,0xa0,0xc9,0x69,0x72,0x3b}}

// USB I/O Protocol
#define EFI_USB_IO_PROTOCOL_GUID \
  {0x2B2F68D6,0x0CD2,0x44cf,{0x8E,0x8B,0xBB,0xA2,0x0B,0x1B,0x5B,0x75}}
```

**参照**: UEFI Spec 2.10, Appendix A

### Secure Boot 関連

#### 変数名

| 変数名 | 説明 | 参照 |
|--------|------|------|
| `PK` | Platform Key | 32.3.1 |
| `KEK` | Key Exchange Key | 32.3.2 |
| `db` | 許可されたデータベース | 32.3.3 |
| `dbx` | 禁止されたデータベース | 32.3.4 |
| `SecureBoot` | Secure Boot 状態 | 32.4.1 |

**参照**: UEFI Spec 2.10, Section 32

---

## 📗 ACPI Specification 6.5

### 主要な章構成

| 章 | タイトル | 内容 |
|---|---------|------|
| **5** | ACPI Software Programming Model | ACPI の概要 |
| **6** | Configuration | システム設定 |
| **9** | ACPI-Defined Devices | ACPI デバイス |
| **17** | Waking and Sleeping | 電源管理 |
| **19** | PCI Express Support | PCIe サポート |

### 主要なテーブル

#### RSDP (Root System Description Pointer)

```c
typedef struct {
  CHAR8   Signature[8];     // "RSD PTR "
  UINT8   Checksum;
  CHAR8   OemId[6];
  UINT8   Revision;
  UINT32  RsdtAddress;
  // ACPI 2.0+
  UINT32  Length;
  UINT64  XsdtAddress;
  UINT8   ExtendedChecksum;
  UINT8   Reserved[3];
} ACPI_RSDP;
```

**参照**: ACPI Spec 6.5, Section 5.2.5

#### RSDT/XSDT (Root/Extended System Description Table)

```c
typedef struct {
  ACPI_TABLE_HEADER Header;
  UINT32            TableOffsetEntry[n];  // RSDTの場合
  // UINT64         TableOffsetEntry[n];  // XSDTの場合
} ACPI_RSDT_XSDT;
```

**参照**: ACPI Spec 6.5, Section 5.2.7, 5.2.8

#### FADT (Fixed ACPI Description Table)

主要フィールド:

| フィールド | 説明 | オフセット |
|----------|------|-----------|
| `FIRMWARE_CTRL` | FACS アドレス | 36 |
| `DSDT` | DSDT アドレス | 40 |
| `PM1a_EVT_BLK` | PM1a イベントブロック | 56 |
| `PM1a_CNT_BLK` | PM1a コントロールブロック | 64 |

**参照**: ACPI Spec 6.5, Section 5.2.9

#### MADT (Multiple APIC Description Table)

構造体タイプ:

| Type | 名前 | 説明 |
|------|------|------|
| 0 | Processor Local APIC | CPU のローカル APIC |
| 1 | I/O APIC | I/O APIC 情報 |
| 2 | Interrupt Source Override | 割り込みオーバーライド |
| 9 | Processor Local x2APIC | x2APIC 情報 |

**参照**: ACPI Spec 6.5, Section 5.2.12

#### DSDT/SSDT (Differentiated/Secondary System Description Table)

AML (ACPI Machine Language) を含むテーブル。

**参照**: ACPI Spec 6.5, Section 5.2.11

### AML オペレーションリージョン

```asl
OperationRegion (PCFG, PCI_Config, 0x00, 0x100)
Field (PCFG, DWordAcc, NoLock, Preserve) {
  VID,  16,  // Vendor ID
  DID,  16,  // Device ID
}
```

**参照**: ACPI Spec 6.5, Section 19.6.86

### 電源状態

| 状態 | 名前 | 説明 |
|------|------|------|
| **S0** | Working | 動作中 |
| **S1** | Sleep (CPU停止、RAM有効) | CPU 停止、メモリ保持 |
| **S3** | Suspend to RAM | RAM のみ通電 |
| **S4** | Suspend to Disk | ディスクに保存 |
| **S5** | Soft Off | 完全停止 |

**参照**: ACPI Spec 6.5, Section 16

---

## 📕 PI Specification 1.8 (Platform Initialization)

### ブートフェーズ

| フェーズ | 名前 | 説明 | Volume |
|---------|------|------|--------|
| **SEC** | Security Phase | 最小限の初期化 | Volume 1 |
| **PEI** | Pre-EFI Initialization | メモリ初期化 | Volume 1 |
| **DXE** | Driver Execution Environment | ドライバ実行 | Volume 2 |
| **BDS** | Boot Device Selection | ブートデバイス選択 | Volume 3 |
| **TSL** | Transient System Load | OS ローダ実行 | Volume 3 |
| **RT** | Runtime | OS 実行中 | - |

**参照**: PI Spec 1.8, Volume 1, Section 2

### PEI

#### PPI (PEIM-to-PEIM Interface)

主要な PPI:

| PPI | 説明 | 参照 |
|-----|------|------|
| `EFI_PEI_CPU_IO_PPI` | CPU I/O アクセス | Vol.1, 8.3 |
| `EFI_PEI_PCI_CFG2_PPI` | PCI 設定アクセス | Vol.1, 8.4 |
| `EFI_PEI_STALL_PPI` | 遅延 | Vol.1, 8.5 |
| `EFI_PEI_RESET2_PPI` | システムリセット | Vol.1, 8.7 |

**参照**: PI Spec 1.8, Volume 1

#### HOB (Hand-Off Block)

主要な HOB タイプ:

| タイプ | 説明 | 参照 |
|--------|------|------|
| `EFI_HOB_TYPE_HANDOFF` | 最初の HOB | Vol.3, 4 |
| `EFI_HOB_TYPE_MEMORY_ALLOCATION` | メモリ割り当て | Vol.3, 5 |
| `EFI_HOB_TYPE_RESOURCE_DESCRIPTOR` | リソース記述 | Vol.3, 6 |
| `EFI_HOB_TYPE_GUID_EXTENSION` | GUID 拡張 | Vol.3, 7 |
| `EFI_HOB_TYPE_FV` | ファームウェアボリューム | Vol.3, 8 |
| `EFI_HOB_TYPE_CPU` | CPU 情報 | Vol.3, 9 |

**参照**: PI Spec 1.8, Volume 3

### DXE

#### DXE Services

| サービス | 説明 | 参照 |
|---------|------|------|
| `AddMemorySpace()` | メモリ空間追加 | Vol.2, 7.2.1 |
| `AllocateMemorySpace()` | メモリ割り当て | Vol.2, 7.2.2 |
| `GetMemorySpaceDescriptor()` | メモリ記述子取得 | Vol.2, 7.2.4 |
| `SetMemorySpaceAttributes()` | メモリ属性設定 | Vol.2, 7.2.5 |

**参照**: PI Spec 1.8, Volume 2

#### ドライバタイプ

| タイプ | 説明 | 参照 |
|--------|------|------|
| **DXE Driver** | 標準ドライバ | Vol.2, 3 |
| **DXE Runtime Driver** | ランタイムドライバ | Vol.2, 3 |
| **UEFI Driver** | UEFI ドライバ | Vol.2, 3 |
| **SMM Driver** | SMM ドライバ | Vol.4 |

**参照**: PI Spec 1.8, Volume 2

---

## 🔧 Intel SDM (Software Developer's Manual)

### Volume 3: System Programming Guide

#### 主要な章

| 章 | タイトル | 内容 |
|---|---------|------|
| **9** | Processor Management and Initialization | プロセッサ管理と初期化 |
| **10** | Advanced Programmable Interrupt Controller (APIC) | APIC |
| **11** | Memory Cache Control | キャッシュ制御 |
| **12** | Memory Type Range Registers (MTRRs) | MTRR |
| **34** | System Management Mode (SMM) | SMM |
| **35** | Intel® VT-x | 仮想化 |

**参照**: Intel SDM Vol.3

#### リセットベクタ

```
Physical Address: 0xFFFFFFF0 (4GB - 16 bytes)
Initial State:
  CS.Selector = 0xF000
  CS.Base     = 0xFFFF0000
  RIP         = 0xFFF0
  → Linear Address = 0xFFFFFFF0
```

**参照**: Intel SDM Vol.3, Section 9.1.4

#### CPU モード

| モード | 説明 | 参照 |
|--------|------|------|
| **Real Mode** | 16bit モード | 9.1 |
| **Protected Mode** | 32bit 保護モード | 9.8 |
| **Long Mode** | 64bit モード | 9.8.5 |
| **SMM** | System Management Mode | 34 |

**参照**: Intel SDM Vol.3, Section 9

#### MSR (Model-Specific Register)

主要な MSR:

| MSR | 名前 | アドレス | 説明 |
|-----|------|---------|------|
| `IA32_APIC_BASE` | APIC Base | 0x1B | APIC ベースアドレス |
| `IA32_EFER` | Extended Feature Enable | 0xC0000080 | 拡張機能有効化 |
| `IA32_MTRR_*` | MTRR | 0x2FF- | メモリタイプ設定 |
| `IA32_BIOS_SIGN_ID` | BIOS Signature | 0x8B | マイクロコードバージョン |

**参照**: Intel SDM Vol.4

#### GDT/IDT

```c
// GDT Entry
typedef struct {
  UINT16  LimitLow;
  UINT16  BaseLow;
  UINT8   BaseMid;
  UINT8   Access;
  UINT8   Granularity;
  UINT8   BaseHigh;
} GDT_ENTRY;

// IDT Entry (64bit)
typedef struct {
  UINT16  OffsetLow;
  UINT16  Selector;
  UINT8   IST;
  UINT8   Attributes;
  UINT16  OffsetMiddle;
  UINT32  OffsetHigh;
  UINT32  Reserved;
} IDT_ENTRY64;
```

**参照**: Intel SDM Vol.3, Section 3.5

---

## 📙 PCI/PCIe Specifications

### PCI Configuration Space

#### ヘッダタイプ 0 (デバイス)

| オフセット | サイズ | フィールド | 説明 |
|-----------|-------|-----------|------|
| 0x00 | 2 | Vendor ID | ベンダー ID |
| 0x02 | 2 | Device ID | デバイス ID |
| 0x04 | 2 | Command | コマンドレジスタ |
| 0x06 | 2 | Status | ステータスレジスタ |
| 0x08 | 1 | Revision ID | リビジョン ID |
| 0x09 | 3 | Class Code | クラスコード |
| 0x0C | 1 | Cache Line Size | キャッシュラインサイズ |
| 0x0D | 1 | Latency Timer | レイテンシタイマ |
| 0x0E | 1 | Header Type | ヘッダタイプ |
| 0x0F | 1 | BIST | Built-in Self Test |
| 0x10-0x24 | 4*6 | BAR0-5 | Base Address Registers |
| 0x2C | 2 | Subsystem Vendor ID | サブシステムベンダー ID |
| 0x2E | 2 | Subsystem Device ID | サブシステムデバイス ID |
| 0x3C | 1 | Interrupt Line | 割り込みライン |
| 0x3D | 1 | Interrupt Pin | 割り込みピン |

**参照**: PCI Spec 3.0, Section 6.1

### PCIe Extended Configuration Space

- **Legacy PCI**: 256 bytes (0x00-0xFF)
- **PCIe**: 4096 bytes (0x000-0xFFF)

主要な拡張ケイパビリティ:

| ID | 名前 | 説明 |
|----|------|------|
| 0x01 | Advanced Error Reporting (AER) | エラー報告 |
| 0x03 | Device Serial Number | デバイスシリアル番号 |
| 0x10 | SR-IOV | シングルルート I/O 仮想化 |
| 0x0B | Vendor-Specific | ベンダー固有 |

**参照**: PCIe Spec 5.0, Section 7.6

---

## 📓 USB Specifications

### USB 2.0

#### デバイス記述子

```c
typedef struct {
  UINT8   bLength;
  UINT8   bDescriptorType;
  UINT16  bcdUSB;
  UINT8   bDeviceClass;
  UINT8   bDeviceSubClass;
  UINT8   bDeviceProtocol;
  UINT8   bMaxPacketSize0;
  UINT16  idVendor;
  UINT16  idProduct;
  UINT16  bcdDevice;
  UINT8   iManufacturer;
  UINT8   iProduct;
  UINT8   iSerialNumber;
  UINT8   bNumConfigurations;
} USB_DEVICE_DESCRIPTOR;
```

**参照**: USB 2.0 Spec, Section 9.6.1

### USB 3.x

#### デバイスクラス

| Class | 名前 | 説明 |
|-------|------|------|
| 0x01 | Audio | オーディオデバイス |
| 0x03 | HID | Human Interface Device |
| 0x08 | Mass Storage | ストレージデバイス |
| 0x09 | Hub | USB ハブ |
| 0x0A | CDC | 通信デバイス |

**参照**: USB 3.2 Spec, Appendix D

---

## 📔 TPM 2.0 Specification

### PCR (Platform Configuration Register)

| PCR | 用途 | 説明 |
|-----|------|------|
| 0 | CRTM, BIOS | 最初のコード測定 |
| 1 | Platform Config | プラットフォーム設定 |
| 2 | Option ROM | オプション ROM |
| 3 | Option ROM Config | オプション ROM 設定 |
| 4 | MBR | マスターブートレコード |
| 5 | MBR Config | MBR 設定 |
| 6 | State Transitions | 状態遷移 |
| 7 | Vendor Specific | ベンダー固有 |

**参照**: TCG PC Client Platform Firmware Profile, Section 2.3.4

### TPM コマンド例

```c
// TPM2_PCR_Extend
TPM_RC TPM2_PCR_Extend(
  TPMI_DH_PCR     pcrHandle,  // PCR番号
  TPML_DIGEST_VALUES *digests // ハッシュ値
);

// TPM2_Quote
TPM_RC TPM2_Quote(
  TPMI_DH_OBJECT  signHandle,
  TPML_PCR_SELECTION *PCRselect,
  TPM2B_DATA      *qualifyingData,
  TPMT_SIG_SCHEME *inScheme,
  TPM2B_ATTEST    *quoted,
  TPMT_SIGNATURE  *signature
);
```

**参照**: TPM 2.0 Library Spec, Part 3

---

## 🔍 クイック検索

### よくある質問と参照先

| 質問 | 仕様書 | セクション |
|------|--------|-----------|
| UEFI アプリの書き方は？ | UEFI Spec | 2.1, 4 |
| プロトコルのインストール方法は？ | UEFI Spec | 6.3, 7.3 |
| ブートオプションの設定は？ | UEFI Spec | 3.1 |
| Secure Boot の実装は？ | UEFI Spec | 32 |
| ACPI テーブルの作り方は？ | ACPI Spec | 5 |
| PEI での初期化手順は？ | PI Spec Vol.1 | 2, 3 |
| DXE ドライバの書き方は？ | PI Spec Vol.2 | 3 |
| PCIe の列挙方法は？ | PCIe Spec | 7 |
| CPU のリセット後の動作は？ | Intel SDM Vol.3 | 9.1 |
| SMM の使い方は？ | Intel SDM Vol.3 | 34 |

---

[目次に戻る](../SUMMARY.md)
