# ストレージスタックの構造

🎯 **この章で学ぶこと**
- UEFI ストレージスタックの階層構造と各層の役割
- Block I/O Protocol と Disk I/O Protocol の違い
- パーティション検出とファイルシステムの仕組み
- NVMe、AHCI、USB などデバイス別ドライバの構成

📚 **前提知識**
- [Part II: プロトコルとドライバモデルの理解](03-protocol-and-driver-model.md)
- [Part II: ハードウェア抽象化の仕組み](05-hardware-abstraction.md)

---

## ストレージスタックの全体像

### なぜ階層化が必要なのか

ストレージデバイスには、HDD、SSD、NVMe SSD、USB フラッシュドライブなど、多様な種類があります。これらのデバイスは、それぞれ異なる特性と要求を持っています。HDD は回転するディスクにデータを記録し、SATA インターフェースを使用します。SSD はフラッシュメモリにデータを記録し、SATA または PCIe インターフェースを使用します。NVMe SSD は、PCIe インターフェースに最適化された高速なストレージデバイスです。USB フラッシュドライブは、USB インターフェースを通じて接続されるポータブルなストレージです。

さらに、これらのストレージデバイスは、異なるパーティションスキームと異なるファイルシステムを使用します。パーティションスキームには、MBR (Master Boot Record) と GPT (GUID Partition Table) があり、それぞれ異なる方法でディスクをパーティション分割します。ファイルシステムには、FAT32、exFAT、NTFS などがあり、それぞれ異なる方法でファイルとディレクトリを管理します。このような多様性により、ストレージデバイスへのアクセスは極めて複雑になります。

UEFI では、これらの多様性を**階層的なプロトコルスタック**で抽象化し、上位層が下位層の詳細を意識せずに動作できるようにしています。階層的なスタックにより、各層は明確な責務を持ち、下位層が提供する抽象化の上に構築されます。最下層は、物理的なストレージデバイスへの低レベルアクセスを提供し、中間層は、パーティション管理とディスク I/O の抽象化を提供し、最上層は、ファイルシステムレベルのアクセスを提供します。この設計により、アプリケーションは、ストレージデバイスの種類やパーティションスキーム、ファイルシステムを意識することなく、統一的なインターフェースでファイルにアクセスできます。

階層化の利点は、複数の側面から説明できます。まず、**抽象化による簡潔性**です。上位層は、下位層の複雑な実装詳細を知る必要がなく、シンプルなインターフェースを通じてアクセスできます。次に、**再利用性**です。各層のドライバは、他の層から独立しており、異なるストレージデバイスやファイルシステムで再利用できます。さらに、**拡張性**です。新しいストレージデバイスやファイルシステムのサポートは、対応する層にドライバを追加するだけで実現でき、他の層への影響はありません。最後に、**保守性**です。各層の責務が明確に分離されているため、バグ修正や機能追加が容易になります。

```mermaid
graph TB
    subgraph "アプリケーション層"
        APP[UEFI アプリ/OS ローダ]
    end

    subgraph "ファイルシステム層"
        SFS[Simple File System Protocol]
        FAT[FAT ドライバ]
    end

    subgraph "パーティション層"
        PART[Partition Driver]
        GPT[GPT/MBR 検出]
    end

    subgraph "ディスク抽象化層"
        DISK_IO[Disk I/O Protocol]
        BLOCK_IO[Block I/O Protocol]
    end

    subgraph "デバイスドライバ層"
        NVME[NVMe Driver]
        AHCI[AHCI Driver]
        USB_MS[USB Mass Storage]
    end

    subgraph "ハードウェア層"
        HW[ストレージデバイス]
    end

    APP --> SFS
    SFS --> FAT
    FAT --> DISK_IO
    FAT --> BLOCK_IO
    BLOCK_IO --> PART
    PART --> GPT
    GPT --> BLOCK_IO
    BLOCK_IO --> NVME
    BLOCK_IO --> AHCI
    BLOCK_IO --> USB_MS
    NVME --> HW
    AHCI --> HW
    USB_MS --> HW

    style SFS fill:#e1f5ff
    style BLOCK_IO fill:#fff4e1
    style DISK_IO fill:#e1ffe1
    style PART fill:#f0e1ff
```

