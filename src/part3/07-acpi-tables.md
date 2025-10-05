# ACPI テーブルの役割

🎯 **この章で学ぶこと**
- 主要な ACPI テーブルの詳細構造
- FADT（Fixed ACPI Description Table）の役割
- MADT（Multiple APIC Description Table）と割り込み設定
- MCFG（Memory Mapped Configuration Table）と PCIe
- その他の重要なテーブル（HPET, SRAT, SLIT, BGRT など）
- ACPI テーブルの作成と検証

📚 **前提知識**
- [Part III: ACPI の目的と構造](./06-acpi-architecture.md)
- ACPI テーブルの基本概念
- PCIe と割り込みコントローラの基礎

---

## FADT（Fixed ACPI Description Table）

**FADT**（別名 FACP）は、ACPI の中核となるテーブルで、ハードウェアの固定機能レジスタ情報と DSDT へのポインタを格納します。

### FADT の構造

```c
typedef struct {
  EFI_ACPI_DESCRIPTION_HEADER  Header;              // シグネチャ "FACP"
  UINT32  FirmwareCtrl;                             // FACS 物理アドレス (32-bit)
  UINT32  Dsdt;                                     // DSDT 物理アドレス (32-bit)
  UINT8   Reserved0;                                // ACPI 1.0 互換フィールド
  UINT8   PreferredPmProfile;                       // 推奨電源プロファイル
  UINT16  SciInt;                                   // SCI 割り込み番号
  UINT32  SmiCmd;                                   // SMI コマンドポート
  UINT8   AcpiEnable;                               // ACPI 有効化コマンド
  UINT8   AcpiDisable;                              // ACPI 無効化コマンド
  UINT8   S4BiosReq;                                // S4 BIOS 要求コマンド
  UINT8   PstateCnt;                                // P-State 制御
  UINT32  Pm1aEvtBlk;                               // PM1a Event Register Block
  UINT32  Pm1bEvtBlk;                               // PM1b Event Register Block
  UINT32  Pm1aCntBlk;                               // PM1a Control Register Block
  UINT32  Pm1bCntBlk;                               // PM1b Control Register Block
  UINT32  Pm2CntBlk;                                // PM2 Control Register Block
  UINT32  PmTmrBlk;                                 // PM Timer Register Block
  UINT32  Gpe0Blk;                                  // GPE0 Register Block
  UINT32  Gpe1Blk;                                  // GPE1 Register Block
  UINT8   Pm1EvtLen;                                // PM1 Event Register Length
  UINT8   Pm1CntLen;                                // PM1 Control Register Length
  UINT8   Pm2CntLen;                                // PM2 Control Register Length
  UINT8   PmTmrLen;                                 // PM Timer Register Length
  UINT8   Gpe0BlkLen;                               // GPE0 Block Length
  UINT8   Gpe1BlkLen;                               // GPE1 Block Length
  UINT8   Gpe1Base;                                 // GPE1 Base Offset
  UINT8   CstCnt;                                   // C-State 制御
  UINT16  PLvl2Lat;                                 // C2 レイテンシ
  UINT16  PLvl3Lat;                                 // C3 レイテンシ
  UINT16  FlushSize;                                // フラッシュサイズ
  UINT16  FlushStride;                              // フラッシュストライド
  UINT8   DutyOffset;                               // Duty サイクルオフセット
  UINT8   DutyWidth;                                // Duty サイクル幅
  UINT8   DayAlrm;                                  // RTC Day Alarm Index
  UINT8   MonAlrm;                                  // RTC Month Alarm Index
  UINT8   Century;                                  // RTC Century Index
  UINT16  IapcBootArch;                             // IA-PC Boot Architecture Flags
  UINT8   Reserved1;                                // 予約
  UINT32  Flags;                                    // Fixed Feature Flags
  EFI_ACPI_6_5_GENERIC_ADDRESS_STRUCTURE  ResetReg; // リセットレジスタ
  UINT8   ResetValue;                               // リセット値
  UINT16  ArmBootArch;                              // ARM Boot Architecture Flags
  UINT8   MinorVersion;                             // FADT マイナーバージョン
  UINT64  XFirmwareCtrl;                            // FACS 物理アドレス (64-bit)
  UINT64  XDsdt;                                    // DSDT 物理アドレス (64-bit)
  EFI_ACPI_6_5_GENERIC_ADDRESS_STRUCTURE  XPm1aEvtBlk;
  EFI_ACPI_6_5_GENERIC_ADDRESS_STRUCTURE  XPm1bEvtBlk;
  EFI_ACPI_6_5_GENERIC_ADDRESS_STRUCTURE  XPm1aCntBlk;
  EFI_ACPI_6_5_GENERIC_ADDRESS_STRUCTURE  XPm1bCntBlk;
  EFI_ACPI_6_5_GENERIC_ADDRESS_STRUCTURE  XPm2CntBlk;
  EFI_ACPI_6_5_GENERIC_ADDRESS_STRUCTURE  XPmTmrBlk;
  EFI_ACPI_6_5_GENERIC_ADDRESS_STRUCTURE  XGpe0Blk;
  EFI_ACPI_6_5_GENERIC_ADDRESS_STRUCTURE  XGpe1Blk;
  EFI_ACPI_6_5_GENERIC_ADDRESS_STRUCTURE  SleepControlReg;
  EFI_ACPI_6_5_GENERIC_ADDRESS_STRUCTURE  SleepStatusReg;
  UINT64  HypervisorVendorId;                       // ハイパーバイザベンダ ID
} EFI_ACPI_6_5_FIXED_ACPI_DESCRIPTION_TABLE;
```

