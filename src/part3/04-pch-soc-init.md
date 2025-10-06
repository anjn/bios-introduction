# PCH/SoC の役割と初期化

🎯 **この章で学ぶこと**
- PCH（Platform Controller Hub）の役割とアーキテクチャ
- PCH サブシステム（SATA、USB、LPC、SMBus など）の初期化
- GPIO の詳細な設定方法
- 従来の PCH と最新 SoC の違い
- プラットフォーム固有の初期化シーケンス

📚 **前提知識**
- [Part III: CPU とチップセット初期化](./03-cpu-chipset-init.md)
- DMI（Direct Media Interface）の基礎
- PCIe の基本概念

---

## PCH とは何か

**PCH (Platform Controller Hub)** は、Intel プラットフォームにおける I/O コントローラの中核であり、CPU と周辺デバイスの橋渡しを担う重要なコンポーネントです。PCH は、かつてのチップセットアーキテクチャにおけるノースブリッジとサウスブリッジの機能を統合した後継チップであり、SATA、USB、LPC、SMBus、GPIO、オーディオ、ネットワークなど、多数のサブシステムを単一のチップに集約しています。現代のプラットフォームでは、CPU が直接メモリコントローラと PCIe コントローラを内蔵しているため、PCH は主に I/O デバイスの管理に特化しています。

PCH のアーキテクチャは、コンピュータシステムの進化とともに大きく変化してきました。**2000年代前半**までは、チップセットはノースブリッジとサウスブリッジという 2 つのチップで構成されていました。ノースブリッジは、CPU、メモリ、AGP (Accelerated Graphics Port) を接続し、高速なデータ転送を担当しました。サウスブリッジは、USB、SATA、LPC、PCI などの低速 I/O デバイスを管理しました。ノースブリッジとサウスブリッジは、PCI バスや専用リンクで接続されていました。**2010年代**に入ると、メモリコントローラが CPU に統合され、ノースブリッジの主要機能が CPU に吸収されました。これにより、ノースブリッジは消滅し、サウスブリッジの機能を拡張した PCH が登場しました。**現在**では、PCH が単一チップで I/O を統合し、DMI (Direct Media Interface) という高速リンクで CPU と接続されています。この進化により、システムの構成はシンプルになり、消費電力と基板面積が削減されました。

PCH は、多数のサブシステムを統合しており、それぞれが特定の役割を担っています。**SATA コントローラ**は、HDD や SSD などのストレージデバイスを管理し、AHCI (Advanced Host Controller Interface) や RAID モードをサポートします。**USB コントローラ**は、キーボード、マウス、USB メモリなどの USB デバイスを管理し、xHCI (eXtensible Host Controller Interface) によって USB 3.x をサポートします。**LPC/eSPI** は、SuperI/O、TPM (Trusted Platform Module)、BIOS Flash などのレガシーデバイスと接続します。eSPI (Enhanced SPI) は、LPC の後継として、より高速で効率的な通信を提供します。**SMBus (System Management Bus)** は、温度センサ、電圧センサ、SPD EEPROM などの低速デバイスとの通信に使用されます。**High Definition Audio** は、オーディオコーデックと接続し、スピーカーやマイクなどのオーディオデバイスをサポートします。**PCIe ルートポート**は、NIC (Network Interface Card)、追加ストレージコントローラ、拡張カードなどの PCIe デバイスを接続します。**SPI コントローラ**は、BIOS/UEFI ファームウェアが保存されている Flash ROM にアクセスします。**GPIO (General Purpose I/O)** は、汎用 I/O ピンを提供し、電源制御、LED 制御、ボタン入力などのプラットフォーム固有の信号を扱います。

PCH の初期化は、プラットフォーム全体の機能を有効化するために不可欠です。PCH の初期化は、CPU 初期化の後、デバイス列挙の前に実行されます。初期化シーケンスには、ストラップ設定の読み込み、クロック生成、電源管理の設定、各サブシステムの有効化が含まれます。Intel の FSP (Firmware Support Package) や AMD の AGESA (AMD Generic Encapsulated Software Architecture) は、これらの複雑な初期化シーケンスを抽象化し、BIOS ベンダーが容易に統合できるようにします。PCH の適切な初期化により、システムのすべての I/O デバイスが正しく動作し、OS が期待する機能が提供されます。

**補足図: PCH の歴史的変遷**

```mermaid
graph TD
    A[古いアーキテクチャ] --> B[CPU]
    B --> C[ノースブリッジ<br/>メモリコントローラ<br/>AGPなど]
    C --> D[サウスブリッジ<br/>USB/SATA/LPCなど]

    E[現代のアーキテクチャ] --> F[CPU<br/>統合メモリコントローラ<br/>PCIeコントローラ]
    F -->|DMI| G[PCH<br/>USB/SATA/LPC<br/>ネットワーク/オーディオなど]

    style C fill:#f9f,stroke:#333,stroke-width:2px
    style D fill:#f9f,stroke:#333,stroke-width:2px
    style G fill:#bbf,stroke:#333,stroke-width:2px
```

