# PCIe の仕組みとデバイス列挙

🎯 **この章で学ぶこと**
- PCIe（PCI Express）の基本アーキテクチャ
- PCIe リンクトレーニングと初期化
- コンフィギュレーション空間とアクセス方法
- デバイス列挙（Enumeration）のアルゴリズム
- BAR（Base Address Register）の割り当て
- MSI/MSI-X 割り込みの仕組み

📚 **前提知識**
- [Part III: PCH/SoC の役割と初期化](./04-pch-soc-init.md)
- PCI バスの基礎知識
- メモリマップド I/O の概念

---

## PCIe とは何か

**PCIe（PCI Express）** は、現代のコンピュータにおける標準的な高速シリアルインターフェースです。従来の PCI バス（パラレル）を置き換え、より高速で柔軟な接続を実現します。

### PCI から PCIe への進化

```mermaid
graph LR
    A[PCI<br/>1992年] --> B[PCI-X<br/>1998年]
    B --> C[PCIe 1.0<br/>2003年]
    C --> D[PCIe 2.0<br/>2007年]
    D --> E[PCIe 3.0<br/>2010年]
    E --> F[PCIe 4.0<br/>2017年]
    F --> G[PCIe 5.0<br/>2019年]
    G --> H[PCIe 6.0<br/>2022年]

    style A fill:#fcc,stroke:#333,stroke-width:2px
    style H fill:#cfc,stroke:#333,stroke-width:2px
```

**世代別スループット（x16 レーン）：**

| 世代 | 転送速度（片方向） | x1 レーン | x16 レーン | エンコーディング |
|------|-------------------|----------|-----------|----------------|
| **PCIe 1.0** | 2.5 GT/s | 250 MB/s | 4 GB/s | 8b/10b |
| **PCIe 2.0** | 5.0 GT/s | 500 MB/s | 8 GB/s | 8b/10b |
| **PCIe 3.0** | 8.0 GT/s | 985 MB/s | 15.75 GB/s | 128b/130b |
| **PCIe 4.0** | 16.0 GT/s | 1.97 GB/s | 31.5 GB/s | 128b/130b |
| **PCIe 5.0** | 32.0 GT/s | 3.94 GB/s | 63 GB/s | 128b/130b |
| **PCIe 6.0** | 64.0 GT/s | 7.88 GB/s | 126 GB/s | PAM4 |

### PCIe の階層構造

```mermaid
graph TD
    A[トランザクション層<br/>Transaction Layer] --> B[データリンク層<br/>Data Link Layer]
    B --> C[物理層<br/>Physical Layer]

    A -->|TLP| D[パケット生成/解析<br/>順序管理]
    B -->|DLLP| E[エラー検出/再送<br/>フロー制御]
    C -->|物理信号| F[電気的特性<br/>リンクトレーニング]

    style A fill:#fbb,stroke:#333,stroke-width:2px
    style B fill:#bfb,stroke:#333,stroke-width:2px
    style C fill:#bbf,stroke:#333,stroke-width:2px
```

**各層の役割：**

1. **物理層（Physical Layer）**
   - 差動ペア信号の送受信
   - クロックリカバリ
   - リンクトレーニング（速度・幅の交渉）

2. **データリンク層（Data Link Layer）**
   - CRC によるエラー検出
   - ACK/NAK による再送制御
   - フロー制御（クレジット管理）

3. **トランザクション層（Transaction Layer）**
   - TLP（Transaction Layer Packet）の生成・解析
   - アドレスルーティング
   - 順序保証

---

## PCIe トポロジ

PCIe は **ツリー構造** を形成します。

```mermaid
graph TD
    A[Root Complex<br/>ルートコンプレックス] --> B[Switch<br/>上流ポート]
    B --> C[Switch<br/>下流ポート1]
    B --> D[Switch<br/>下流ポート2]
    C --> E[Endpoint<br/>NIC]
    D --> F[Endpoint<br/>SSD]
    A --> G[Endpoint<br/>GPU]

    style A fill:#fbb,stroke:#333,stroke-width:2px
    style B fill:#bfb,stroke:#333,stroke-width:2px
    style E fill:#bbf,stroke:#333,stroke-width:2px
    style F fill:#bbf,stroke:#333,stroke-width:2px
    style G fill:#bbf,stroke:#333,stroke-width:2px
```