### PreferredPmProfile（電源プロファイル）

| 値 | プロファイル | 説明 |
|----|------------|------|
| 0 | Unspecified | 未指定 |
| 1 | Desktop | デスクトップ |
| 2 | Mobile | モバイル（ラップトップ） |
| 3 | Workstation | ワークステーション |
| 4 | Enterprise Server | エンタープライズサーバ |
| 5 | SOHO Server | 小規模サーバ |
| 6 | Appliance PC | アプライアンス PC |
| 7 | Performance Server | パフォーマンスサーバ |
| 8 | Tablet | タブレット |

### Fixed Feature Flags

```c
#define EFI_ACPI_6_5_WBINVD                          BIT0   // WBINVD 命令サポート
#define EFI_ACPI_6_5_WBINVD_FLUSH                    BIT1   // WBINVD はキャッシュフラッシュ
#define EFI_ACPI_6_5_PROC_C1                         BIT2   // C1 サポート
#define EFI_ACPI_6_5_P_LVL2_UP                       BIT3   // C2 はマルチプロセッサで動作
#define EFI_ACPI_6_5_PWR_BUTTON                      BIT4   // 電源ボタンは制御メソッド
#define EFI_ACPI_6_5_SLP_BUTTON                      BIT5   // スリープボタンは制御メソッド
#define EFI_ACPI_6_5_FIX_RTC                         BIT6   // RTC ウェイクステータスは固定レジスタ
#define EFI_ACPI_6_5_RTC_S4                          BIT7   // RTC は S4 からウェイク可能
#define EFI_ACPI_6_5_TMR_VAL_EXT                     BIT8   // PM タイマは 32-bit
#define EFI_ACPI_6_5_DCK_CAP                         BIT9   // ドッキングサポート
#define EFI_ACPI_6_5_RESET_REG_SUP                   BIT10  // リセットレジスタサポート
#define EFI_ACPI_6_5_SEALED_CASE                     BIT11  // 密閉ケース
#define EFI_ACPI_6_5_HEADLESS                        BIT12  // ヘッドレス（ディスプレイなし）
#define EFI_ACPI_6_5_CPU_SW_SLP                      BIT13  // CPU をスリープ命令で制御
#define EFI_ACPI_6_5_PCI_EXP_WAK                     BIT14  // PCIe ウェイクイベント
#define EFI_ACPI_6_5_USE_PLATFORM_CLOCK              BIT15  // プラットフォームクロック使用
#define EFI_ACPI_6_5_S4_RTC_STS_VALID                BIT16  // S4 の RTC ステータス有効
#define EFI_ACPI_6_5_REMOTE_POWER_ON_CAPABLE         BIT17  // リモート電源 ON 可能
#define EFI_ACPI_6_5_FORCE_APIC_CLUSTER_MODEL        BIT18  // APIC クラスタモード強制
#define EFI_ACPI_6_5_FORCE_APIC_PHYSICAL_DESTINATION_MODE  BIT19  // APIC 物理モード強制
#define EFI_ACPI_6_5_HW_REDUCED_ACPI                 BIT20  // ハードウェア削減 ACPI
#define EFI_ACPI_6_5_LOW_POWER_S0_IDLE_CAPABLE       BIT21  // S0 低電力アイドル対応
```

