# グラフィックスサブシステム (GOP)

🎯 **この章で学ぶこと**
- Graphics Output Protocol (GOP) の設計思想と役割
- レガシー VGA/VESA からの進化
- GOP のモード設定とフレームバッファアクセスの仕組み
- Blt (Block Transfer) 操作による描画抽象化

📚 **前提知識**
- [Part II: プロトコルとドライバモデルの理解](03-protocol-and-driver-model.md)
- [Part II: ハードウェア抽象化の仕組み](05-hardware-abstraction.md)

---

## GOP の必要性

### レガシーグラフィックスの問題点

UEFI 以前の BIOS 環境では、**VGA BIOS** や **VESA BIOS Extensions (VBE)** を使ってグラフィックス機能を提供していました。しかし、これらには以下の問題がありました：

| 問題点 | 説明 | 影響 |
|--------|------|------|
| **リアルモード依存** | INT 10h などリアルモード割り込みに依存 | 64 ビット環境で使用不可 |
| **標準化不足** | ベンダごとに実装が異なる | 互換性問題が頻発 |
| **機能不足** | 高解像度、高色深度のサポートが不十分 | 現代のディスプレイに対応できない |
| **パフォーマンス** | BIOS 呼び出しのオーバーヘッドが大きい | 描画が遅い |

### GOP による解決

**Graphics Output Protocol (GOP)** は、これらの問題を解決するために UEFI で導入された標準的なグラフィックスインターフェースです。

```mermaid
graph LR
    subgraph "レガシー BIOS"
        VGABIOS[VGA BIOS]
        VBE[VESA VBE]
        INT10[INT 10h]
    end

    subgraph "UEFI"
        GOP[GOP Protocol]
        FRAME[Framebuffer]
    end

    subgraph "課題"
        REAL[リアルモード依存]
        COMPAT[互換性問題]
        PERF[低速]
    end

    VGABIOS --> INT10
    VBE --> INT10
    INT10 --> REAL
    INT10 --> COMPAT
    INT10 --> PERF

    GOP --> FRAME
    FRAME -.解決.-> REAL
    FRAME -.解決.-> COMPAT
    FRAME -.解決.-> PERF

    style GOP fill:#e1f5ff
    style FRAME fill:#e1ffe1
    style REAL fill:#ffe1e1
    style COMPAT fill:#ffe1e1
    style PERF fill:#ffe1e1
```

### GOP の設計思想

| 原則 | 説明 |
|------|------|
| **プロテクトモード動作** | リアルモード割り込みを使用しない |
| **標準化** | UEFI 仕様で厳密に定義 |
| **シンプルなインターフェース** | フレームバッファへの直接アクセス |
| **高機能** | 任意の解像度・色深度をサポート |

---

## GOP プロトコルの構造

### プロトコル定義

```c
typedef struct _EFI_GRAPHICS_OUTPUT_PROTOCOL {
  EFI_GRAPHICS_OUTPUT_PROTOCOL_QUERY_MODE  QueryMode;
  EFI_GRAPHICS_OUTPUT_PROTOCOL_SET_MODE    SetMode;
  EFI_GRAPHICS_OUTPUT_PROTOCOL_BLT         Blt;
  EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE        *Mode;
} EFI_GRAPHICS_OUTPUT_PROTOCOL;
```

### 各メソッドの役割

```mermaid
graph TB
    GOP[GOP Protocol]
    GOP --> QUERY[QueryMode]
    GOP --> SET[SetMode]
    GOP --> BLT[Blt]
    GOP --> MODE[Mode]

    QUERY --> QUERY_DESC["利用可能なモードを問い合わせ<br/>解像度・色深度を取得"]
    SET --> SET_DESC["指定したモードに切り替え<br/>フレームバッファを初期化"]
    BLT --> BLT_DESC["矩形領域の転送・塗りつぶし<br/>画面更新操作"]
    MODE --> MODE_DESC["現在のモード情報<br/>フレームバッファアドレス"]

    style QUERY fill:#e1f5ff
    style SET fill:#fff4e1
    style BLT fill:#e1ffe1
    style MODE fill:#ffe1f5
```