**コンポーネントの種類：**

| 種類 | 役割 | 例 |
|------|------|-----|
| **Root Complex (RC)** | PCIe ツリーの頂点、CPU/メモリと接続 | CPU 内蔵 PCIe コントローラ |
| **Switch** | 複数のデバイスを接続、パケット転送 | PCIe スイッチチップ |
| **Endpoint** | 末端デバイス | GPU、NIC、SSD |
| **Bridge** | PCIe と他のバス（PCI など）を接続 | PCIe-to-PCI ブリッジ |

---

## リンクトレーニングと初期化

PCIe リンクは電源投入時に **リンクトレーニング** を実行し、最適な速度と幅を決定します。

### リンクトレーニングシーケンス

```mermaid
sequenceDiagram
    participant EP as Endpoint
    participant RC as Root Complex

    Note over EP,RC: 1. Detect (検出)
    RC->>RC: 受信機検出
    EP->>EP: 受信機検出
    RC-->>EP: リンク検出

    Note over EP,RC: 2. Polling (ポーリング)
    RC->>EP: TS1 送信
    EP->>RC: TS1 送信
    RC->>EP: TS2 送信
    EP->>RC: TS2 送信

    Note over EP,RC: 3. Configuration (設定)
    RC->>EP: リンク幅交渉
    EP-->>RC: 幅確定
    RC->>EP: レーン番号割り当て

    Note over EP,RC: 4. L0 (動作状態)
    RC->>EP: データ転送可能
```

**トレーニングシーケンス（TS: Training Sequence）：**

- **TS1**: ビットロック、シンボルロック確立
- **TS2**: レーン番号の割り当て、リンク幅の最終確認

### リンク状態遷移

```mermaid
stateDiagram-v2
    [*] --> Detect
    Detect --> Polling: 受信機検出
    Polling --> Configuration: TS交換成功
    Configuration --> L0: 設定完了
    L0 --> L0s: アイドル（短時間）
    L0s --> L0: 復帰（高速）
    L0 --> L1: アイドル（長時間）
    L1 --> L0: 復帰（中速）
    L0 --> L2: 電源管理
    L2 --> L0: ウェイクアップ
```

**電源状態：**

| 状態 | 説明 | 復帰時間 | 消費電力 |
|------|------|---------|---------|
| **L0** | 通常動作 | - | 100% |
| **L0s** | スタンバイ（短時間） | < 1 μs | 70% |
| **L1** | スタンバイ（長時間） | < 10 μs | 10% |
| **L2** | 低電力 | 数百 μs | < 1% |
| **L3** | 電源 OFF | 数 ms | 0% |

---

## コンフィギュレーション空間

PCIe デバイスは **256 バイト（PCI 互換）** または **4096 バイト（PCIe 拡張）** のコンフィギュレーション空間を持ちます。

### コンフィギュレーション空間のレイアウト

```
オフセット    内容
0x000-0x03F   PCI 互換ヘッダ（64 バイト）
0x040-0x0FF   Capability リスト
0x100-0xFFF   PCIe 拡張 Capability（拡張コンフィグ空間）
```

**PCI 互換ヘッダ（Type 0）：**

| オフセット | サイズ | フィールド名 | 説明 |
|-----------|-------|-------------|------|
| 0x00 | 2 | Vendor ID | ベンダ識別子 |
| 0x02 | 2 | Device ID | デバイス識別子 |
| 0x04 | 2 | Command | コマンドレジスタ |
| 0x06 | 2 | Status | ステータスレジスタ |
| 0x08 | 1 | Revision ID | リビジョン |
| 0x09 | 3 | Class Code | クラスコード |
| 0x0C | 1 | Cache Line Size | キャッシュラインサイズ |
| 0x0D | 1 | Latency Timer | レイテンシタイマ（PCIe では未使用） |
| 0x0E | 1 | Header Type | ヘッダタイプ |
| 0x10-0x27 | 24 | BAR 0-5 | ベースアドレスレジスタ |
| 0x2C | 2 | Subsystem Vendor ID | サブシステムベンダ ID |
| 0x2E | 2 | Subsystem ID | サブシステム ID |
| 0x34 | 1 | Capabilities Pointer | Capability リスト先頭 |
| 0x3C | 1 | Interrupt Line | 割り込みライン（レガシー） |
| 0x3D | 1 | Interrupt Pin | 割り込みピン（レガシー） |