### Generic Address Structure

ACPI 2.0+ では、レジスタアドレスを **Generic Address Structure** で表現します。

```c
typedef struct {
  UINT8   AddressSpaceId;   // 0: System Memory, 1: System I/O, 2: PCI Config, ...
  UINT8   RegisterBitWidth; // レジスタビット幅
  UINT8   RegisterBitOffset;// レジスタビットオフセット
  UINT8   AccessSize;       // アクセスサイズ (0: Undefined, 1: Byte, 2: Word, 3: Dword, 4: Qword)
  UINT64  Address;          // レジスタアドレス
} EFI_ACPI_6_5_GENERIC_ADDRESS_STRUCTURE;
```

---

## MADT（Multiple APIC Description Table）

**MADT**（別名 APIC）は、システムの割り込みコントローラ（APIC/IOAPIC/GIC）の構成を記述します。

### MADT の構造

```c
typedef struct {
  EFI_ACPI_DESCRIPTION_HEADER  Header;       // シグネチャ "APIC"
  UINT32  LocalApicAddress;                  // Local APIC ベースアドレス
  UINT32  Flags;                             // Flags (Bit 0: PCAT_COMPAT)
  // 以降、可変長の Interrupt Controller Structure が続く
} EFI_ACPI_6_5_MULTIPLE_APIC_DESCRIPTION_TABLE_HEADER;
```

**Flags:**
- Bit 0 (PCAT_COMPAT): PC-AT 互換（8259 PIC が存在）

### Interrupt Controller Structure の種類

MADT には複数の **Interrupt Controller Structure** が含まれます。

| Type | 名前 | 説明 |
|------|------|------|
| 0x00 | Processor Local APIC | CPU の Local APIC |
| 0x01 | I/O APIC | I/O APIC コントローラ |
| 0x02 | Interrupt Source Override | IRQ マッピングオーバーライド |
| 0x03 | NMI Source | NMI ソース |
| 0x04 | Local APIC NMI | Local APIC NMI 設定 |
| 0x05 | Local APIC Address Override | Local APIC アドレスオーバーライド（64-bit） |
| 0x09 | Processor Local x2APIC | x2APIC（拡張 APIC） |

### Processor Local APIC Structure

```c
typedef struct {
  UINT8   Type;              // 0x00
  UINT8   Length;            // 8
  UINT8   AcpiProcessorUid;  // ACPI Processor UID
  UINT8   ApicId;            // Local APIC ID
  UINT32  Flags;             // Bit 0: Enabled, Bit 1: Online Capable
} EFI_ACPI_6_5_PROCESSOR_LOCAL_APIC_STRUCTURE;
```

### I/O APIC Structure

```c
typedef struct {
  UINT8   Type;              // 0x01
  UINT8   Length;            // 12
  UINT8   IoApicId;          // I/O APIC ID
  UINT8   Reserved;
  UINT32  IoApicAddress;     // I/O APIC ベースアドレス
  UINT32  GlobalSystemInterruptBase;  // この I/O APIC が扱う GSI の開始番号
} EFI_ACPI_6_5_IO_APIC_STRUCTURE;
```

### Interrupt Source Override Structure

レガシー IRQ を GSI（Global System Interrupt）にマッピングします。

```c
typedef struct {
  UINT8   Type;              // 0x02
  UINT8   Length;            // 10
  UINT8   Bus;               // バス（0 = ISA）
  UINT8   Source;            // ソース IRQ
  UINT32  GlobalSystemInterrupt;  // マッピング先 GSI
  UINT16  Flags;             // Polarity と Trigger Mode
} EFI_ACPI_6_5_INTERRUPT_SOURCE_OVERRIDE_STRUCTURE;
```

**Flags:**
- Bit [1:0]: Polarity (00: Conforms to bus, 01: Active High, 11: Active Low)
- Bit [3:2]: Trigger Mode (00: Conforms to bus, 01: Edge, 11: Level)

**例: IRQ 0 (Timer) → GSI 2 にマッピング**