**参考表: PCH の主要機能**

| サブシステム | 役割 | 接続デバイス例 |
|-------------|------|---------------|
| **SATA コントローラ** | ストレージデバイス管理 | HDD, SSD |
| **USB コントローラ** | USB デバイス管理 | キーボード, マウス, USBメモリ |
| **LPC/eSPI** | レガシーデバイス接続 | SuperI/O, TPM, BIOS Flash |
| **SMBus** | 低速デバイス通信 | 温度センサ, SPD EEPROM |
| **High Definition Audio** | オーディオ処理 | スピーカー, マイク |
| **PCIe ルートポート** | 拡張デバイス接続 | NIC, 追加ストレージ |
| **SPI コントローラ** | Flash ROM アクセス | BIOS/UEFI ファームウェア |
| **GPIO** | 汎用 I/O 制御 | 電源制御, LED, ボタン |

---

## PCH の初期化フロー

PCH の初期化は、CPU 初期化の後、デバイス列挙の前に行われます。

### 初期化シーケンス

```mermaid
sequenceDiagram
    participant PEI as PEI Phase
    participant CPU as CPU Init PEIM
    participant PCH as PCH Init PEIM
    participant DMI as DMI Link
    participant SubSys as PCH サブシステム

    PEI->>CPU: CPU 初期化開始
    CPU->>DMI: DMI リンク確立
    DMI-->>PEI: リンク OK

    PEI->>PCH: PCH 初期化開始
    PCH->>PCH: 1. ストラップ読み込み
    PCH->>PCH: 2. クロック設定
    PCH->>PCH: 3. 電源管理設定

    PCH->>SubSys: 4. サブシステム初期化
    SubSys->>SubSys: SATA 初期化
    SubSys->>SubSys: USB 初期化
    SubSys->>SubSys: LPC/eSPI 初期化
    SubSys->>SubSys: GPIO 初期化

    SubSys-->>PCH: 初期化完了
    PCH-->>PEI: PCH 初期化完了
```

### ステップ1: ストラップ設定の読み込み

**ストラップ（Strap）** は、PCH の動作モードを決定するハードウェア設定です。SPI Flash の特定領域に格納されています。

```c
/**
  PCH ストラップを読み込む

  @retval Strap データ
**/
UINT32
ReadPchStrap (
  VOID
  )
{
  UINT32 StrapData;

  // SPI Flash の Descriptor Region からストラップを読み込み
  // アドレスは PCH 世代により異なる（例: 0x0F00）
  StrapData = MmioRead32 (PCH_SPI_BASE_ADDRESS + 0x0F00);

  // ME（Management Engine）の有効/無効
  BOOLEAN MeEnabled = (StrapData & BIT0) != 0;

  // PCIe ポート設定
  UINT8 PciePortConfig = (StrapData >> 4) & 0x7;

  return StrapData;
}
```

**主要なストラップ項目：**
- ME (Management Engine) の有効/無効
- PCIe レーン構成（x4/x2/x1）
- SATA/PCIe モード選択
- Boot BIOS Strap（SPI/LPC）

### ステップ2: クロック初期化

PCH 内部の各サブシステムに適切なクロックを供給します。

```c
/**
  PCH クロック設定
**/
VOID
ConfigurePchClocks (
  VOID
  )
{
  UINT32 ClockConfig;

  // RCRB（Root Complex Register Block）ベースアドレス
  UINTN RcrbBase = PCH_RCRB_BASE;

  // クロックゲーティング設定
  ClockConfig = MmioRead32 (RcrbBase + R_PCH_RCRB_CG);

  // 使用するデバイスのクロックを有効化
  ClockConfig |= B_PCH_RCRB_CG_SATA;  // SATA クロック ON
  ClockConfig |= B_PCH_RCRB_CG_USB;   // USB クロック ON
  ClockConfig &= ~B_PCH_RCRB_CG_AZALIA; // Audio クロック OFF（未使用）

  MmioWrite32 (RcrbBase + R_PCH_RCRB_CG, ClockConfig);

  // クロック安定化待機
  MicroSecondDelay (10);
}
```

### ステップ3: 電源管理設定

PCH の電源管理は ACPI 仕様に準拠しています。