### コンフィギュレーション空間アクセス

**方法1: I/O ポート経由（レガシー、最大256バイト）**

```c
/**
  I/O ポート経由で PCI コンフィグ読み込み（レガシー）

  @param[in]  Bus       バス番号
  @param[in]  Device    デバイス番号
  @param[in]  Function  ファンクション番号
  @param[in]  Register  レジスタオフセット

  @retval 読み込んだ値
**/
UINT32
PciConfigReadLegacy (
  IN UINT8  Bus,
  IN UINT8  Device,
  IN UINT8  Function,
  IN UINT8  Register
  )
{
  UINT32 Address;

  // アドレス形成: [31: Enable] [30:24: Reserved] [23:16: Bus]
  //                [15:11: Device] [10:8: Function] [7:2: Register] [1:0: 00]
  Address = 0x80000000 |
            ((UINT32)Bus << 16) |
            ((UINT32)Device << 11) |
            ((UINT32)Function << 8) |
            (Register & 0xFC);

  IoWrite32 (0xCF8, Address);        // CONFIG_ADDRESS
  return IoRead32 (0xCFC);           // CONFIG_DATA
}
```

**方法2: MMIO 経由（推奨、4096バイト全体アクセス可能）**

```c
/**
  MMIO 経由で PCIe コンフィグ読み込み（拡張）

  @param[in]  Bus       バス番号
  @param[in]  Device    デバイス番号
  @param[in]  Function  ファンクション番号
  @param[in]  Register  レジスタオフセット（0x000-0xFFF）

  @retval 読み込んだ値
**/
UINT32
PciExpressConfigRead (
  IN UINT8   Bus,
  IN UINT8   Device,
  IN UINT8   Function,
  IN UINT16  Register
  )
{
  UINTN Address;

  // MMCONFIG ベースアドレス（ACPI MCFG テーブルから取得）
  UINTN MmconfigBase = PcdGet64 (PcdPciExpressBaseAddress); // 例: 0xE0000000

  // アドレス計算: Base + (Bus << 20) + (Device << 15) + (Function << 12) + Register
  Address = MmconfigBase |
            ((UINTN)Bus << 20) |
            ((UINTN)Device << 15) |
            ((UINTN)Function << 12) |
            Register;

  return MmioRead32 (Address);
}
```

---

## デバイス列挙（Enumeration）

**デバイス列挙** は、BIOS/UEFI が起動時に PCIe ツリーをスキャンし、すべてのデバイスを検出・設定するプロセスです。

### 列挙アルゴリズム

```mermaid
graph TD
    A[開始: Bus 0 から] --> B{デバイス存在?<br/>Vendor ID != 0xFFFF}
    B -->|No| C[次のデバイス]
    B -->|Yes| D[ヘッダタイプ確認]
    D -->|Type 0<br/>Endpoint| E[BAR 設定]
    D -->|Type 1<br/>Bridge| F[サブバス割り当て]
    F --> G[サブバス列挙<br/>再帰的]
    G --> E
    E --> H{全デバイス終了?}
    H -->|No| C
    H -->|Yes| I[終了]

    style A fill:#fbb,stroke:#333,stroke-width:2px
    style I fill:#bfb,stroke:#333,stroke-width:2px
```

### 列挙のステップ

**ステップ1: デバイス検出**