```c
{
  .Type = 0x02,
  .Length = 10,
  .Bus = 0,                    // ISA
  .Source = 0,                 // IRQ 0
  .GlobalSystemInterrupt = 2,  // GSI 2
  .Flags = 0x0005              // Active High, Edge-triggered
}
```

---

## MCFG（Memory Mapped Configuration Table）

**MCFG** は、PCIe の MMCONFIG（メモリマップドコンフィギュレーション空間）のベースアドレスを指定します。

### MCFG の構造

```c
typedef struct {
  EFI_ACPI_DESCRIPTION_HEADER  Header;  // シグネチャ "MCFG"
  UINT64  Reserved;
  // 以降、Base Address Allocation Structure が続く
} EFI_ACPI_6_5_MEMORY_MAPPED_CONFIGURATION_BASE_ADDRESS_TABLE_HEADER;

typedef struct {
  UINT64  BaseAddress;         // MMCONFIG ベースアドレス
  UINT16  PciSegmentGroupNumber;  // PCI セグメント番号
  UINT8   StartBusNumber;      // 開始バス番号
  UINT8   EndBusNumber;        // 終了バス番号
  UINT32  Reserved;
} EFI_ACPI_6_5_MEMORY_MAPPED_CONFIGURATION_SPACE_BASE_ADDRESS_ALLOCATION_STRUCTURE;
```

**例: セグメント 0, バス 0-255, ベースアドレス 0xE0000000**

```c
{
  .BaseAddress = 0xE0000000,
  .PciSegmentGroupNumber = 0,
  .StartBusNumber = 0,
  .EndBusNumber = 255,
  .Reserved = 0
}
```

この設定により、PCIe Config Space は以下のようにマップされます：

```
Bus 0, Device 0, Function 0, Offset 0x00: 0xE0000000
Bus 0, Device 0, Function 0, Offset 0xFF: 0xE00000FF
Bus 0, Device 1, Function 0, Offset 0x00: 0xE0008000
Bus 1, Device 0, Function 0, Offset 0x00: 0xE0100000
...
Bus 255, Device 31, Function 7, Offset 0xFFF: 0xEFFFFFFF
```

---

## HPET（High Precision Event Timer Table）

**HPET** は、高精度タイマのハードウェア情報を記述します。

### HPET の構造

```c
typedef struct {
  EFI_ACPI_DESCRIPTION_HEADER                 Header;  // シグネチャ "HPET"
  UINT32                                      EventTimerBlockId;
  EFI_ACPI_6_5_GENERIC_ADDRESS_STRUCTURE      BaseAddressLower32Bit;
  UINT8                                       HpetNumber;
  UINT16                                      MainCounterMinimumClockTickInPeriodicMode;
  UINT8                                       PageProtectionAndOemAttribute;
} EFI_ACPI_6_5_HIGH_PRECISION_EVENT_TIMER_TABLE_HEADER;
```

**EventTimerBlockId:**
- Bit [15:0]: Hardware Revision ID
- Bit [23:16]: Number of Comparators
- Bit [24]: Counter Size (0: 32-bit, 1: 64-bit)
- Bit [31:25]: Reserved

**例:**

```c
{
  .Header = {
    .Signature = SIGNATURE_32 ('H', 'P', 'E', 'T'),
    .Length = sizeof (EFI_ACPI_6_5_HIGH_PRECISION_EVENT_TIMER_TABLE_HEADER),
    .Revision = 0x01,
    .Checksum = 0,  // 自動計算
  },
  .EventTimerBlockId = 0x8086A201,  // Intel, Rev 1, 2 comparators, 64-bit
  .BaseAddressLower32Bit = {
    .AddressSpaceId = EFI_ACPI_6_5_SYSTEM_MEMORY,
    .RegisterBitWidth = 64,
    .RegisterBitOffset = 0,
    .AccessSize = EFI_ACPI_6_5_QWORD,
    .Address = 0xFED00000
  },
  .HpetNumber = 0,
  .MainCounterMinimumClockTickInPeriodicMode = 0x0080,  // 128
  .PageProtectionAndOemAttribute = 0
}
```

---

## SRAT（System Resource Affinity Table）

**SRAT** は、NUMA（Non-Uniform Memory Access）システムで、CPU とメモリの親和性を記述します。

### SRAT の構造

```c
typedef struct {
  EFI_ACPI_DESCRIPTION_HEADER  Header;  // シグネチャ "SRAT"
  UINT32  Reserved1;
  UINT64  Reserved2;
  // 以降、Affinity Structure が続く
} EFI_ACPI_6_5_SYSTEM_RESOURCE_AFFINITY_TABLE_HEADER;
```