```c
/**
  PCH 電源管理初期化
**/
VOID
InitPchPowerManagement (
  VOID
  )
{
  UINTN PmcBase = PCH_PMC_BASE_ADDRESS;

  // GEN_PMCON_A レジスタ設定
  UINT32 GenPmConA = MmioRead32 (PmcBase + R_PCH_PMC_GEN_PMCON_A);

  // RTC 電源喪失時の動作設定
  GenPmConA |= B_PCH_PMC_GEN_PMCON_A_RTC_PWR_STS;

  // AC 電源喪失後の挙動（例: 自動起動）
  GenPmConA &= ~B_PCH_PMC_GEN_PMCON_A_AFTERG3_EN; // G3 後は OFF のまま

  MmioWrite32 (PmcBase + R_PCH_PMC_GEN_PMCON_A, GenPmConA);

  // C-State 設定
  MmioWrite32 (PmcBase + R_PCH_PMC_S3_PWRGATE, 0x00);
  MmioWrite32 (PmcBase + R_PCH_PMC_S4_PWRGATE, 0x00);
}
```

---

## サブシステムの初期化

### SATA コントローラ

SATA は **AHCI（Advanced Host Controller Interface）** モードまたは **RAID** モードで動作します。

```c
/**
  SATA 初期化
**/
EFI_STATUS
InitSataController (
  VOID
  )
{
  UINTN SataBase = PCI_LIB_ADDRESS (0, 17, 0, 0); // Bus 0, Device 17, Function 0

  // SATA モード設定（AHCI）
  UINT16 SataMode = PciRead16 (SataBase + R_SATA_MAP);
  SataMode &= ~B_SATA_MAP_SMS_MASK;
  SataMode |= V_SATA_MAP_SMS_AHCI; // AHCI モード
  PciWrite16 (SataBase + R_SATA_MAP, SataMode);

  // ポート有効化
  UINT8 PortsEnabled = BIT0 | BIT1; // Port 0, 1 を有効化
  PciWrite8 (SataBase + R_SATA_PCS, PortsEnabled);

  // AHCI BAR 設定
  PciWrite32 (SataBase + R_SATA_AHCI_BAR, SATA_AHCI_BASE_ADDRESS);

  // Bus Master 有効化
  UINT16 Command = PciRead16 (SataBase + PCI_COMMAND_OFFSET);
  Command |= EFI_PCI_COMMAND_MEMORY_SPACE | EFI_PCI_COMMAND_BUS_MASTER;
  PciWrite16 (SataBase + PCI_COMMAND_OFFSET, Command);

  return EFI_SUCCESS;
}
```

**SATA モードの比較：**

| モード | 説明 | 用途 |
|--------|------|------|
| **IDE** | レガシー互換モード | 古い OS 向け（非推奨） |
| **AHCI** | 標準的な SATA モード | 一般的な用途、NCQ サポート |
| **RAID** | ハードウェア RAID | RAID 0/1/5/10 構成 |

### USB コントローラ

PCH の USB コントローラは **xHCI（USB 3.x）** と **EHCI（USB 2.0、レガシー）** があります。

```c
/**
  USB (xHCI) 初期化
**/
EFI_STATUS
InitUsbController (
  VOID
  )
{
  UINTN XhciBase = PCI_LIB_ADDRESS (0, 20, 0, 0); // Bus 0, Device 20, Function 0

  // xHCI BAR 設定
  PciWrite32 (XhciBase + R_XHCI_MEM_BASE, USB_XHCI_BASE_ADDRESS);

  // USB ポート有効化
  UINT32 PortConfig = PciRead32 (XhciBase + R_XHCI_USB2PR);
  PortConfig |= 0x0000000F; // Port 0-3 を有効化
  PciWrite32 (XhciBase + R_XHCI_USB2PR, PortConfig);

  // USB3 ポート有効化
  PortConfig = PciRead32 (XhciBase + R_XHCI_USB3PR);
  PortConfig |= 0x00000003; // Port 0-1 を有効化
  PciWrite32 (XhciBase + R_XHCI_USB3PR, PortConfig);

  // Bus Master 有効化
  UINT16 Command = PciRead16 (XhciBase + PCI_COMMAND_OFFSET);
  Command |= EFI_PCI_COMMAND_MEMORY_SPACE | EFI_PCI_COMMAND_BUS_MASTER;
  PciWrite16 (XhciBase + PCI_COMMAND_OFFSET, Command);

  return EFI_SUCCESS;
}
```

### LPC/eSPI インターフェース

**LPC（Low Pin Count）** または **eSPI（Enhanced SPI）** は、レガシーデバイスとの通信に使用されます。

```mermaid
graph LR
    A[PCH] -->|LPC/eSPI| B[Super I/O]
    A -->|LPC/eSPI| C[TPM 1.2/2.0]
    A -->|LPC/eSPI| D[EC<br/>Embedded Controller]
    A -->|LPC/eSPI| E[SIO デバイス<br/>シリアル/パラレル]

    style A fill:#bbf,stroke:#333,stroke-width:2px
```