```c
/**
  PCIe バス上のデバイスをスキャン

  @param[in]  Bus  バス番号
**/
VOID
ScanPciBus (
  IN UINT8  Bus
  )
{
  UINT8   Device;
  UINT8   Function;
  UINT16  VendorId;
  UINT8   HeaderType;

  for (Device = 0; Device < 32; Device++) {
    for (Function = 0; Function < 8; Function++) {
      // Vendor ID 読み込み
      VendorId = PciRead16 (Bus, Device, Function, 0x00);

      if (VendorId == 0xFFFF) {
        // デバイス不在
        if (Function == 0) {
          break; // 次のデバイスへ
        }
        continue;
      }

      // デバイス発見
      Print (L"Found device: Bus %d, Dev %d, Func %d, VID 0x%04X\n",
             Bus, Device, Function, VendorId);

      // ヘッダタイプ確認
      HeaderType = PciRead8 (Bus, Device, Function, 0x0E);

      if ((HeaderType & 0x7F) == 0x01) {
        // Type 1: PCI-to-PCI Bridge
        EnumerateBridge (Bus, Device, Function);
      } else {
        // Type 0: Endpoint
        ConfigureDevice (Bus, Device, Function);
      }

      // マルチファンクションでない場合、Function 0 のみ
      if (Function == 0 && !(HeaderType & 0x80)) {
        break;
      }
    }
  }
}
```

**ステップ2: ブリッジの処理**

```c
/**
  PCI-to-PCI ブリッジを列挙

  @param[in]  Bus       バス番号
  @param[in]  Device    デバイス番号
  @param[in]  Function  ファンクション番号
**/
VOID
EnumerateBridge (
  IN UINT8  Bus,
  IN UINT8  Device,
  IN UINT8  Function
  )
{
  STATIC UINT8 NextBusNumber = 1;
  UINT8 SecondaryBus;

  // セカンダリバス番号を割り当て
  SecondaryBus = NextBusNumber++;

  // ブリッジ設定
  PciWrite8 (Bus, Device, Function, 0x19, SecondaryBus);    // Secondary Bus Number
  PciWrite8 (Bus, Device, Function, 0x1A, 0xFF);            // Subordinate Bus (暫定)

  // セカンダリバスをスキャン
  ScanPciBus (SecondaryBus);

  // Subordinate Bus 番号を確定
  PciWrite8 (Bus, Device, Function, 0x1A, NextBusNumber - 1);
}
```

**ステップ3: BAR（Base Address Register）の設定**

```c
/**
  デバイスの BAR を設定

  @param[in]  Bus       バス番号
  @param[in]  Device    デバイス番号
  @param[in]  Function  ファンクション番号
**/
VOID
ConfigureDevice (
  IN UINT8  Bus,
  IN UINT8  Device,
  IN UINT8  Function
  )
{
  UINT8  BarIndex;
  UINT32 BarValue;
  UINT32 BarSize;

  for (BarIndex = 0; BarIndex < 6; BarIndex++) {
    UINT8 BarOffset = 0x10 + (BarIndex * 4);

    // BAR に 0xFFFFFFFF を書き込んでサイズを測定
    PciWrite32 (Bus, Device, Function, BarOffset, 0xFFFFFFFF);
    BarValue = PciRead32 (Bus, Device, Function, BarOffset);

    if (BarValue == 0 || BarValue == 0xFFFFFFFF) {
      continue; // 未使用 BAR
    }

    // サイズ計算
    if (BarValue & 0x1) {
      // I/O BAR
      BarSize = ~(BarValue & 0xFFFFFFFC) + 1;
      UINTN IoAddress = AllocateIoSpace (BarSize);
      PciWrite32 (Bus, Device, Function, BarOffset, IoAddress | 0x1);
    } else {
      // Memory BAR
      BarSize = ~(BarValue & 0xFFFFFFF0) + 1;
      UINTN MemAddress = AllocateMemorySpace (BarSize);
      PciWrite32 (Bus, Device, Function, BarOffset, MemAddress);

      // 64-bit BAR の場合
      if ((BarValue & 0x6) == 0x4) {
        BarIndex++; // 次の BAR も使用
        PciWrite32 (Bus, Device, Function, BarOffset + 4, (UINT32)(MemAddress >> 32));
      }
    }
  }

  // Command レジスタを有効化
  UINT16 Command = PciRead16 (Bus, Device, Function, 0x04);
  Command |= 0x07; // I/O Space | Memory Space | Bus Master
  PciWrite16 (Bus, Device, Function, 0x04, Command);
}
```