### Processor Local APIC/SAPIC Affinity Structure

```c
typedef struct {
  UINT8   Type;              // 0x00
  UINT8   Length;            // 16
  UINT8   ProximityDomain7To0;
  UINT8   ApicId;
  UINT32  Flags;             // Bit 0: Enabled
  UINT8   LocalSapicEid;
  UINT8   ProximityDomain31To8[3];
  UINT32  ClockDomain;
} EFI_ACPI_6_5_PROCESSOR_LOCAL_APIC_SAPIC_AFFINITY_STRUCTURE;
```

### Memory Affinity Structure

```c
typedef struct {
  UINT8   Type;              // 0x01
  UINT8   Length;            // 40
  UINT32  ProximityDomain;   // NUMA ノード番号
  UINT16  Reserved1;
  UINT64  AddressBaseLow;    // メモリ範囲開始アドレス (下位)
  UINT64  AddressBaseHigh;   // メモリ範囲開始アドレス (上位)
  UINT64  LengthLow;         // メモリ範囲サイズ (下位)
  UINT64  LengthHigh;        // メモリ範囲サイズ (上位)
  UINT32  Reserved2;
  UINT32  Flags;             // Bit 0: Enabled, Bit 1: Hot Pluggable, Bit 2: Non-Volatile
} EFI_ACPI_6_5_MEMORY_AFFINITY_STRUCTURE;
```

---

## SLIT（System Locality Information Table）

**SLIT** は、NUMA ノード間の相対的な距離（レイテンシ）を記述します。

### SLIT の構造

```c
typedef struct {
  EFI_ACPI_DESCRIPTION_HEADER  Header;  // シグネチャ "SLIT"
  UINT64  NumberOfSystemLocalities;
  UINT8   Entry[1];  // N x N の行列（N = NumberOfSystemLocalities）
} EFI_ACPI_6_5_SYSTEM_LOCALITY_DISTANCE_INFORMATION_TABLE_HEADER;
```

**例: 2ノードシステム**

```
Entry[0][0] = 10  // ノード 0 → ノード 0 (自身)
Entry[0][1] = 20  // ノード 0 → ノード 1
Entry[1][0] = 20  // ノード 1 → ノード 0
Entry[1][1] = 10  // ノード 1 → ノード 1 (自身)
```

値は相対的な距離で、自ノードは通常 10、リモートノードはそれより大きい値（例: 20, 30）。

---

## BGRT（Boot Graphics Resource Table）

**BGRT** は、ブート時のロゴ画像の情報を OS に伝えます。

### BGRT の構造

```c
typedef struct {
  EFI_ACPI_DESCRIPTION_HEADER  Header;  // シグネチャ "BGRT"
  UINT16  Version;                      // バージョン（1）
  UINT8   Status;                       // Bit 0: Displayed, Bit 1-2: Orientation
  UINT8   ImageType;                    // 0: BMP
  UINT64  ImageAddress;                 // 画像データの物理アドレス
  UINT32  ImageOffsetX;                 // 画像の X オフセット
  UINT32  ImageOffsetY;                 // 画像の Y オフセット
} EFI_ACPI_6_5_BOOT_GRAPHICS_RESOURCE_TABLE;
```

**Status:**
- Bit 0: 0 = 非表示, 1 = 表示済み
- Bit [2:1]: Orientation (00: 0°, 01: 90°, 10: 180°, 11: 270°)

---

## ACPI テーブルの作成と検証

### EDK II での ACPI テーブル作成

UEFI ファームウェアは **ACPI Table Protocol** を使ってテーブルをインストールします。

```c
/**
  ACPI テーブルをインストール

  @param[in]  AcpiTable  ACPI テーブルデータ
  @param[in]  TableSize  テーブルサイズ

  @retval EFI_SUCCESS  成功
**/
EFI_STATUS
InstallAcpiTable (
  IN VOID   *AcpiTable,
  IN UINTN  TableSize
  )
{
  EFI_ACPI_TABLE_PROTOCOL  *AcpiTableProtocol;
  UINTN                    TableKey;
  EFI_STATUS               Status;

  Status = gBS->LocateProtocol (
                  &gEfiAcpiTableProtocolGuid,
                  NULL,
                  (VOID **)&AcpiTableProtocol
                  );
  if (EFI_ERROR (Status)) {
    return Status;
  }

  Status = AcpiTableProtocol->InstallAcpiTable (
                                AcpiTableProtocol,
                                AcpiTable,
                                TableSize,
                                &TableKey
                                );

  return Status;
}
```