#### QueryMode: モード情報の取得

```c
typedef EFI_STATUS (EFIAPI *EFI_GRAPHICS_OUTPUT_PROTOCOL_QUERY_MODE) (
  IN  EFI_GRAPHICS_OUTPUT_PROTOCOL          *This,
  IN  UINT32                                ModeNumber,
  OUT UINTN                                 *SizeOfInfo,
  OUT EFI_GRAPHICS_OUTPUT_MODE_INFORMATION  **Info
);
```

**役割**: 指定したモード番号の詳細情報（解像度、色深度、フレームバッファ形式）を取得します。

#### SetMode: モード設定

```c
typedef EFI_STATUS (EFIAPI *EFI_GRAPHICS_OUTPUT_PROTOCOL_SET_MODE) (
  IN  EFI_GRAPHICS_OUTPUT_PROTOCOL  *This,
  IN  UINT32                        ModeNumber
);
```

**役割**: 指定したモード番号に切り替えます。この操作により、解像度が変更され、フレームバッファが再初期化されます。

#### Blt: Block Transfer（描画操作）

```c
typedef EFI_STATUS (EFIAPI *EFI_GRAPHICS_OUTPUT_PROTOCOL_BLT) (
  IN  EFI_GRAPHICS_OUTPUT_PROTOCOL      *This,
  IN  EFI_GRAPHICS_OUTPUT_BLT_PIXEL     *BltBuffer  OPTIONAL,
  IN  EFI_GRAPHICS_OUTPUT_BLT_OPERATION BltOperation,
  IN  UINTN                             SourceX,
  IN  UINTN                             SourceY,
  IN  UINTN                             DestinationX,
  IN  UINTN                             DestinationY,
  IN  UINTN                             Width,
  IN  UINTN                             Height,
  IN  UINTN                             Delta        OPTIONAL
);
```

**役割**: 矩形領域のコピー、塗りつぶし、画面更新などの描画操作を行います。

---

## モード設定の仕組み

### モード情報の構造

```c
typedef struct {
  UINT32                     MaxMode;         // サポートされるモード数
  UINT32                     Mode;            // 現在のモード番号
  EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *Info; // 現在のモード情報
  UINTN                      SizeOfInfo;      // 情報構造体のサイズ
  EFI_PHYSICAL_ADDRESS       FrameBufferBase; // フレームバッファの物理アドレス
  UINTN                      FrameBufferSize; // フレームバッファのサイズ
} EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE;

typedef struct {
  UINT32                     Version;          // 構造体バージョン
  UINT32                     HorizontalResolution; // 横解像度
  UINT32                     VerticalResolution;   // 縦解像度
  EFI_GRAPHICS_PIXEL_FORMAT  PixelFormat;      // ピクセルフォーマット
  EFI_PIXEL_BITMASK          PixelInformation; // ビットマスク情報
  UINT32                     PixelsPerScanLine; // 1行あたりのピクセル数
} EFI_GRAPHICS_OUTPUT_MODE_INFORMATION;
```

### ピクセルフォーマット

```c
typedef enum {
  PixelRedGreenBlueReserved8BitPerColor, // RGBX (各8ビット)
  PixelBlueGreenRedReserved8BitPerColor, // BGRX (各8ビット)
  PixelBitMask,                          // カスタムビットマスク
  PixelBltOnly,                          // Blt 操作のみ可能
  PixelFormatMax
} EFI_GRAPHICS_PIXEL_FORMAT;
```

### モード設定の流れ