---

## Block I/O Protocol

### Block I/O Protocol の役割

**`EFI_BLOCK_IO_PROTOCOL`** は、ストレージデバイスへの**ブロック単位のアクセス**を提供する最も基本的なプロトコルです。

### プロトコル定義

```c
typedef struct _EFI_BLOCK_IO_PROTOCOL {
  UINT64                    Revision;
  EFI_BLOCK_IO_MEDIA        *Media;
  EFI_BLOCK_RESET           Reset;
  EFI_BLOCK_READ            ReadBlocks;
  EFI_BLOCK_WRITE           WriteBlocks;
  EFI_BLOCK_FLUSH           FlushBlocks;
} EFI_BLOCK_IO_PROTOCOL;
```

### 各メソッドの役割

| メソッド | 役割 | パラメータ |
|---------|------|-----------|
| **Reset** | デバイスをリセット | ExtendedVerification |
| **ReadBlocks** | 指定ブロックを読み込み | LBA, BufferSize, Buffer |
| **WriteBlocks** | 指定ブロックに書き込み | LBA, BufferSize, Buffer |
| **FlushBlocks** | 書き込みキャッシュをフラッシュ | なし |

### Media 構造体

```c
typedef struct {
  UINT32  MediaId;              // メディア変更検出用 ID
  BOOLEAN RemovableMedia;       // リムーバブルメディアか
  BOOLEAN MediaPresent;         // メディアが存在するか
  BOOLEAN LogicalPartition;     // 論理パーティションか（物理デバイスでないか）
  BOOLEAN ReadOnly;             // 読み取り専用か
  BOOLEAN WriteCaching;         // 書き込みキャッシュが有効か
  UINT32  BlockSize;            // ブロックサイズ（バイト）
  UINT32  IoAlign;              // バッファアライメント要件
  EFI_LBA LastBlock;            // 最後のブロック番号
  EFI_LBA LowestAlignedLba;     // アライメント境界の開始 LBA
  UINT32  LogicalBlocksPerPhysicalBlock; // 物理ブロックあたりの論理ブロック数
  UINT32  OptimalTransferLengthGranularity; // 最適転送サイズ
} EFI_BLOCK_IO_MEDIA;
```

### ReadBlocks の動作

```mermaid
sequenceDiagram
    participant APP as アプリケーション
    participant BIO as Block I/O Protocol
    participant DRV as ストレージドライバ
    participant HW as ハードウェア

    APP->>BIO: ReadBlocks(LBA=100, Size=4096, Buffer)
    BIO->>DRV: LBA 変換、コマンド生成
    DRV->>HW: READ コマンド送信
    HW->>HW: ディスク読み取り
    HW-->>DRV: データ転送
    DRV-->>BIO: Buffer にコピー
    BIO-->>APP: EFI_SUCCESS
```

**LBA (Logical Block Address)**: 論理ブロックアドレス。0 から始まる連続した番号でブロックを指定します。

---

## Disk I/O Protocol

### Disk I/O Protocol の役割

**`EFI_DISK_IO_PROTOCOL`** は、Block I/O Protocol の上に構築され、**バイト単位のアクセス**を可能にします。

### なぜ Disk I/O が必要なのか

Block I/O Protocol はブロック単位（通常 512 バイトまたは 4096 バイト）でしかアクセスできません。しかし、ファイルシステムドライバなどは、**任意のオフセットから任意のサイズ**でデータを読み書きしたい場合があります。

```mermaid
graph LR
    subgraph "Disk I/O Protocol"
        DISKIO[任意オフセット・サイズ]
    end

    subgraph "内部処理"
        ALIGN[アライメント調整]
        RMW[Read-Modify-Write]
    end

    subgraph "Block I/O Protocol"
        BLOCKIO[ブロック境界アクセス]
    end

    DISKIO --> ALIGN
    ALIGN --> RMW
    RMW --> BLOCKIO

    style DISKIO fill:#e1f5ff
    style ALIGN fill:#fff4e1
    style RMW fill:#fff4e1
    style BLOCKIO fill:#e1ffe1
```

### プロトコル定義