---

## BAR（Base Address Register）

**BAR** は、デバイスがメモリまたは I/O 空間のどこにマップされるかを指定します。

### BAR の種類

**Memory BAR（ビット0 = 0）：**

```
[31:4]  ベースアドレス（16バイトアライン）
[3]     Prefetchable（0: No, 1: Yes）
[2:1]   Type（00: 32-bit, 10: 64-bit）
[0]     0（Memory Space）
```

**I/O BAR（ビット0 = 1）：**

```
[31:2]  ベースアドレス（4バイトアライン）
[1]     予約
[0]     1（I/O Space）
```

### BAR サイズの決定方法

1. BAR に `0xFFFFFFFF` を書き込む
2. 読み戻す
3. マスクビット（Memory: bit 4-31, I/O: bit 2-31）を反転して +1

**例：**

```
書き込み: 0xFFFFFFFF
読み戻し: 0xFFFFF000
サイズ  : ~0xFFFFF000 + 1 = 0x00001000 (4KB)
```

---

## Capability と Extended Capability

### Capability リスト（0x40-0xFF）

**Capability** は、デバイスの拡張機能を記述します。リンクリスト形式で格納されます。

```c
/**
  指定された Capability ID を検索

  @param[in]  Bus       バス番号
  @param[in]  Device    デバイス番号
  @param[in]  Function  ファンクション番号
  @param[in]  CapId     Capability ID

  @retval オフセット（見つからない場合は 0）
**/
UINT8
FindCapability (
  IN UINT8  Bus,
  IN UINT8  Device,
  IN UINT8  Function,
  IN UINT8  CapId
  )
{
  UINT16 Status;
  UINT8  CapPtr;
  UINT8  CurrentCapId;

  // Status レジスタの Capability List ビット確認
  Status = PciRead16 (Bus, Device, Function, 0x06);
  if (!(Status & 0x0010)) {
    return 0; // Capability なし
  }

  // Capability ポインタ取得
  CapPtr = PciRead8 (Bus, Device, Function, 0x34);

  // リストを走査
  while (CapPtr != 0 && CapPtr != 0xFF) {
    CurrentCapId = PciRead8 (Bus, Device, Function, CapPtr);
    if (CurrentCapId == CapId) {
      return CapPtr; // 発見
    }

    // 次の Capability へ
    CapPtr = PciRead8 (Bus, Device, Function, CapPtr + 1);
  }

  return 0; // 見つからず
}
```

**主要な Capability ID：**

| ID | 名前 | 説明 |
|----|------|------|
| 0x01 | Power Management | 電源管理 |
| 0x05 | MSI | Message Signaled Interrupts |
| 0x10 | PCIe Capability | PCIe 固有設定 |
| 0x11 | MSI-X | 拡張 MSI |

### Extended Capability（0x100-0xFFF）

PCIe 拡張 Capability は、より大きな領域を使用します。

```c
/**
  Extended Capability を検索

  @param[in]  Bus       バス番号
  @param[in]  Device    デバイス番号
  @param[in]  Function  ファンクション番号
  @param[in]  ExtCapId  Extended Capability ID

  @retval オフセット（見つからない場合は 0）
**/
UINT16
FindExtendedCapability (
  IN UINT8   Bus,
  IN UINT8   Device,
  IN UINT8   Function,
  IN UINT16  ExtCapId
  )
{
  UINT16 CapPtr = 0x100; // 拡張 Capability は 0x100 から開始
  UINT32 Header;
  UINT16 CurrentCapId;

  while (CapPtr != 0) {
    Header = PciExpressConfigRead (Bus, Device, Function, CapPtr);
    CurrentCapId = (UINT16)(Header & 0xFFFF);

    if (CurrentCapId == ExtCapId) {
      return CapPtr;
    }

    // 次のポインタ（ビット 31:20）
    CapPtr = (UINT16)((Header >> 20) & 0xFFC);
  }

  return 0;
}
```