```c
/**
  LPC 初期化
**/
VOID
InitLpcController (
  VOID
  )
{
  UINTN LpcBase = PCI_LIB_ADDRESS (0, 31, 0, 0); // Bus 0, Device 31, Function 0

  // I/O デコード範囲設定
  UINT16 LpcIoDecodeRanges =
    B_LPC_IOD_COMA_2F8 |  // COM1: 2F8h
    B_LPC_IOD_KBC_60_64 | // キーボード: 60h/64h
    B_LPC_IOD_FDD_3F0;    // FDD: 3F0h

  PciWrite16 (LpcBase + R_LPC_IOD, LpcIoDecodeRanges);

  // Generic I/O Range 設定（例: TPM 用）
  PciWrite32 (LpcBase + R_LPC_GEN1_DEC, 0x000C0681); // TPM at 0x680-0x68F

  // BIOS デコード有効化
  UINT8 BiosControl = PciRead8 (LpcBase + R_LPC_BC);
  BiosControl |= B_LPC_BC_LE; // BIOS Lock Enable
  PciWrite8 (LpcBase + R_LPC_BC, BiosControl);
}
```

**LPC vs eSPI：**

| 項目 | LPC | eSPI |
|------|-----|------|
| 信号線数 | 7本（LAD[3:0], LFRAME#, LCLK, LRESET#） | 4本（CS#, CLK, DIO[1:0]） |
| 最大速度 | 33MHz | 66MHz |
| 電圧 | 3.3V | 1.8V / 3.3V |
| 用途 | レガシー | 最新プラットフォーム |

### SMBus コントローラ

**SMBus（System Management Bus）** は、低速デバイスとの通信に使用されます。

```c
/**
  SMBus 経由で SPD を読み込む例

  @param[in]  SmbusAddress  デバイスアドレス（例: 0x50）
  @param[in]  Offset        読み込みオフセット
  @param[out] Data          読み込んだデータ

  @retval EFI_SUCCESS  成功
**/
EFI_STATUS
SmbusReadByte (
  IN  UINT8   SmbusAddress,
  IN  UINT8   Offset,
  OUT UINT8   *Data
  )
{
  UINTN SmbusBase = PCH_SMBUS_BASE_ADDRESS;

  // アドレス設定
  IoWrite8 (SmbusBase + R_SMBUS_HSTS, 0xFF); // ステータスクリア
  IoWrite8 (SmbusBase + R_SMBUS_TSA, (SmbusAddress << 1) | 0x01); // Read
  IoWrite8 (SmbusBase + R_SMBUS_HCMD, Offset);

  // コマンド実行
  IoWrite8 (SmbusBase + R_SMBUS_HCTL, V_SMBUS_HCTL_CMD_BYTE_DATA);

  // 完了待機
  UINT32 Timeout = 1000;
  while (Timeout--) {
    UINT8 Status = IoRead8 (SmbusBase + R_SMBUS_HSTS);
    if (Status & B_SMBUS_HSTS_INTR) {
      *Data = IoRead8 (SmbusBase + R_SMBUS_HD0);
      IoWrite8 (SmbusBase + R_SMBUS_HSTS, 0xFF);
      return EFI_SUCCESS;
    }
    MicroSecondDelay (10);
  }

  return EFI_TIMEOUT;
}
```

---

## GPIO の詳細設定

**GPIO（General Purpose Input/Output）** は、汎用的なデジタル信号の入出力を制御します。

### GPIO の構造

PCH の GPIO は **コミュニティ（Community）** と **グループ（Group）** に分類されます。

```mermaid
graph TD
    A[PCH GPIO] --> B[Community 0]
    A --> C[Community 1]
    A --> D[Community 2]

    B --> E[Group A<br/>GPP_A0 - GPP_A23]
    B --> F[Group B<br/>GPP_B0 - GPP_B23]

    C --> G[Group C<br/>GPP_C0 - GPP_C23]
    C --> H[Group D<br/>GPP_D0 - GPP_D23]

    D --> I[Group E<br/>GPP_E0 - GPP_E12]

    style A fill:#bbf,stroke:#333,stroke-width:2px
```

### GPIO パッドコンフィグレーション

各 GPIO ピンは **DW0（DWORD 0）** と **DW1（DWORD 1）** の2つの32ビットレジスタで設定されます。