```c
typedef struct _EFI_DISK_IO_PROTOCOL {
  UINT64              Revision;
  EFI_DISK_READ       ReadDisk;
  EFI_DISK_WRITE      WriteDisk;
} EFI_DISK_IO_PROTOCOL;
```

### ReadDisk vs ReadBlocks

| 項目 | Block I/O: ReadBlocks | Disk I/O: ReadDisk |
|------|----------------------|-------------------|
| **単位** | ブロック（512B/4096B） | バイト |
| **オフセット** | LBA（ブロック番号） | バイトオフセット |
| **サイズ制限** | ブロックサイズの倍数 | 任意 |
| **内部動作** | 直接ハードウェアアクセス | 必要に応じて RMW |

**RMW (Read-Modify-Write)**: ブロック境界に揃っていない書き込みの場合、まず該当ブロックを読み込み、必要部分だけ変更してから書き戻す操作。

---

## パーティション検出の仕組み

### Partition Driver の役割

**Partition Driver** は、物理ディスク上の**パーティションテーブル（GPT または MBR）を解析**し、各パーティションを個別の Block I/O Protocol インスタンスとして公開します。

```mermaid
graph TB
    subgraph "物理ディスク"
        DISK[Block I/O: 物理デバイス<br/>MediaId=1, LogicalPartition=FALSE]
    end

    subgraph "Partition Driver"
        PART_DRV[パーティションテーブル解析]
    end

    subgraph "論理パーティション"
        PART1[Block I/O: Partition 1<br/>MediaId=2, LogicalPartition=TRUE<br/>LBA 0 → 物理 LBA 2048]
        PART2[Block I/O: Partition 2<br/>MediaId=3, LogicalPartition=TRUE<br/>LBA 0 → 物理 LBA 206848]
    end

    DISK --> PART_DRV
    PART_DRV --> PART1
    PART_DRV --> PART2

    style DISK fill:#e1f5ff
    style PART_DRV fill:#fff4e1
    style PART1 fill:#e1ffe1
    style PART2 fill:#e1ffe1
```

### GPT vs MBR

| 項目 | MBR (Master Boot Record) | GPT (GUID Partition Table) |
|------|--------------------------|----------------------------|
| **最大パーティション数** | 4（プライマリ） | 128（標準設定） |
| **最大ディスクサイズ** | 2 TB | 9.4 ZB（実質無制限） |
| **パーティション識別** | Type Code（1バイト） | Type GUID（128ビット） |
| **冗長性** | なし | ヘッダとテーブルの複製 |
| **UEFI サポート** | レガシー互換 | 推奨 |

### パーティション検出の流れ

```mermaid
sequenceDiagram
    participant DXE as DXE Dispatcher
    participant PART as Partition Driver
    participant BIO as Block I/O (物理)
    participant FS as File System Driver

    DXE->>PART: DriverBindingSupported()
    PART->>BIO: Media->LogicalPartition?
    BIO-->>PART: FALSE（物理デバイス）
    PART-->>DXE: EFI_SUCCESS

    DXE->>PART: DriverBindingStart()
    PART->>BIO: ReadBlocks(LBA=1, ...) // GPT ヘッダ
    BIO-->>PART: GPT データ
    PART->>PART: パーティションテーブル解析
    PART->>PART: 子ハンドル作成
    PART->>PART: Block I/O インストール（各パーティション）
    PART-->>DXE: EFI_SUCCESS

    DXE->>FS: DriverBindingSupported()
    FS->>BIO: Media->LogicalPartition?
    BIO-->>FS: TRUE（論理パーティション）
    FS-->>DXE: EFI_SUCCESS
    DXE->>FS: DriverBindingStart()
```

**ポイント**:
- Partition Driver は `LogicalPartition == FALSE` のデバイスにのみ接続
- File System Driver は `LogicalPartition == TRUE` のデバイスに接続

---

## Simple File System Protocol

### ファイルシステム抽象化

**`EFI_SIMPLE_FILE_SYSTEM_PROTOCOL`** は、ファイルシステムへのアクセスを抽象化し、**ファイル・ディレクトリ操作**を提供します。

### プロトコル定義

```c
typedef struct _EFI_SIMPLE_FILE_SYSTEM_PROTOCOL {
  UINT64                            Revision;
  EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_OPEN_VOLUME OpenVolume;
} EFI_SIMPLE_FILE_SYSTEM_PROTOCOL;
```