**主要な Extended Capability ID：**

| ID | 名前 | 説明 |
|----|------|------|
| 0x0001 | AER | Advanced Error Reporting |
| 0x0002 | VC | Virtual Channel |
| 0x0003 | Serial Number | デバイスシリアル番号 |
| 0x0010 | SR-IOV | Single Root I/O Virtualization |

---

## MSI/MSI-X 割り込み

### レガシー割り込み vs MSI

**レガシー割り込み（INTx）：**
- 物理的な割り込みライン（INTA#-INTD#）
- 共有可能（複数デバイスが同じラインを使用）
- 低速（レベルトリガ）

**MSI（Message Signaled Interrupts）：**
- メモリ書き込みで割り込み通知
- 各デバイスが独立したベクタを持つ
- 高速、スケーラブル

### MSI の設定

```c
/**
  MSI を有効化

  @param[in]  Bus       バス番号
  @param[in]  Device    デバイス番号
  @param[in]  Function  ファンクション番号
  @param[in]  Vector    割り込みベクタ番号
**/
VOID
EnableMsi (
  IN UINT8  Bus,
  IN UINT8  Device,
  IN UINT8  Function,
  IN UINT8  Vector
  )
{
  UINT8  MsiCapOffset;
  UINT16 MsiControl;
  UINT32 MessageAddress;
  UINT16 MessageData;

  // MSI Capability を検索
  MsiCapOffset = FindCapability (Bus, Device, Function, 0x05);
  if (MsiCapOffset == 0) {
    return; // MSI 非サポート
  }

  // MSI Control レジスタ読み込み
  MsiControl = PciRead16 (Bus, Device, Function, MsiCapOffset + 2);

  // Message Address 設定（Local APIC ベースアドレス）
  MessageAddress = 0xFEE00000 | (0 << 12); // Destination: BSP
  PciWrite32 (Bus, Device, Function, MsiCapOffset + 4, MessageAddress);

  // Message Data 設定（割り込みベクタ）
  MessageData = Vector;
  if (MsiControl & 0x0080) {
    // 64-bit アドレス対応
    PciWrite32 (Bus, Device, Function, MsiCapOffset + 8, 0); // Upper 32-bit
    PciWrite16 (Bus, Device, Function, MsiCapOffset + 12, MessageData);
  } else {
    // 32-bit アドレス
    PciWrite16 (Bus, Device, Function, MsiCapOffset + 8, MessageData);
  }

  // MSI Enable
  MsiControl |= 0x0001;
  PciWrite16 (Bus, Device, Function, MsiCapOffset + 2, MsiControl);
}
```

### MSI-X

**MSI-X** は MSI の拡張版で、より多くの割り込みベクタ（最大 2048）をサポートします。

```c
/**
  MSI-X を有効化

  @param[in]  Bus       バス番号
  @param[in]  Device    デバイス番号
  @param[in]  Function  ファンクション番号
**/
VOID
EnableMsiX (
  IN UINT8  Bus,
  IN UINT8  Device,
  IN UINT8  Function
  )
{
  UINT8  MsixCapOffset;
  UINT16 MsixControl;
  UINT32 TableOffsetBir;
  UINT8  TableBar;
  UINT32 TableOffset;
  UINTN  TableAddress;

  // MSI-X Capability を検索
  MsixCapOffset = FindCapability (Bus, Device, Function, 0x11);
  if (MsixCapOffset == 0) {
    return;
  }

  // Table Offset/BIR 取得
  TableOffsetBir = PciRead32 (Bus, Device, Function, MsixCapOffset + 4);
  TableBar = TableOffsetBir & 0x7;           // BAR Index
  TableOffset = TableOffsetBir & 0xFFFFFFF8; // Offset

  // BAR アドレス取得
  UINT32 BarValue = PciRead32 (Bus, Device, Function, 0x10 + TableBar * 4);
  TableAddress = (BarValue & 0xFFFFFFF0) + TableOffset;

  // MSI-X Table エントリ設定（例: エントリ 0）
  MmioWrite32 (TableAddress + 0,  0xFEE00000); // Message Address Low
  MmioWrite32 (TableAddress + 4,  0x00000000); // Message Address High
  MmioWrite32 (TableAddress + 8,  0x00000030); // Message Data (Vector 0x30)
  MmioWrite32 (TableAddress + 12, 0x00000000); // Vector Control (Unmask)

  // MSI-X Enable
  MsixControl = PciRead16 (Bus, Device, Function, MsixCapOffset + 2);
  MsixControl |= 0x8000; // Enable
  MsixControl &= ~0x4000; // Function Mask = 0
  PciWrite16 (Bus, Device, Function, MsixCapOffset + 2, MsixControl);
}
```