```c
/**
  GPIO 設定構造体
**/
typedef struct {
  UINT32 PadMode      : 3;  // パッドモード（GPIO, Native Function など）
  UINT32 HostSwOwn    : 1;  // 所有権（ACPI/Driver）
  UINT32 Direction    : 1;  // 方向（Input/Output）
  UINT32 OutputState  : 1;  // 出力値（Low/High）
  UINT32 InterruptCfg : 3;  // 割り込み設定
  UINT32 ResetConfig  : 2;  // リセット時の動作
  UINT32 TermConfig   : 4;  // 終端抵抗（Pull-up/Pull-down）
  UINT32 Reserved     : 17;
} GPIO_CONFIG_DW0;

/**
  GPIO を出力モードに設定

  @param[in]  GpioPad   GPIO 番号（例: GPP_A0）
  @param[in]  Level     出力レベル（0 or 1）
**/
VOID
GpioSetOutputValue (
  IN UINT32  GpioPad,
  IN UINT32  Level
  )
{
  UINT32 Community = GPIO_GET_COMMUNITY (GpioPad);
  UINT32 Group = GPIO_GET_GROUP (GpioPad);
  UINT32 PadNumber = GPIO_GET_PAD_NUMBER (GpioPad);

  // GPIO ベースアドレス取得
  UINTN GpioBase = GetGpioCommunityBase (Community);
  UINTN PadCfgOffset = (Group * 0x400) + (PadNumber * 0x10);

  // DW0 設定
  UINT32 PadCfgDw0 = MmioRead32 (GpioBase + PadCfgOffset);

  PadCfgDw0 &= ~(0x7 << 0);    // パッドモードクリア
  PadCfgDw0 |= (0x0 << 0);     // GPIO モード

  PadCfgDw0 |= (1 << 8);       // Direction = Output

  if (Level) {
    PadCfgDw0 |= (1 << 9);     // Output = High
  } else {
    PadCfgDw0 &= ~(1 << 9);    // Output = Low
  }

  MmioWrite32 (GpioBase + PadCfgOffset, PadCfgDw0);
}
```

### GPIO の典型的な用途

| GPIO | 用途例 |
|------|--------|
| **GPP_A0** | PCIe CLKREQ# |
| **GPP_B5** | SSD 電源制御 |
| **GPP_C6** | LED 制御 |
| **GPP_D9** | ボタン入力 |
| **GPP_E7** | TPM 割り込み |

---

## 従来の PCH と最新 SoC の違い

### ディスクリート PCH（従来型）

```mermaid
graph TD
    A[CPU Package] -->|DMI| B[PCH Package]
    B --> C[SATA]
    B --> D[USB]
    B --> E[LPC/eSPI]
    B --> F[PCIe]

    style A fill:#bbf,stroke:#333,stroke-width:2px
    style B fill:#bfb,stroke:#333,stroke-width:2px
```

**特徴：**
- CPU と PCH が別チップ
- DMI 経由で接続（PCIe x4 相当）
- デスクトップ・サーバ向け

### SoC（System on Chip）統合型

```mermaid
graph TD
    A[SoC Package] --> B[CPU Cores]
    A --> C[GPU]
    A --> D[PCH 機能統合]
    D --> E[SATA]
    D --> F[USB]
    D --> G[LPC/eSPI]
    D --> H[PCIe]

    style A fill:#fbf,stroke:#333,stroke-width:2px
```

**特徴：**
- CPU、GPU、PCH 機能が1チップ
- DMI レス（内部バス接続）
- モバイル・組み込み向け
- 低消費電力

### アーキテクチャ比較

| 項目 | ディスクリート PCH | SoC 統合 |
|------|-------------------|----------|
| **パッケージ数** | 2個（CPU + PCH） | 1個 |
| **接続** | DMI（PCIe x4） | 内部バス |
| **レイテンシ** | 高い | 低い |
| **消費電力** | 高い | 低い |
| **コスト** | 高い | 低い |
| **拡張性** | 高い | 限定的 |
| **主な用途** | デスクトップ、サーバ | モバイル、組み込み |

---

## プラットフォーム固有の初期化

### Intel プラットフォーム（FSP 使用）

```c
/**
  FSP SiliconInit による PCH 初期化
**/
EFI_STATUS
CallFspSiliconInit (
  VOID
  )
{
  FSP_INFO_HEADER   *FspHeader;
  FSPS_UPD          *FspsUpd;

  // FSP-S (Silicon Init) ヘッダ取得
  FspHeader = GetFspSInfoHeader ();

  // UPD（Updatable Product Data）設定
  FspsUpd = GetFspsUpdDataPointer (FspHeader);

  // SATA 設定
  FspsUpd->FspsConfig.SataEnable = 1;
  FspsUpd->FspsConfig.SataMode = 0; // AHCI
  FspsUpd->FspsConfig.SataPortsEnable[0] = 1;
  FspsUpd->FspsConfig.SataPortsEnable[1] = 1;

  // USB 設定
  FspsUpd->FspsConfig.EnableXhci = 1;
  FspsUpd->FspsConfig.PortUsb20Enable[0] = 1;
  FspsUpd->FspsConfig.PortUsb30Enable[0] = 1;

  // PCIe ルートポート設定
  FspsUpd->FspsConfig.PcieRpEnable[0] = 1;
  FspsUpd->FspsConfig.PcieRpEnable[1] = 1;

  // FSP SiliconInit 実行
  EFI_STATUS Status = CallFspSiliconInit (FspsUpd);

  return Status;
}
```