### File Protocol

`OpenVolume()` は **`EFI_FILE_PROTOCOL`** を返します。このプロトコルが実際のファイル操作を提供します。

```c
typedef struct _EFI_FILE_PROTOCOL {
  UINT64                Revision;
  EFI_FILE_OPEN         Open;
  EFI_FILE_CLOSE        Close;
  EFI_FILE_DELETE       Delete;
  EFI_FILE_READ         Read;
  EFI_FILE_WRITE        Write;
  EFI_FILE_GET_POSITION GetPosition;
  EFI_FILE_SET_POSITION SetPosition;
  EFI_FILE_GET_INFO     GetInfo;
  EFI_FILE_SET_INFO     SetInfo;
  EFI_FILE_FLUSH        Flush;
  // UEFI 2.0 以降
  EFI_FILE_OPEN_EX      OpenEx;
  EFI_FILE_READ_EX      ReadEx;
  EFI_FILE_WRITE_EX     WriteEx;
  EFI_FILE_FLUSH_EX     FlushEx;
} EFI_FILE_PROTOCOL;
```

### ファイル操作の流れ

```mermaid
sequenceDiagram
    participant APP as アプリケーション
    participant SFS as Simple File System
    participant FILE as File Protocol
    participant DISK as Disk I/O

    APP->>SFS: OpenVolume(&Root)
    SFS-->>APP: Root (ルートディレクトリ)

    APP->>FILE: Root->Open("\\EFI\\BOOT\\BOOTX64.EFI")
    FILE->>DISK: ReadDisk(FAT エントリ検索)
    DISK-->>FILE: クラスタチェーン
    FILE->>FILE: ファイルハンドル作成
    FILE-->>APP: FileHandle

    APP->>FILE: FileHandle->Read(&Size, Buffer)
    FILE->>DISK: ReadDisk(クラスタ読み取り)
    DISK-->>FILE: ファイルデータ
    FILE-->>APP: データ

    APP->>FILE: FileHandle->Close()
```

### ファイルパスの規則