```mermaid
sequenceDiagram
    participant APP as UEFI アプリ
    participant GOP as GOP Protocol
    participant DRV as GOP ドライバ
    participant HW as GPU ハードウェア

    APP->>GOP: QueryMode(0, ...)
    GOP->>DRV: モード 0 の情報取得
    DRV->>HW: レジスタ読み取り
    HW-->>DRV: サポート情報
    DRV-->>APP: 1920x1080, RGB

    APP->>GOP: SetMode(0)
    GOP->>DRV: モード 0 に設定
    DRV->>HW: レジスタ設定
    HW-->>DRV: 設定完了
    DRV->>DRV: フレームバッファ初期化
    DRV-->>APP: EFI_SUCCESS

    APP->>GOP: Mode->FrameBufferBase
    GOP-->>APP: 0xC0000000
```

**手順**:

1. **全モード列挙**: `MaxMode` まで `QueryMode()` を呼び、対応解像度を確認
2. **適切なモード選択**: アプリケーションの要求に合うモードを選択
3. **モード設定**: `SetMode()` でモード切り替え
4. **フレームバッファアクセス**: `Mode->FrameBufferBase` から直接描画可能

---

## Blt 操作による描画

### Blt 操作の種類

```c
typedef enum {
  EfiBltVideoFill,           // 画面を単色で塗りつぶし
  EfiBltVideoToBltBuffer,    // 画面からメモリへコピー
  EfiBltBufferToVideo,       // メモリから画面へコピー
  EfiBltVideoToVideo,        // 画面内でコピー（スクロールなど）
  EfiGraphicsOutputBltOperationMax
} EFI_GRAPHICS_OUTPUT_BLT_OPERATION;
```

### 各操作の用途

| 操作 | 用途 | 例 |
|------|------|-----|
| **VideoFill** | 領域を単色で塗りつぶす | 背景のクリア、矩形の描画 |
| **VideoToBltBuffer** | 画面内容をメモリに保存 | 画面キャプチャ、ダブルバッファリング |
| **BufferToVideo** | メモリ内容を画面に転送 | ビットマップ表示、フォント描画 |
| **VideoToVideo** | 画面内でコピー | スクロール、ウィンドウ移動 |

### Blt 操作の概念図

```mermaid
graph TB
    subgraph "メモリ (BltBuffer)"
        BUF[Blt Buffer<br/>RGB ピクセル配列]
    end

    subgraph "画面 (Framebuffer)"
        FB[Framebuffer<br/>物理 VRAM]
    end

    BUF -->|BufferToVideo| FB
    FB -->|VideoToBltBuffer| BUF
    FB -->|VideoToVideo| FB
    BUF -.VideoFill.-> FB

    style BUF fill:#e1f5ff
    style FB fill:#e1ffe1
```

### Blt 操作の例（概念的）

#### 例1: 画面全体を青色でクリア

```c
EFI_GRAPHICS_OUTPUT_BLT_PIXEL Blue = { 0, 0, 255, 0 }; // B, G, R, Reserved

Status = Gop->Blt (
  Gop,
  &Blue,
  EfiBltVideoFill,
  0, 0,                          // Source (未使用)
  0, 0,                          // Destination (0, 0)
  Gop->Mode->Info->HorizontalResolution,
  Gop->Mode->Info->VerticalResolution,
  0
);
```

#### 例2: ビットマップを画面に描画

```c
EFI_GRAPHICS_OUTPUT_BLT_PIXEL *ImageBuffer;
// ImageBuffer にビットマップデータを読み込み済みと仮定

Status = Gop->Blt (
  Gop,
  ImageBuffer,
  EfiBltBufferToVideo,
  0, 0,                          // Source (0, 0)
  100, 100,                      // Destination (100, 100)
  640, 480,                      // Width, Height
  0                              // Delta (0 = Width * sizeof(pixel))
);
```

#### 例3: 画面領域を下にスクロール

```c
// 画面を10行下にスクロール
Status = Gop->Blt (
  Gop,
  NULL,
  EfiBltVideoToVideo,
  0, 10,                         // Source (0, 10)
  0, 0,                          // Destination (0, 0)
  Gop->Mode->Info->HorizontalResolution,
  Gop->Mode->Info->VerticalResolution - 10,
  0
);
```