### AMD プラットフォーム（AGESA 使用）

AMD プラットフォームでは **AGESA（AMD Generic Encapsulated Software Architecture）** が同様の役割を果たします。

```c
/**
  AGESA による FCH（Fusion Controller Hub）初期化
**/
VOID
InitializeFch (
  VOID
  )
{
  FCH_INTERFACE FchInterface;

  // FCH パラメータ設定
  FchInterface.SataEnable = TRUE;
  FchInterface.SataMode = 0; // AHCI
  FchInterface.Usb.Xhci0Enable = TRUE;
  FchInterface.Usb.Xhci1Enable = FALSE;

  // AGESA FCH 初期化呼び出し
  AgesaFchInit (&FchInterface);
}
```

---

## 💡 コラム: AMD AGESA: Intel FSP に対抗するプラットフォーム初期化フレームワーク

🏢 **ベンダー固有の話**

AMD AGESA（AMD Generic Encapsulated Software Architecture）は、Intel FSP と同様に、プラットフォーム初期化の複雑さを BIOS ベンダーから隠蔽するためのフレームワークです。本章で学んだ Intel FSP が PCH の初期化を担当するように、AGESA は AMD プラットフォームの FCH（Fusion Controller Hub）、メモリ、CPU、そして Infinity Fabric の初期化を担当します。AGESA の最大の目的は、チップセット設計の詳細を抽象化し、BIOS ベンダー（AMI、Phoenix、Insyde など）が容易にプラットフォームをサポートできるようにすることです。これにより、AMD は新しいプロセッサやチップセットを市場に投入する際、BIOS ベンダーが迅速に対応でき、エコシステム全体の開発効率が向上します。

AGESA の歴史は、2000年代半ばの AMD K8（Athlon 64）時代にさかのぼります。当時、AMD はデスクトップ、サーバ（Opteron）、モバイルといった多様なプラットフォームに対応する必要がありました。各プラットフォームは異なるメモリ構成、異なる HyperTransport 接続、異なるチップセットを持っており、BIOS ベンダーがこれらすべてをゼロから実装するのは非常に困難でした。そこで、AMD は AGESA という共通の初期化フレームワークを開発し、プラットフォーム固有の複雑な初期化処理を AGESA に集約しました。BIOS ベンダーは、AGESA を呼び出すだけで、メモリトレーニングや CPU の起動といった複雑な処理を実行できるようになりました。この設計により、AMD プラットフォームの BIOS 開発期間が大幅に短縮され、新しいプロセッサの市場投入が加速しました。

AGESA は、複数のコンポーネントで構成されています。まず、**Memory Initialization** は、DRAM のトレーニング（最適なタイミング設定の探索）と初期化を担当します。DDR メモリは、電圧、周波数、タイミングパラメータが複雑に絡み合っており、各メモリモジュールに対して最適な設定を見つける必要があります。AGESA は、SPD EEPROM からメモリの仕様を読み取り、数百から数千のパラメータ組み合わせをテストして、最適な設定を決定します。次に、**CPU Initialization** は、マルチコアの起動、マイクロコードの更新、P-state/C-state の設定を行います。AMD の CPU は、最大 64 コア（EPYC）を持つため、各コアを適切に起動し、電源管理を設定する必要があります。さらに、**FCH Initialization** は、Fusion Controller Hub（AMD 版の PCH）を初期化し、SATA、USB、LPC、GPIO などのサブシステムを設定します。最後に、**HyperTransport/Infinity Fabric** の設定は、CPU 間（マルチソケットサーバ）や CPU-FCH 間の高速接続を初期化します。Infinity Fabric は、Zen アーキテクチャで導入された新しい接続技術であり、CPU コア、キャッシュ、メモリコントローラ、I/O コントローラをすべて接続します。

UEFI の普及に伴い、AMD は **AGESA PI（Platform Initialization）** という新しいバージョンを開発しました。AGESA PI は、UEFI PI（Platform Initialization）仕様に準拠し、PEI Module（PEIM）として EDK II に統合できるように設計されています。従来の AGESA は独自の API とデータ構造を持っていましたが、AGESA PI は UEFI 標準の PPI（PEIM-to-PEIM Interface）と HOB（Hand-Off Block）を使用します。これにより、EDK II ベースの BIOS に AGESA を統合することが容易になり、UEFI エコシステムとの親和性が向上しました。AGESA PI は、内部的には従来の AGESA のコアロジックを使用しつつ、外部インターフェースを UEFI PI に準拠させるラッパー層を提供しています。