UEFI では、**バックスラッシュ (`\`) 区切り**のパスを使用します：

```
\EFI\BOOT\BOOTX64.EFI
\myapp\config.ini
```

**注意点**:
- 常にルート (`\`) から始まる
- 大文字小文字は区別されない（FAT の場合）
- スラッシュ (`/`) ではなくバックスラッシュ (`\`)

---

## デバイス別ドライバスタック

### NVMe ストレージスタック

**NVMe (Non-Volatile Memory Express)** は PCIe 接続の高速 SSD 用プロトコルです。

```mermaid
graph TB
    subgraph "アプリケーション"
        APP[UEFI Shell]
    end

    subgraph "ファイルシステム"
        FS[FAT Driver]
    end

    subgraph "パーティション"
        PART[Partition Driver - GPT]
    end

    subgraph "NVMe スタック"
        NVME_BIO[NVMe Block I/O]
        NVME_DRV[NVMe Driver]
        NVME_PASSTHRU[NVMe Pass Thru Protocol]
    end

    subgraph "ハードウェア"
        PCI_IO[PCI I/O Protocol]
        NVME_HW[NVMe SSD]
    end

    APP --> FS
    FS --> PART
    PART --> NVME_BIO
    NVME_BIO --> NVME_DRV
    NVME_DRV --> NVME_PASSTHRU
    NVME_PASSTHRU --> PCI_IO
    PCI_IO --> NVME_HW

    style FS fill:#e1f5ff
    style PART fill:#fff4e1
    style NVME_BIO fill:#e1ffe1
    style NVME_PASSTHRU fill:#f0e1ff
```

**NVMe Pass Thru Protocol**: NVMe コマンド（Admin Command, I/O Command）を直接送信するための低レベルプロトコル。

### AHCI (SATA) ストレージスタック

**AHCI (Advanced Host Controller Interface)** は SATA ディスク用の標準インターフェースです。

```mermaid
graph TB
    subgraph "ファイルシステム"
        FS[FAT Driver]
    end

    subgraph "パーティション"
        PART[Partition Driver - MBR]
    end

    subgraph "AHCI スタック"
        AHCI_BIO[AHCI Block I/O]
        AHCI_DRV[AHCI Bus Driver]
        ATA_PASSTHRU[ATA Pass Thru Protocol]
    end

    subgraph "ハードウェア"
        PCI_IO[PCI I/O Protocol]
        SATA_HW[SATA HDD/SSD]
    end

    FS --> PART
    PART --> AHCI_BIO
    AHCI_BIO --> AHCI_DRV
    AHCI_DRV --> ATA_PASSTHRU
    ATA_PASSTHRU --> PCI_IO
    PCI_IO --> SATA_HW

    style FS fill:#e1f5ff
    style PART fill:#fff4e1
    style AHCI_BIO fill:#e1ffe1
    style ATA_PASSTHRU fill:#f0e1ff
```

### USB Mass Storage スタック

**USB Mass Storage** は USB フラッシュドライブや外付け HDD で使われます。

```mermaid
graph TB
    subgraph "ファイルシステム"
        FS[FAT Driver]
    end

    subgraph "パーティション"
        PART[Partition Driver]
    end

    subgraph "USB スタック"
        USB_MS[USB Mass Storage Driver]
        USB_IO[USB I/O Protocol]
    end

    subgraph "ハードウェア"
        XHCI[xHCI Driver]
        USB_HW[USB デバイス]
    end

    FS --> PART
    PART --> USB_MS
    USB_MS --> USB_IO
    USB_IO --> XHCI
    XHCI --> USB_HW

    style FS fill:#e1f5ff
    style PART fill:#fff4e1
    style USB_MS fill:#e1ffe1
    style USB_IO fill:#f0e1ff
```

---

## ストレージスタックの動的な構築

### ドライバ接続の流れ

UEFI は起動時に、**DXE Dispatcher** がドライバを順次ロードし、`ConnectController()` でデバイスに接続していきます。

```mermaid
sequenceDiagram
    participant DXE as DXE Dispatcher
    participant NVME as NVMe Driver
    participant PART as Partition Driver
    participant FAT as FAT Driver

    DXE->>NVME: DriverBindingSupported(PCI Handle)
    NVME-->>DXE: EFI_SUCCESS
    DXE->>NVME: DriverBindingStart(PCI Handle)
    NVME->>NVME: Block I/O インストール
    NVME-->>DXE: EFI_SUCCESS

    DXE->>PART: DriverBindingSupported(Block I/O Handle)
    PART-->>DXE: EFI_SUCCESS
    DXE->>PART: DriverBindingStart(Block I/O Handle)
    PART->>PART: GPT 解析
    PART->>PART: 子ハンドル作成（各パーティション）
    PART-->>DXE: EFI_SUCCESS

    DXE->>FAT: DriverBindingSupported(Partition Handle)
    FAT-->>DXE: EFI_SUCCESS
    DXE->>FAT: DriverBindingStart(Partition Handle)
    FAT->>FAT: FAT32 認識
    FAT->>FAT: Simple File System インストール
    FAT-->>DXE: EFI_SUCCESS
```

### ハンドルの階層構造

```
物理デバイスハンドル
  ├─ Device Path Protocol
  ├─ PCI I/O Protocol
  └─ Block I/O Protocol (物理)
      │
      └─ パーティション1ハンドル（子）
          ├─ Device Path Protocol
          ├─ Block I/O Protocol (論理)
          ├─ Disk I/O Protocol
          └─ Simple File System Protocol
```

---

## ストレージアクセスの最適化

### キャッシング

| 層 | キャッシュの種類 | 説明 |
|----|---------------|------|
| **ハードウェア** | ディスクキャッシュ | デバイス内蔵の DRAM/SRAM |
| **Block I/O** | Write Caching | `Media->WriteCaching` で有効化 |
| **File System** | メタデータキャッシュ | FAT テーブルのキャッシュ |

### DMA vs PIO

| アクセス方法 | 説明 | パフォーマンス |
|------------|------|---------------|
| **DMA** | Direct Memory Access（CPU を介さずメモリ転送） | 高速 |
| **PIO** | Programmed I/O（CPU がデータをコピー） | 低速 |

UEFI のストレージドライバは通常 **DMA** を使用します。PCI I/O Protocol の `Map()` メソッドで DMA バッファをマッピングします。

---

## まとめ

この章では、UEFI におけるストレージスタックの階層構造と各層の役割について説明しました。ストレージスタックは、Block I/O Protocol、Disk I/O Protocol、Partition Driver、Simple File System Protocol という四つの主要な層から構成されています。この階層化により、多様なストレージデバイス、パーティションスキーム、ファイルシステムを統一的なインターフェースで扱うことができます。各層は明確な責務を持ち、下位層が提供する抽象化の上に構築されています。

Block I/O Protocol は、ストレージスタックの最下層であり、ブロック単位でのデータ読み書きを提供します。このプロトコルは、物理的なストレージデバイスへの低レベルアクセスを抽象化し、ReadBlocks と WriteBlocks という二つの主要な関数を提供します。Media 構造体は、デバイスの物理的特性を記述し、ブロックサイズ、メディアの有無、書き込み保護状態などの情報を提供します。Block I/O Protocol は、デバイスドライバ (NVMe Driver、AHCI Driver、USB Mass Storage Driver など) によって実装され、各ドライバはハードウェア固有の詳細を隠蔽します。

Disk I/O Protocol は、Block I/O Protocol の上に構築され、バイト単位でのデータ読み書きを提供します。このプロトコルは、ブロック境界に整列していない任意のオフセットとサイズでの読み書きをサポートし、Read-Modify-Write 操作により実現します。Disk I/O Protocol により、上位層はブロックサイズやブロック境界を意識することなく、任意の位置からデータにアクセスできます。

Partition Driver は、Disk I/O Protocol を使用してパーティションテーブルを解析し、各パーティションを個別の Block I/O Protocol として公開します。GPT (GUID Partition Table) と MBR (Master Boot Record) の両方をサポートし、それぞれのパーティションスキームに応じた処理を実行します。Partition Driver により、論理的なパーティションが物理的なディスクから分離され、各パーティションは独立したストレージデバイスとして扱われます。

Simple File System Protocol は、ストレージスタックの最上層であり、ファイルとディレクトリの操作を抽象化します。このプロトコルは、OpenVolume、Open、Read、Write、Close などの関数を提供し、ファイルシステムレベルのアクセスを可能にします。FAT32 は UEFI の標準ファイルシステムであり、ほぼすべての UEFI 実装でサポートされています。FAT ドライバは、Block I/O Protocol を使用してパーティションにアクセスし、FAT ファイルシステムの構造を解析してファイル操作を実現します。

デバイス別のストレージスタックは、それぞれ固有のプロトコルを使用します。NVMe ストレージは、NVMe Pass Thru Protocol を使用して NVMe コマンドを送信し、高速なデータ転送を実現します。AHCI (SATA) ストレージは、ATA Pass Thru Protocol を使用して ATA コマンドを送信します。USB ストレージは、USB I/O Protocol を使用して USB 通信を実行し、SCSI コマンドをカプセル化して送信します。これらのデバイス固有のプロトコルは、Block I/O Protocol の実装レイヤに隠蔽され、上位層は統一的なインターフェースでアクセスできます。

---

次章では、**USB スタックの構造**について学びます。USB は複雑な階層プロトコルであり、USB Host Controller（xHCI/EHCI）、USB Bus Driver、USB デバイスドライバ（HID、Mass Storage など）が連携して動作します。USB の列挙プロセス、エンドポイント通信、転送タイプ（Control/Bulk/Interrupt/Isochronous）など、USB スタック特有の仕組みを詳しく見ていきます。

---

📚 **参考資料**
- [UEFI Specification v2.10 - Section 13.5: Block I/O Protocol](https://uefi.org/specifications)
- [UEFI Specification v2.10 - Section 13.7: Simple File System Protocol](https://uefi.org/specifications)
- [UEFI Specification v2.10 - Section 13.6: Disk I/O Protocol](https://uefi.org/specifications)
- [NVMe Specification](https://nvmexpress.org/specifications/)
- [AHCI Specification](https://www.intel.com/content/www/us/en/io/serial-ata/serial-ata-ahci-spec-rev1-3-1.html)