---

## GOP ドライバのアーキテクチャ

### GOP ドライバの階層

```mermaid
graph TB
    subgraph "アプリケーション層"
        APP[UEFI アプリ/シェル]
    end

    subgraph "GOP プロトコル層"
        GOP_PROTO[EFI_GRAPHICS_OUTPUT_PROTOCOL]
    end

    subgraph "GOP ドライバ層"
        GOP_DRV[GOP ドライバ]
        MODESW[モード切り替え]
        BLTOP[Blt 操作実装]
    end

    subgraph "ハードウェア抽象層"
        PCI_IO[PCI I/O Protocol]
    end

    subgraph "ハードウェア層"
        GPU[GPU/ビデオカード]
        VRAM[VRAM]
    end

    APP --> GOP_PROTO
    GOP_PROTO --> GOP_DRV
    GOP_DRV --> MODESW
    GOP_DRV --> BLTOP
    MODESW --> PCI_IO
    BLTOP --> PCI_IO
    PCI_IO --> GPU
    GPU --> VRAM

    style GOP_PROTO fill:#e1f5ff
    style GOP_DRV fill:#fff4e1
    style PCI_IO fill:#e1ffe1
```

### GOP ドライバの種類

| ドライバタイプ | 説明 | 例 |
|--------------|------|-----|
| **ベンダ専用** | 特定 GPU に最適化されたドライバ | Intel GOP Driver, NVIDIA UEFI Driver |
| **汎用 VESA** | VESA VBE 経由で動作 | VBE Shim Driver |
| **シンプル FB** | フレームバッファのみサポート | Simple Framebuffer Driver |

### GOP ドライバの初期化手順

```mermaid
sequenceDiagram
    participant DXE as DXE Core
    participant DRV as GOP ドライバ
    participant PCI as PCI I/O
    participant GPU as GPU

    DXE->>DRV: DriverBindingSupported()
    DRV->>PCI: GetLocation()
    PCI-->>DRV: VendorID, DeviceID
    DRV->>DRV: サポート判定
    DRV-->>DXE: EFI_SUCCESS

    DXE->>DRV: DriverBindingStart()
    DRV->>PCI: Attributes(Enable)
    DRV->>GPU: モード列挙
    GPU-->>DRV: サポートモード一覧
    DRV->>DRV: GOP Protocol インストール
    DRV-->>DXE: EFI_SUCCESS
```

**手順**:

1. **デバイス検出**: PCI I/O Protocol でビデオカードを発見
2. **サポート判定**: VendorID/DeviceID から対応可否を判断
3. **初期化**: GPU のモード情報を収集
4. **プロトコル公開**: GOP Protocol をハンドルにインストール

---

## GOP と UGA の関係

### UGA Protocol (レガシー)

UEFI 1.x では **Universal Graphics Adapter (UGA) Protocol** が使われていました。UEFI 2.0 以降は **GOP が推奨**され、UGA は廃止予定です。

| 項目 | UGA | GOP |
|------|-----|-----|
| **導入時期** | UEFI 1.x | UEFI 2.0 以降 |
| **モード設定** | SetMode() | SetMode() |
| **描画** | Blt() | Blt() |
| **フレームバッファ** | 直接アクセス不可 | Mode->FrameBufferBase で可能 |
| **ステータス** | 廃止予定 | 推奨 |

### 互換性のための対応

古い UEFI アプリケーションとの互換性のため、一部の GOP ドライバは **UGA Protocol も同時に提供**することがあります。

---

## フレームバッファの直接操作

### フレームバッファとは

**フレームバッファ**は、画面に表示される各ピクセルの色情報が格納されたメモリ領域です。GOP では、このアドレスが `Mode->FrameBufferBase` として公開されます。

### 直接描画の例（概念的）