AGESA のもう一つの興味深い側面は、**オープンソースとプロプライエタリのバランス**です。Intel FSP は完全にバイナリのみで提供され、ソースコードは公開されていません。一方、AMD は coreboot コミュニティとの協力により、AGESA の一部をオープンソース化しています。coreboot で AMD プラットフォームをサポートする場合、AGESA はバイナリブロブとして統合されますが、そのインターフェースと統合方法は公開されています。AMD は、PSP（Platform Security Processor）ファームウェアやチップセット初期化の一部を非公開としていますが、メモリ初期化やCPU 初期化の一部は公開することで、コミュニティの貢献を受け入れています。この選択的オープンソース化により、AMD はセキュリティと知的財産を保護しつつ、オープンソースコミュニティとの協力関係を維持しています。

AMD Ryzen および EPYC 世代では、**AGESA v5（Combo PI）** が導入されました。Combo PI は、複数世代の Zen アーキテクチャ（Zen、Zen+、Zen 2、Zen 3）を単一の AGESA で対応できるように設計されています。これにより、マザーボードベンダーは、BIOS 更新により新しい Ryzen プロセッサをサポートできるようになりました。実際、Ryzen プラットフォームでは、AGESA の更新が頻繁に行われ、メモリ互換性の向上（新しい DDR4 モジュールのサポート）、CPU 互換性の向上（新しい Ryzen 5000 シリーズのサポート）、パフォーマンスの向上（メモリタイミングの最適化、ブースト動作の改善）が提供されます。ユーザーがマザーボードベンダーのウェブサイトから BIOS 更新をダウンロードする際、その更新内容に「AGESA 1.2.0.3 に更新」といった記載を見ることがありますが、これはまさに AGESA の新しいバージョンが含まれていることを意味します。

本章で学んだ FCH の初期化（SATA、USB、LPC、GPIO など）は、AGESA が提供する機能のごく一部です。AGESA は、これらの I/O サブシステムだけでなく、メモリトレーニング、CPU マルチコア起動、Infinity Fabric 設定、電源管理など、プラットフォーム全体の初期化を担当します。プラットフォーム開発者にとって、Intel プラットフォームでは FSP の理解が必須であり、AMD プラットフォームでは AGESA の理解が必須です。両者は異なるアーキテクチャと設計思想を持ちますが、「複雑なプラットフォーム初期化を抽象化し、BIOS ベンダーの負担を軽減する」という共通の目的を持っています。FSP と AGESA の存在により、現代の複雑な x86 プラットフォームが、多数の BIOS ベンダーによってサポートされ、エコシステム全体が健全に機能しているのです。

**参考表: Intel FSP vs AMD AGESA**

| 項目 | Intel FSP | AMD AGESA |
|------|-----------|-----------|
| **提供形態** | バイナリのみ | 選択的オープンソース |
| **対応アーキテクチャ** | x86_64 (Intel) | x86_64 (AMD) |
| **主な初期化** | PCH、メモリ、CPU | FCH、メモリ、CPU、Infinity Fabric |
| **UEFI PI 準拠** | あり (FSP 2.x) | あり (AGESA PI) |
| **coreboot 対応** | あり (バイナリ) | あり (バイナリ) |
| **更新頻度** | BIOS 更新 | BIOS 更新（頻繁） |
| **オープンソース度** | なし | 一部公開 |