---

## 演習問題

### 基本演習

1. **PCIe の利点**
   従来の PCI バスと比較して、PCIe の主な利点を3つ挙げてください。

2. **コンフィグ空間アクセス**
   Bus 0, Device 5, Function 0, Offset 0x10 の値を読み取るコードを、I/O ポート方式と MMIO 方式の両方で書いてください。

### 応用演習

3. **デバイス検出**
   Bus 0 上のすべてのデバイスを列挙し、Vendor ID と Device ID を表示するプログラムを作成してください。

4. **MSI 設定**
   指定されたデバイスに対して MSI を有効化し、割り込みベクタ 0x50 を設定するコードを書いてください。

### チャレンジ演習

5. **完全な列挙プログラム**
   PCIe ツリー全体を再帰的にスキャンし、すべてのデバイスとブリッジを検出・設定する完全な列挙プログラムを実装してください。

6. **ホットプラグ対応**
   PCIe ホットプラグイベント（デバイス挿入・取り外し）を検出し、動的に列挙するメカニズムを調査・実装してください。

---

## まとめ

この章では、PCIe の仕組みとデバイス列挙について学びました。

🔑 **重要なポイント：**

1. **PCIe アーキテクチャ**
   - 3層構造（物理層・データリンク層・トランザクション層）
   - ツリー型トポロジ（Root Complex → Switch → Endpoint）
   - シリアル通信、差動ペア、高速化の歴史

2. **リンクトレーニング**
   - 電源投入時に Detect → Polling → Configuration → L0
   - リンク幅（x1, x2, x4, x8, x16）と速度（Gen1-6）の交渉
   - 電源状態（L0, L0s, L1, L2）による省電力

3. **コンフィギュレーション空間**
   - PCI 互換領域（256 バイト）と PCIe 拡張領域（4096 バイト）
   - I/O ポート（0xCF8/0xCFC）または MMIO（MMCONFIG）でアクセス
   - Capability と Extended Capability によるデバイス機能記述

4. **デバイス列挙**
   - BIOS/UEFI が起動時に実行
   - Vendor ID 読み込みでデバイス検出
   - BAR 設定によりメモリ/I/O 空間割り当て
   - ブリッジは再帰的にサブバスを列挙

5. **MSI/MSI-X**
   - レガシー INTx に代わる高速割り込み機構
   - メモリ書き込みで Local APIC に通知
   - MSI-X は最大 2048 ベクタをサポート

**次章では、ACPI の目的と構造について学びます。**

---

📚 **参考資料**
- [PCI Express Base Specification](https://pcisig.com/specifications) - PCIe 仕様書（要会員登録）
- [PCI Local Bus Specification](https://pcisig.com/) - PCI 仕様書
- [Intel® PCIe Controller Documentation](https://www.intel.com/content/www/us/en/support/articles/000055661/processors.html) - Intel PCIe 実装ガイド
- [Linux Kernel PCI Subsystem](https://www.kernel.org/doc/html/latest/PCI/index.html) - Linux の PCIe 実装例
- [ACPI MCFG Table](https://uefi.org/specifications) - MMCONFIG 設定（ACPI 6.5 仕様）