```c
UINT32 *FrameBuffer = (UINT32 *)(UINTN)Gop->Mode->FrameBufferBase;
UINT32 HorizontalResolution = Gop->Mode->Info->HorizontalResolution;
UINT32 VerticalResolution = Gop->Mode->Info->VerticalResolution;

// 画面全体を白色 (0xFFFFFFFF) で塗りつぶし
for (UINT32 y = 0; y < VerticalResolution; y++) {
  for (UINT32 x = 0; x < HorizontalResolution; x++) {
    FrameBuffer[y * HorizontalResolution + x] = 0xFFFFFFFF;
  }
}
```

### Blt vs 直接アクセス

| 方法 | 利点 | 欠点 | 用途 |
|------|------|------|------|
| **Blt 操作** | ハードウェア加速が可能<br/>抽象化されている | オーバーヘッドがある | 一般的な描画 |
| **直接アクセス** | 最高速<br/>柔軟性が高い | ピクセルフォーマットに注意が必要 | 高速描画が必要な場合 |

---

## GOP を使った画面出力の実例

### 起動画面（スプラッシュスクリーン）

多くの UEFI ファームウェアは、起動時にベンダーロゴを表示します。これは GOP を使って実装されています。

```mermaid
sequenceDiagram
    participant BIOS as UEFI Firmware
    participant GOP as GOP Protocol
    participant LOGO as Logo Driver

    BIOS->>GOP: SetMode(最高解像度)
    BIOS->>LOGO: ロゴビットマップ取得
    LOGO-->>BIOS: BMP データ
    BIOS->>GOP: Blt(BufferToVideo)
    GOP-->>BIOS: 画面にロゴ表示
    Note over BIOS: ユーザーがキーを押すまで待機
    BIOS->>GOP: Blt(VideoFill, Black)
    GOP-->>BIOS: 画面クリア
```

### UEFI シェル

UEFI シェルも GOP を使ってテキストを描画しています。

**動作原理**:

1. **フォントデータ**: HII Font Protocol からフォントビットマップを取得
2. **文字描画**: 各文字をビットマップとして Blt で転送
3. **スクロール**: VideoToVideo で画面内容を上にシフト

---

## まとめ

### この章で学んだこと

✅ **GOP の必要性**
- レガシー VGA/VESA の問題（リアルモード依存、標準化不足）を解決
- UEFI 環境でのモダンなグラフィックス抽象化

✅ **GOP の構造**
- QueryMode, SetMode, Blt の3つの主要メソッド
- Mode 構造体でフレームバッファ情報を提供

✅ **モード設定**
- 複数の解像度・色深度をサポート
- ピクセルフォーマット（RGB, BGR, BitMask）の選択

✅ **Blt 操作**
- VideoFill, VideoToBltBuffer, BufferToVideo, VideoToVideo の4種類
- 矩形領域の効率的な転送・塗りつぶし

✅ **GOP ドライバ**
- PCI I/O Protocol 経由で GPU にアクセス
- ベンダ専用ドライバと汎用ドライバ

✅ **フレームバッファ直接アクセス**
- Mode->FrameBufferBase から直接描画可能
- Blt とのトレードオフを理解

### 次章の予告

次章では、**ストレージスタックの構造**について学びます。UEFI は HDD、SSD、NVMe など多様なストレージデバイスをサポートしますが、これらは Block I/O Protocol、Disk I/O Protocol、File System Protocol という階層的なスタックで抽象化されています。各プロトコルの役割と、ドライバがどのように連携するかを詳しく見ていきます。

---

📚 **参考資料**
- [UEFI Specification v2.10 - Section 12.9: Graphics Output Protocol](https://uefi.org/specifications)
- [UEFI Specification v2.10 - Section 12.10: EDID Protocols](https://uefi.org/specifications)
- [Intel® UEFI Development Kit (UDK) - GOP Driver Implementation](https://github.com/tianocore/edk2)