**参考資料**:
- [coreboot AGESA Integration](https://doc.coreboot.org/vendorcode/amd/agesa/index.html)
- [UEFI PI (Platform Initialization) Specification](https://uefi.org/specifications)
- AMD Ryzen AGESA Release Notes（マザーボードベンダーのBIOS更新ページ）
- "AMD AGESA and coreboot" - Open Source Firmware Conference talks

---

## 演習問題

### 基本演習

1. **PCH の役割**
   従来のサウスブリッジと PCH の違いを説明してください。

2. **SATA モード**
   AHCI モードと IDE モードの違いを、OS サポートの観点から述べてください。

### 応用演習

3. **GPIO 設定**
   GPP_C6 を出力モードに設定し、LED を点滅させるコードを書いてください。

4. **SMBus 読み込み**
   SMBus 経由で温度センサ（アドレス 0x48）から温度を読み取るコードを書いてください。

### チャレンジ演習

5. **PCH 診断ツール**
   PCH のすべてのサブシステムの状態（有効/無効、設定値）を表示する UEFI アプリケーションを作成してください。

6. **SoC 統合の影響**
   ディスクリート PCH から SoC 統合に移行する際のファームウェア設計上の変更点を調査してください。

---

## まとめ

この章では、PCH (Platform Controller Hub) と SoC の役割、初期化方法、そしてアーキテクチャの進化について詳しく学びました。PCH は、Intel プラットフォームにおける I/O コントローラの中核であり、かつてのノースブリッジとサウスブリッジの機能を統合した後継チップです。PCH は、SATA、USB、LPC、SMBus、GPIO、オーディオ、ネットワークなど、多数のサブシステムを単一のチップに集約し、DMI (Direct Media Interface) 経由で CPU と接続されます。現代のプラットフォームでは、CPU が直接メモリコントローラと PCIe コントローラを内蔵しているため、PCH は主に I/O デバイスの管理に特化しています。

**PCH の初期化シーケンス**は、複数のステップで構成されます。まず、ストラップ設定を読み込み、PCH の動作モードを決定します。ストラップは、基板上のジャンパやレジスタで設定され、SATA モード (AHCI/RAID)、GPIO のデフォルト設定、起動デバイスの優先順位などを定義します。次に、クロック生成を設定し、BCLK、PCIe Clock、USB Clock、SATA Clock などの各種クロックを生成します。その後、電源管理を設定し、ACPI PM1 レジスタ、GPE レジスタ、TCO レジスタを初期化します。最後に、各サブシステムを初期化し、SATA、USB、LPC/eSPI、SMBus、GPIO、オーディオ、ネットワークなどを有効化します。Intel の FSP (Firmware Support Package) や AMD の AGESA (AMD Generic Encapsulated Software Architecture) は、これらの複雑な初期化シーケンスを抽象化し、BIOS ベンダーが容易に統合できるようにします。

**主要サブシステム**の役割と初期化方法を理解することは、プラットフォーム開発において重要です。**SATA コントローラ**は、AHCI (Advanced Host Controller Interface) モードまたは RAID モードでストレージデバイスを管理します。AHCI モードは、OS が直接 SATA デバイスを制御でき、ホットプラグや NCQ (Native Command Queuing) をサポートします。RAID モードは、複数のドライブを冗長化またはストライピングでき、データの保護とパフォーマンスの向上を実現します。**USB コントローラ**は、xHCI (eXtensible Host Controller Interface) によって USB 3.x をサポートします。xHCI は、USB 3.x、2.0、1.1 のすべてを単一のコントローラでサポートし、メモリ効率と低レイテンシを実現します。**LPC/eSPI** は、SuperI/O、TPM、BIOS Flash などのレガシーデバイスと接続します。eSPI (Enhanced SPI) は、LPC の後継として、より高速で効率的な通信を提供し、ピン数を削減します。**SMBus (System Management Bus)** は、温度センサ、電圧センサ、SPD EEPROM などの低速デバイスとの通信に使用されます。SMBus は、I2C プロトコルのサブセットであり、100 kHz の低速クロックで動作します。**GPIO (General Purpose I/O)** は、汎用 I/O ピンを提供し、電源制御、LED 制御、ボタン入力などのプラットフォーム固有の信号を扱います。GPIO は、パッドコンフィグによって詳細に設定でき、モード (GPIO/Native)、方向 (Input/Output)、プルアップ/プルダウン、出力状態、割り込み設定などを制御できます。

**アーキテクチャの進化**は、プラットフォームの要件に応じて異なる方向に進んでいます。**ディスクリート PCH** は、拡張性を重視したアーキテクチャであり、デスクトップやサーバで使用されます。ディスクリート PCH は、CPU とは別のチップとして実装され、DMI で接続されます。このアーキテクチャの利点は、多数の PCIe レーン、SATA ポート、USB ポートを提供でき、拡張カードやストレージデバイスを多数接続できることです。一方、**SoC 統合** は、省電力と小型化を重視したアーキテクチャであり、モバイルや組み込みデバイスで使用されます。SoC 統合では、PCH の機能が CPU チップに統合され、単一のチップで CPU、メモリコントローラ、PCIe コントローラ、I/O コントローラのすべてを提供します。このアーキテクチャの利点は、消費電力の削減、基板面積の削減、システムコストの削減です。AMD の Ryzen や Intel の Atom などは、SoC 統合アーキテクチャを採用しています。どちらのアーキテクチャを選択するかは、プラットフォームの要件 (拡張性 vs 省電力、デスクトップ vs モバイル) によって決まります。

---

📚 **参考資料**
- [Intel® PCH Datasheet](https://www.intel.com/content/www/us/en/products/docs/chipsets/datasheet.html) - PCH の詳細仕様
- [AHCI Specification](https://www.intel.com/content/dam/www/public/us/en/documents/technical-specifications/serial-ata-ahci-spec-rev1-3-1.pdf) - SATA AHCI 仕様書
- [USB xHCI Specification](https://www.intel.com/content/www/us/en/io/universal-serial-bus/extensible-host-controler-interface-usb-xhci.html) - USB 3.x ホストコントローラ仕様
- [Intel® GPIO Usage Guide](https://www.intel.com/content/www/us/en/support/programmable/support-resources/configuration/cfg-gpio.html) - GPIO 設定ガイド
- [eSPI Specification](https://www.intel.com/content/www/us/en/support/articles/000020952/intel-nuc.html) - Enhanced SPI 仕様