### チェックサム計算

すべての ACPI テーブルはチェックサムを持ちます。

```c
/**
  ACPI テーブルのチェックサムを計算

  @param[in]  Table  ACPI テーブル

  @retval チェックサム値
**/
UINT8
CalculateChecksum8 (
  IN UINT8  *Table,
  IN UINTN  Length
  )
{
  UINT8  Sum = 0;
  UINTN  Index;

  for (Index = 0; Index < Length; Index++) {
    Sum = (UINT8)(Sum + Table[Index]);
  }

  return (UINT8)(0x100 - Sum);
}

// 使用例
EFI_ACPI_DESCRIPTION_HEADER *Header = (EFI_ACPI_DESCRIPTION_HEADER *)Table;
Header->Checksum = 0;
Header->Checksum = CalculateChecksum8 ((UINT8 *)Table, Header->Length);
```

### Linux での ACPI テーブルダンプ

```bash
# すべての ACPI テーブルをダンプ
sudo acpidump > acpidump.dat

# AML を逆アセンブル
sudo acpidump -b  # バイナリ出力
iasl -d *.dat     # 逆アセンブル
```

---

## 演習問題

### 基本演習

1. **FADT 読み取り**
   システムの FADT テーブルを読み取り、PreferredPmProfile と PM1a Event Block アドレスを表示するプログラムを作成してください。

2. **MADT 解析**
   MADT テーブルを解析し、システムの CPU 数と I/O APIC 数を表示するプログラムを作成してください。

### 応用演習

3. **MCFG 活用**
   MCFG テーブルから MMCONFIG ベースアドレスを取得し、Bus 0, Device 0, Function 0 の Vendor ID を読み取るコードを書いてください。

4. **カスタム SSDT 作成**
   簡単なデバイス（例: GPIO コントローラ）を記述した SSDT を ASL で作成し、コンパイルして UEFI ファームウェアに組み込んでください。

### チャレンジ演習

5. **NUMA 情報表示**
   SRAT と SLIT テーブルを解析し、NUMA ノードの構成とノード間距離を視覚化するツールを作成してください。

6. **ACPI テーブルバリデータ**
   任意の ACPI テーブルを読み込み、チェックサムとシグネチャを検証するツールを作成してください。

---

## まとめ

この章では、主要な ACPI テーブルの詳細構造と役割について学びました。

🔑 **重要なポイント：**

1. **FADT（FACP）**
   - ACPI の中核テーブル、DSDT へのポインタを保持
   - PM レジスタ、GPE レジスタのアドレス情報
   - 電源プロファイル、Fixed Feature Flags

2. **MADT（APIC）**
   - 割り込みコントローラの構成
   - Local APIC、I/O APIC、Interrupt Source Override
   - IRQ から GSI へのマッピング

3. **MCFG**
   - PCIe MMCONFIG ベースアドレス
   - セグメント、バス範囲の指定

4. **その他の重要テーブル**
   - **HPET**: 高精度タイマ
   - **SRAT/SLIT**: NUMA 構成とレイテンシ
   - **BGRT**: ブートロゴ画像

5. **テーブル作成**
   - EDK II の ACPI Table Protocol でインストール
   - チェックサムの計算と検証
   - `acpidump` と `iasl` でデバッグ

**次章では、SMBIOS と MP テーブルの役割について学びます。**

---

📚 **参考資料**
- [ACPI Specification 6.5](https://uefi.org/specifications) - ACPI 公式仕様書（各テーブルの詳細）
- [Intel® ACPI Component Architecture](https://acpica.org/) - iasl コンパイラと acpidump ツール
- [EDK II ACPI Module](https://github.com/tianocore/edk2/tree/master/MdeModulePkg/Universal/Acpi) - EDK II の ACPI 実装
- [Linux ACPI Tables](https://www.kernel.org/doc/Documentation/acpi/) - Linux での ACPI テーブル処理
- [UEFI ACPI Data Table](https://uefi.org/specifications) - UEFI Specification 付録 O
