# デバッグツールの仕組み

🎯 **この章で学ぶこと**
- JTAG/SWD ハードウェアデバッガの原理
- GDB リモートデバッグプロトコルの詳細
- UEFI デバッグサポートプロトコルの実装
- シンボル情報の構造と活用方法
- プロファイリングツールの仕組み

📚 **前提知識**
- [ファームウェアデバッグの基礎](01-debug-fundamentals.md)
- [Part I: x86_64 ブート基礎](../part1/README.md)

---

## イントロダクション

デバッグツールは、ファームウェア開発における最も重要なインフラストラクチャの1つです。前章では、シリアルデバッグ、GDB、POST コードといった基本的なデバッグ手法を学びましたが、これらのツールがどのように動作し、内部でどのような仕組みを使ってプロセッサやメモリにアクセスしているかを理解することは、効果的なデバッグを行う上で不可欠です。本章では、デバッグツールの内部動作原理を深く掘り下げ、**ハードウェアデバッガ（JTAG/SWD）**、**GDB リモートプロトコル**、**UEFI デバッグサポート**、**シンボル情報（DWARF/CodeView）**、そして**プロファイリング・トレース機構**の仕組みを詳細に解説します。

**ハードウェアデバッガ**は、プロセッサに物理的に接続し、CPU の実行を完全に制御できるデバッグインターフェースです。JTAG（Joint Test Action Group）や SWD（Serial Wire Debug）といった標準プロトコルを使用し、プロセッサ内部のレジスタやメモリに直接アクセスできます。ハードウェアデバッガの最大の利点は、**ソフトウェアの介在なしに**プロセッサの状態を監視・制御できる点であり、ファームウェアがクラッシュしてハングした状態でも、外部から介入してデバッグできます。これは、シリアルデバッグや GDB Stub がソフトウェアとして動作する必要があるのとは対照的です。JTAG は 5 本の信号線（TCK, TMS, TDI, TDO, TRST）を使用し、TAP（Test Access Port）ステートマシンを通じて複雑な制御を行いますが、ARM が開発した SWD は 2 本の信号線（SWDCLK, SWDIO）で同等の機能を実現し、ピン数を削減しています。

**GDB リモートプロトコル**（RSP: Remote Serial Protocol）は、GDB クライアントとターゲットシステム上の GDB Stub 間で通信するための標準プロトコルです。このプロトコルは、シリアルポートや TCP/IP 上で動作し、パケットベースの通信を行います。各パケットは `$<data>#<checksum>` という形式で、レジスタの読み書き（`g`/`G` コマンド）、メモリの読み書き（`m`/`M` コマンド）、ブレークポイントの設定（`Z0` コマンド）、実行制御（`c`/`s` コマンド）といった操作を実行します。QEMU や OpenOCD といったツールは、GDB Stub としてこのプロトコルを実装しており、GDB から接続するだけでリモートデバッグが可能になります。GDB リモートプロトコルの理解は、独自のデバッグスタブを実装したり、デバッグ時の通信問題をトラブルシュートする際に極めて有用です。

**UEFI デバッグサポート**は、UEFI 仕様で定義されたデバッグ支援機構であり、`EFI_DEBUG_SUPPORT_PROTOCOL` を通じて例外ハンドラの登録やプロセッサアーキテクチャ固有のデバッグ機能にアクセスできます。このプロトコルを使用することで、ブレークポイント例外（INT3）やシングルステップ例外（デバッグ例外）が発生した際に、カスタムハンドラで処理を行い、GDB Stub に制御を移すことが可能になります。UEFI デバッグサポートは、OS が存在しない環境でも高度なデバッグ機能を実現するための標準的な仕組みを提供します。

**シンボル情報**は、バイナリコードとソースコードを紐づける重要な情報です。**DWARF**（Debugging With Attributed Record Formats）は、ELF バイナリに埋め込まれるデバッグ情報の標準フォーマットであり、変数・関数・型の情報（`.debug_info`）、ソースコード行番号マッピング（`.debug_line`）、スタックフレーム情報（`.debug_frame`）などを含みます。GDB は DWARF 情報を読み取ることで、ソースコードレベルでのブレークポイント設定や変数の表示を実現します。一方、UEFI モジュールは PE/COFF フォーマットを使用し、**CodeView** 形式のデバッグ情報を含むことがあります。これらのシンボル情報がなければ、デバッガは機械語命令のアドレスしか表示できず、ソースコードとの対応が取れないため、効果的なデバッグは不可能です。

**プロファイリング・トレース機構**は、パフォーマンスの分析や実行フローの解析に使用されます。**サンプリングベースプロファイリング**は、定期的なタイマー割り込みで現在のプログラムカウンタ（RIP）を記録し、統計的にホットスポット（最も時間を消費している関数）を特定します。オーバーヘッドが小さく、実環境でも使用できるのが利点です。一方、**インストルメンテーションベースプロファイリング**は、関数の開始・終了時に計測コードを挿入し、正確な実行時間を測定します。さらに、ARM の **ETM**（Embedded Trace Macrocell）や Intel の **Processor Trace (PT)** は、ハードウェアレベルで命令の実行フローを記録し、非侵襲的に詳細なトレースを取得できます。これらの機構を理解することで、パフォーマンス問題の根本原因を特定し、最適化の方向性を決定できるようになります。

---

## ハードウェアデバッガの原理

### JTAG (Joint Test Action Group)

JTAG は、元々 IC のテストのために設計された IEEE 1149.1 規格ですが、現在ではデバッグインターフェースとして広く使用されています。

#### JTAG のアーキテクチャ

```mermaid
graph TB
    subgraph "デバッグホスト"
        A[GDB/IDE]
        B[JTAG デバッガ<br/>OpenOCD/J-Link]
    end

    subgraph "JTAG インターフェース"
        C[TCK - Clock]
        D[TMS - Mode Select]
        E[TDI - Data In]
        F[TDO - Data Out]
        G[TRST - Reset]
    end

    subgraph "ターゲットCPU"
        H[TAP Controller]
        I[Instruction Register]
        J[Data Registers]
        K[CPU Core]
        L[Debug Module]
    end

    A --> B
    B --> C & D & E & F & G
    C & D & E & F & G --> H
    H --> I
    H --> J
    I --> L
    J --> L
    L --> K
```

#### JTAG 信号線の役割

| 信号 | 方向 | 説明 |
|------|------|------|
| **TCK** | Host → Target | クロック信号（通常 1-10 MHz） |
| **TMS** | Host → Target | モード選択（ステートマシン制御） |
| **TDI** | Host → Target | データ入力（シリアルデータ） |
| **TDO** | Target → Host | データ出力（シリアルデータ） |
| **TRST** | Host → Target | リセット（オプション） |

#### TAP ステートマシン

```mermaid
stateDiagram-v2
    [*] --> Test_Logic_Reset
    Test_Logic_Reset --> Run_Test_Idle: TMS=0
    Test_Logic_Reset --> Test_Logic_Reset: TMS=1

    Run_Test_Idle --> Select_DR_Scan: TMS=1
    Run_Test_Idle --> Run_Test_Idle: TMS=0

    Select_DR_Scan --> Capture_DR: TMS=0
    Select_DR_Scan --> Select_IR_Scan: TMS=1

    Capture_DR --> Shift_DR: TMS=0
    Shift_DR --> Shift_DR: TMS=0
    Shift_DR --> Exit1_DR: TMS=1
    Exit1_DR --> Update_DR: TMS=1
    Update_DR --> Run_Test_Idle: TMS=0

    Select_IR_Scan --> Capture_IR: TMS=0
    Capture_IR --> Shift_IR: TMS=0
    Shift_IR --> Shift_IR: TMS=0
    Shift_IR --> Exit1_IR: TMS=1
    Exit1_IR --> Update_IR: TMS=1
    Update_IR --> Run_Test_Idle: TMS=0
```

### ARM SWD (Serial Wire Debug)

SWD は ARM が開発した2線式のデバッグインターフェースで、JTAG よりもピン数が少ないのが特徴です。

#### SWD の信号線

| 信号 | 方向 | 説明 |
|------|------|------|
| **SWDCLK** | Host → Target | クロック信号 |
| **SWDIO** | Bidirectional | データ入出力（双方向） |
| **SWO** | Target → Host | トレース出力（オプション） |

#### SWD プロトコルの基本

```c
// SWD パケット構造（簡略版）
typedef struct {
  UINT8   Start    : 1;  // 常に 1
  UINT8   APnDP    : 1;  // 0=DP, 1=AP
  UINT8   RnW      : 1;  // 0=Write, 1=Read
  UINT8   Address  : 2;  // レジスタアドレス
  UINT8   Parity   : 1;  // パリティビット
  UINT8   Stop     : 1;  // 常に 0
  UINT8   Park     : 1;  // 常に 1
} SWD_REQUEST;

// SWD 読み取りの疑似コード
UINT32 SwdRead(UINT8 ap, UINT8 addr) {
  SWD_REQUEST req;
  req.Start = 1;
  req.APnDP = ap;
  req.RnW = 1;  // Read
  req.Address = addr;
  req.Parity = CalculateParity(&req);
  req.Stop = 0;
  req.Park = 1;

  // リクエスト送信
  SwdSendBits(&req, 8);

  // ACK 受信（3ビット）
  UINT8 ack = SwdReceiveBits(3);
  if (ack != SWD_ACK_OK) {
    return SWD_ERROR;
  }

  // データ受信（32ビット）
  UINT32 data = SwdReceiveBits(32);

  // パリティ受信
  UINT8 parity = SwdReceiveBits(1);

  return data;
}
```

---

## GDB リモートプロトコル

GDB は、リモートデバッグのために RSP (Remote Serial Protocol) を使用します。QEMU や実機デバッガは、このプロトコルを実装することで GDB と通信します。

### GDB リモートプロトコルの概要

```mermaid
sequenceDiagram
    participant GDB as GDB クライアント
    participant Stub as GDB Stub<br/>(QEMU/OpenOCD)
    participant Target as ターゲット

    GDB->>Stub: $g#67 (レジスタ読み取り)
    Stub->>Target: レジスタ値取得
    Target-->>Stub: RAX=0x1234, RBX=0x5678, ...
    Stub-->>GDB: +$rax:1234;rbx:5678;...#XX

    GDB->>Stub: $m7f800000,100#XX (メモリ読み取り)
    Stub->>Target: アドレス 0x7f800000 から 0x100 バイト読み取り
    Target-->>Stub: メモリ内容
    Stub-->>GDB: +$48656c6c6f...#XX

    GDB->>Stub: $Z0,7f801234,1#XX (ブレークポイント設定)
    Stub->>Target: 0x7f801234 に BP 設定
    Target-->>Stub: OK
    Stub-->>GDB: +$OK#XX

    GDB->>Stub: $c#63 (実行継続)
    Stub->>Target: CPU 実行再開
    Note over Target: ブレークポイントヒット
    Target-->>Stub: 停止通知
    Stub-->>GDB: +$S05#XX (SIGTRAP)
```

### 主要な GDB コマンド

| パケット | 説明 | 応答例 |
|---------|------|--------|
| `$g#67` | 全レジスタ読み取り | `$rax:1234;rbx:5678;...#XX` |
| `$G<data>#XX` | 全レジスタ書き込み | `$OK#XX` |
| `$m<addr>,<len>#XX` | メモリ読み取り | `$48656c6c6f...#XX` (HEX) |
| `$M<addr>,<len>:<data>#XX` | メモリ書き込み | `$OK#XX` |
| `$Z0,<addr>,<kind>#XX` | ソフトウェア BP 設定 | `$OK#XX` |
| `$z0,<addr>,<kind>#XX` | ソフトウェア BP 削除 | `$OK#XX` |
| `$c#63` | 実行継続 (continue) | `$S05#XX` (停止時) |
| `$s#73` | ステップ実行 (step) | `$S05#XX` |
| `$?#3F` | 停止理由の問い合わせ | `$S05#XX` |

### パケット形式

```
$<data>#<checksum>

例: $m7f800000,100#a4
     ^          ^ ^^
     |          | |+-- チェックサム（2桁HEX）
     |          | +--- '#' 区切り文字
     |          +----- データ部
     +---------------- '$' 開始マーカー

チェックサム = sum(data) % 256 の2桁HEX表現
```

### GDB Stub の実装例（簡略版）

```c
// GDB Stub の簡易実装
typedef struct {
  UINT64  Rax, Rbx, Rcx, Rdx;
  UINT64  Rsi, Rdi, Rbp, Rsp;
  UINT64  R8, R9, R10, R11, R12, R13, R14, R15;
  UINT64  Rip, Rflags;
  UINT32  Cs, Ss, Ds, Es, Fs, Gs;
} GDB_REGISTERS;

CHAR8 gGdbInputBuffer[4096];
CHAR8 gGdbOutputBuffer[4096];

VOID
GdbStubMain (
  VOID
  )
{
  while (TRUE) {
    // パケット受信
    if (!GdbReceivePacket(gGdbInputBuffer, sizeof(gGdbInputBuffer))) {
      continue;
    }

    // コマンド処理
    switch (gGdbInputBuffer[0]) {
      case 'g':  // レジスタ読み取り
        GdbReadRegisters(gGdbOutputBuffer);
        break;

      case 'G':  // レジスタ書き込み
        GdbWriteRegisters(&gGdbInputBuffer[1]);
        AsciiStrCpyS(gGdbOutputBuffer, sizeof(gGdbOutputBuffer), "OK");
        break;

      case 'm':  // メモリ読み取り
        GdbReadMemory(&gGdbInputBuffer[1], gGdbOutputBuffer);
        break;

      case 'M':  // メモリ書き込み
        GdbWriteMemory(&gGdbInputBuffer[1]);
        AsciiStrCpyS(gGdbOutputBuffer, sizeof(gGdbOutputBuffer), "OK");
        break;

      case 'c':  // 実行継続
        return;  // Stub を抜けて実行再開

      case 's':  // ステップ実行
        SetSingleStepFlag();
        return;

      case '?':  // 停止理由
        AsciiStrCpyS(gGdbOutputBuffer, sizeof(gGdbOutputBuffer), "S05");
        break;

      default:
        // 未サポートコマンド
        gGdbOutputBuffer[0] = '\0';
        break;
    }

    // 応答送信
    GdbSendPacket(gGdbOutputBuffer);
  }
}

VOID
GdbReadRegisters (
  OUT CHAR8  *Buffer
  )
{
  GDB_REGISTERS  *Regs = GetCurrentRegisters();

  // レジスタをHEX文字列に変換
  AsciiSPrint(Buffer, 4096,
    "%016lx%016lx%016lx%016lx"  // RAX, RBX, RCX, RDX
    "%016lx%016lx%016lx%016lx"  // RSI, RDI, RBP, RSP
    "%016lx%016lx%016lx%016lx"  // R8-R11
    "%016lx%016lx%016lx%016lx"  // R12-R15
    "%016lx",                    // RIP
    Regs->Rax, Regs->Rbx, Regs->Rcx, Regs->Rdx,
    Regs->Rsi, Regs->Rdi, Regs->Rbp, Regs->Rsp,
    Regs->R8, Regs->R9, Regs->R10, Regs->R11,
    Regs->R12, Regs->R13, Regs->R14, Regs->R15,
    Regs->Rip
  );
}

VOID
GdbReadMemory (
  IN  CHAR8  *AddrLenStr,
  OUT CHAR8  *Buffer
  )
{
  UINT64  Address;
  UINT32  Length;
  UINT8   *Ptr;
  UINTN   Index;

  // "7f800000,100" をパース
  AsciiStrHexToUint64S(AddrLenStr, NULL, &Address);
  // ',' を探して長さを取得
  CHAR8 *Comma = AsciiStrStr(AddrLenStr, ",");
  if (Comma) {
    AsciiStrHexToUint64S(Comma + 1, NULL, &Length);
  }

  // メモリ内容をHEX文字列に変換
  Ptr = (UINT8 *)(UINTN)Address;
  for (Index = 0; Index < Length; Index++) {
    AsciiSPrint(&Buffer[Index * 2], 3, "%02x", Ptr[Index]);
  }
}
```

---

## UEFI デバッグサポートプロトコル

UEFI 仕様では、デバッグをサポートするためのプロトコルが定義されています。

### EFI_DEBUG_SUPPORT_PROTOCOL

```c
typedef struct _EFI_DEBUG_SUPPORT_PROTOCOL {
  EFI_INSTRUCTION_SET_ARCHITECTURE  Isa;
  EFI_GET_MAXIMUM_PROCESSOR_INDEX   GetMaximumProcessorIndex;
  EFI_REGISTER_PERIODIC_CALLBACK    RegisterPeriodicCallback;
  EFI_REGISTER_EXCEPTION_CALLBACK   RegisterExceptionCallback;
  EFI_INVALIDATE_INSTRUCTION_CACHE  InvalidateInstructionCache;
} EFI_DEBUG_SUPPORT_PROTOCOL;

// 例外ハンドラの登録
typedef
VOID
(EFIAPI *EFI_EXCEPTION_CALLBACK) (
  IN EFI_EXCEPTION_TYPE  ExceptionType,
  IN EFI_SYSTEM_CONTEXT  SystemContext
  );

typedef
EFI_STATUS
(EFIAPI *EFI_REGISTER_EXCEPTION_CALLBACK) (
  IN EFI_DEBUG_SUPPORT_PROTOCOL  *This,
  IN UINTN                       ProcessorIndex,
  IN EFI_EXCEPTION_CALLBACK      ExceptionCallback,
  IN EFI_EXCEPTION_TYPE          ExceptionType
  );
```

### デバッグ例外の処理

```c
// INT3 (ブレークポイント) ハンドラの実装例
VOID
EFIAPI
DebugExceptionHandler (
  IN EFI_EXCEPTION_TYPE  ExceptionType,
  IN EFI_SYSTEM_CONTEXT  SystemContext
  )
{
  EFI_SYSTEM_CONTEXT_X64  *Context = SystemContext.SystemContextX64;

  if (ExceptionType == EXCEPT_X64_BREAKPOINT) {  // INT3
    DEBUG((DEBUG_ERROR, "Breakpoint hit at RIP: 0x%lx\n", Context->Rip));

    // ブレークポイント命令 (0xCC) をスキップ
    Context->Rip++;

    // GDB Stub に制御を移す
    GdbStubBreakpointHandler(Context);

  } else if (ExceptionType == EXCEPT_X64_DEBUG) {  // Single Step
    DEBUG((DEBUG_ERROR, "Single step at RIP: 0x%lx\n", Context->Rip));

    // TF フラグをクリア
    Context->Rflags &= ~BIT8;

    GdbStubSingleStepHandler(Context);
  }
}

// プロトコルのインストール例
EFI_STATUS
EFIAPI
InstallDebugSupport (
  IN EFI_HANDLE  ImageHandle
  )
{
  EFI_STATUS                  Status;
  EFI_DEBUG_SUPPORT_PROTOCOL  *DebugSupport;

  // プロトコルを取得
  Status = gBS->LocateProtocol(
    &gEfiDebugSupportProtocolGuid,
    NULL,
    (VOID **)&DebugSupport
  );
  if (EFI_ERROR(Status)) {
    return Status;
  }

  // ブレークポイント例外ハンドラを登録
  Status = DebugSupport->RegisterExceptionCallback(
    DebugSupport,
    0,  // Processor 0
    DebugExceptionHandler,
    EXCEPT_X64_BREAKPOINT
  );

  // シングルステップ例外ハンドラを登録
  Status = DebugSupport->RegisterExceptionCallback(
    DebugSupport,
    0,
    DebugExceptionHandler,
    EXCEPT_X64_DEBUG
  );

  return EFI_SUCCESS;
}
```

---

## シンボル情報とデバッグ情報

### DWARF デバッグフォーマット

DWARF (Debugging With Attributed Record Formats) は、ELF バイナリに埋め込まれるデバッグ情報の標準フォーマットです。

#### DWARF セクション

| セクション | 内容 |
|----------|------|
| `.debug_info` | 変数、関数、型の情報 |
| `.debug_abbrev` | 情報の省略形定義 |
| `.debug_line` | ソースコード行番号マッピング |
| `.debug_str` | 文字列テーブル |
| `.debug_loc` | 変数の位置情報 |
| `.debug_ranges` | アドレス範囲情報 |
| `.debug_frame` | スタックフレーム情報 |

#### DWARF 情報の読み取り

```bash
# DWARF 情報の表示
readelf --debug-dump=info DxeCore.dll

# 出力例:
# <1><2d>: Abbrev Number: 3 (DW_TAG_subprogram)
#    <2e>   DW_AT_name        : DxeMain
#    <35>   DW_AT_decl_file   : 1
#    <36>   DW_AT_decl_line   : 123
#    <38>   DW_AT_type        : <0x45>
#    <3c>   DW_AT_low_pc      : 0x7f800000
#    <44>   DW_AT_high_pc     : 0x7f800100

# 行番号マッピング
readelf --debug-dump=line DxeCore.dll

# 出力例:
# Line Number Statements:
#   [0x00000000]  Set column to 1
#   [0x00000000]  Extended opcode 2: set Address to 0x7f800000
#   [0x00000005]  Special opcode 14: advance Address by 0 to 0x7f800000 and Line by 123 to 123
#   [0x00000006]  Special opcode 76: advance Address by 5 to 0x7f800005 and Line by 1 to 124
```

### GDB でのシンボル情報の利用

```bash
# シンボルファイルのロード
(gdb) symbol-file Build/OvmfX64/DEBUG_GCC5/X64/MdeModulePkg/Core/Dxe/DxeMain/DEBUG/DxeCore.dll

# ソースコードレベルでのブレークポイント設定
(gdb) break DxeMain.c:123
Breakpoint 1 at 0x7f800010: file DxeMain.c, line 123.

# 変数の表示
(gdb) print HobStart
$1 = (VOID *) 0x7f000000

# 型情報を使った表示
(gdb) print *(EFI_HOB_HANDOFF_INFO_TABLE *)HobStart
$2 = {
  Header = {
    HobType = 0x1,
    HobLength = 0x38,
    Reserved = 0x0
  },
  Version = 0x9,
  ...
}

# ローカル変数の一覧
(gdb) info locals
Status = 0
CoreData = 0x7f850000
MemoryBaseAddress = 0x100000
MemoryLength = 0x7f000000
```

### PE/COFF デバッグ情報 (CodeView)

UEFI モジュールは PE/COFF フォーマットを使用し、Microsoft CodeView 形式のデバッグ情報を含むことがあります。

```c
// PE/COFF Debug Directory Entry
typedef struct {
  UINT32  Characteristics;
  UINT32  TimeDateStamp;
  UINT16  MajorVersion;
  UINT16  MinorVersion;
  UINT32  Type;           // IMAGE_DEBUG_TYPE_CODEVIEW
  UINT32  SizeOfData;
  UINT32  AddressOfRawData;
  UINT32  PointerToRawData;
} IMAGE_DEBUG_DIRECTORY;

// CodeView Debug Info (RSDS 形式)
typedef struct {
  UINT32  Signature;      // 'RSDS' (0x53445352)
  GUID    Guid;           // モジュールGUID
  UINT32  Age;
  CHAR8   PdbFileName[1]; // PDB ファイル名（可変長）
} CODEVIEW_RSDS;
```

---

## プロファイリングツールの仕組み

### サンプリングベースプロファイリング

```mermaid
graph TB
    A[タイマー割り込み<br/>毎 1ms] --> B[現在の RIP を記録]
    B --> C[サンプル蓄積]
    C --> D[統計処理]
    D --> E[ホットスポット特定]

    E --> E1[関数Aが 40% の時間を占める]
    E --> E2[関数Bが 25% の時間を占める]
    E --> E3[関数Cが 15% の時間を占める]
```

#### サンプリングプロファイラの実装

```c
// サンプリングプロファイラ
#define MAX_SAMPLES  10000

typedef struct {
  UINT64  Rip;
  UINT64  Timestamp;
} PROFILE_SAMPLE;

PROFILE_SAMPLE  gSamples[MAX_SAMPLES];
UINTN           gSampleCount = 0;

VOID
EFIAPI
ProfilerTimerHandler (
  IN EFI_EVENT  Event,
  IN VOID       *Context
  )
{
  if (gSampleCount >= MAX_SAMPLES) {
    return;
  }

  // 現在の RIP を記録
  UINT64 Rip = GetCurrentRip();  // アーキテクチャ依存
  gSamples[gSampleCount].Rip = Rip;
  gSamples[gSampleCount].Timestamp = GetPerformanceCounter();
  gSampleCount++;
}

VOID
StartProfiling (
  VOID
  )
{
  EFI_STATUS  Status;
  EFI_EVENT   TimerEvent;

  // 1ms ごとにタイマーイベント
  Status = gBS->CreateEvent(
    EVT_TIMER | EVT_NOTIFY_SIGNAL,
    TPL_HIGH_LEVEL,
    ProfilerTimerHandler,
    NULL,
    &TimerEvent
  );

  Status = gBS->SetTimer(
    TimerEvent,
    TimerPeriodic,
    EFI_TIMER_PERIOD_MILLISECONDS(1)
  );
}

VOID
AnalyzeProfiling (
  VOID
  )
{
  // RIP をアドレスごとに集計
  UINT64  AddressCount[1000] = {0};

  for (UINTN i = 0; i < gSampleCount; i++) {
    UINT64 Rip = gSamples[i].Rip;
    // アドレスを関数単位に丸める
    UINT64 FunctionBase = GetFunctionBase(Rip);
    AddressCount[FunctionBase % 1000]++;
  }

  // トップ10を表示
  DEBUG((DEBUG_INFO, "Profile Results:\n"));
  for (UINTN i = 0; i < 10; i++) {
    UINT64 MaxAddr = 0;
    UINT64 MaxCount = 0;
    for (UINTN j = 0; j < 1000; j++) {
      if (AddressCount[j] > MaxCount) {
        MaxCount = AddressCount[j];
        MaxAddr = j;
      }
    }
    if (MaxCount > 0) {
      DEBUG((DEBUG_INFO, "  0x%lx: %d samples (%.2f%%)\n",
             MaxAddr,
             MaxCount,
             (DOUBLE)MaxCount / gSampleCount * 100.0));
      AddressCount[MaxAddr] = 0;  // 処理済みマーク
    }
  }
}
```

### インストルメンテーションベースプロファイリング

```c
// 関数の開始・終了を記録
#define PROFILE_FUNCTION_ENTER(name) \
  UINT64 __start_##name = GetPerformanceCounter(); \
  DEBUG((DEBUG_VERBOSE, ">> %a\n", #name))

#define PROFILE_FUNCTION_EXIT(name) \
  do { \
    UINT64 __end = GetPerformanceCounter(); \
    UINT64 __elapsed = __end - __start_##name; \
    DEBUG((DEBUG_VERBOSE, "<< %a: %ld ticks\n", #name, __elapsed)); \
  } while (0)

// 使用例
EFI_STATUS
MyFunction (
  VOID
  )
{
  PROFILE_FUNCTION_ENTER(MyFunction);

  // 処理...
  DoSomething();

  PROFILE_FUNCTION_EXIT(MyFunction);
  return EFI_SUCCESS;
}
```

---

## トレース機能

### ARM CoreSight ETM (Embedded Trace Macrocell)

ARM プロセッサには、命令トレース機能が組み込まれています。

```mermaid
graph LR
    A[CPU Core] -->|命令実行情報| B[ETM]
    B -->|圧縮トレースデータ| C[ETB/ETF<br/>Trace Buffer]
    B -->|TPIU| D[SWO Pin]
    C -->|AXI| E[System Memory]
    D -->|シリアル出力| F[デバッグホスト]
    E --> F
```

**ETM の利点**:
- 実時間での命令フロー記録
- ブレークポイントなしでの実行解析
- 分岐予測ミスの検出
- カバレッジ測定

### Intel Processor Trace (PT)

Intel CPU には、ハードウェアベースのトレース機能があります。

```c
// Intel PT の有効化（簡略版）
VOID EnableIntelPT(VOID) {
  UINT64 Ia32RtitCtl;

  // IA32_RTIT_CTL MSR (0x570)
  Ia32RtitCtl = AsmReadMsr64(0x570);

  // TraceEn ビットを設定
  Ia32RtitCtl |= BIT0;  // TraceEn
  Ia32RtitCtl |= BIT1;  // CYCEn (サイクルカウント有効)
  Ia32RtitCtl |= BIT2;  // OS
  Ia32RtitCtl |= BIT3;  // User

  AsmWriteMsr64(0x570, Ia32RtitCtl);

  // トレース出力先（ToPA: Table of Physical Addresses）
  // IA32_RTIT_OUTPUT_BASE MSR (0x560)
  AsmWriteMsr64(0x560, (UINT64)(UINTN)gTraceBuffer);

  // トレース領域マスク
  // IA32_RTIT_OUTPUT_MASK_PTRS MSR (0x561)
  AsmWriteMsr64(0x561, TRACE_BUFFER_SIZE - 1);
}
```

---

## 💻 演習

### 演習 1: GDB リモートプロトコルの実装

簡単な GDB Stub を実装し、QEMU 上で動作させてください。

**要件**:
1. 'g' (レジスタ読み取り) コマンドの実装
2. 'm' (メモリ読み取り) コマンドの実装
3. 'c' (実行継続) コマンドの実装

**ヒント**:
```c
VOID GdbStubMain(VOID) {
  while (1) {
    ReceivePacket(buffer);
    switch (buffer[0]) {
      case 'g': HandleReadRegisters(); break;
      case 'm': HandleReadMemory(); break;
      case 'c': return;  // 実行継続
    }
  }
}
```

### 演習 2: プロファイリング機能の追加

タイマーベースのサンプリングプロファイラを実装し、以下を測定してください。

1. 各関数の実行時間の割合
2. 最もホットな関数トップ5
3. 関数呼び出しの階層

### 演習 3: DWARF 情報の解析

`readelf` を使って、EDK II モジュールのデバッグ情報を解析してください。

```bash
# 1. シンボルテーブルの表示
readelf -s DxeCore.dll | grep FUNC

# 2. DWARF 情報の表示
readelf --debug-dump=info DxeCore.dll | less

# 3. 行番号情報の抽出
readelf --debug-dump=line DxeCore.dll > lines.txt
```

---

## まとめ

本章では、デバッグツールの内部動作原理を深く掘り下げ、ハードウェアデバッガ、GDB リモートプロトコル、UEFI デバッグサポート、シンボル情報、プロファイリング・トレース機構の仕組みを学びました。これらの技術的な詳細を理解することで、デバッグツールをより効果的に使いこなし、複雑な問題にも対処できるようになります。

**JTAG（Joint Test Action Group）** は、IEEE 1149.1 規格として定義されたハードウェアデバッグインターフェースであり、5 本の信号線（TCK クロック、TMS モード選択、TDI データ入力、TDO データ出力、TRST リセット）を使用します。JTAG の核心は **TAP（Test Access Port）ステートマシン** であり、TMS 信号によって状態遷移を制御し、命令レジスタ（IR）やデータレジスタ（DR）にアクセスします。TAP ステートマシンは、Test-Logic-Reset 状態から始まり、Select-DR-Scan → Capture-DR → Shift-DR → Exit1-DR → Update-DR というシーケンスでデータレジスタを読み書きし、同様に IR スキャンで命令を設定します。このステートマシンの理解は、JTAG デバッガの動作を把握する上で不可欠です。一方、**ARM SWD（Serial Wire Debug）** は、2 本の信号線（SWDCLK クロック、SWDIO 双方向データ）で同等のデバッグ機能を実現し、ピン数を削減しています。SWD パケットは、Start、APnDP（Debug Port か Access Port か）、RnW（読み取りか書き込みか）、Address、Parity、Stop、Park の各ビットで構成され、コンパクトなプロトコルでレジスタやメモリにアクセスします。

**GDB リモートプロトコル（RSP）** は、GDB クライアントと GDB Stub 間の通信を定義する標準プロトコルです。すべてのパケットは `$<data>#<checksum>` という形式で、チェックサムはデータ部の各バイトの合計を 256 で割った余りの 2 桁 HEX 表現です。主要なコマンドとして、`$g#67` でレジスタ全体を読み取り、`$m<addr>,<len>#XX` で指定アドレスからメモリを読み取り、`$Z0,<addr>,<kind>#XX` でソフトウェアブレークポイントを設定し、`$c#63` で実行を継続します。GDB Stub は、これらのコマンドを受信し、実際のレジスタ・メモリアクセスを行い、結果を返します。QEMU や OpenOCD は GDB Stub として機能し、GDB から `target remote localhost:1234` で接続するだけで、リモートデバッグが可能になります。GDB Stub を自作する場合、パケットの受信・解析・応答送信の基本ループを実装し、レジスタとメモリのアクセス関数を提供すれば、最小限の機能が実現できます。

**UEFI デバッグサポート**は、`EFI_DEBUG_SUPPORT_PROTOCOL` として定義され、プロセッサアーキテクチャ固有のデバッグ機能にアクセスする標準インターフェースを提供します。このプロトコルを使用することで、ブレークポイント例外（EXCEPT_X64_BREAKPOINT、INT3 命令）やシングルステップ例外（EXCEPT_X64_DEBUG、RFLAGS.TF ビット）に対するカスタム例外ハンドラを登録できます。例外ハンドラは、`EFI_SYSTEM_CONTEXT` 構造体を通じて、すべてのレジスタ（RAX、RBX、RCX、RDX、RSI、RDI、RBP、RSP、R8-R15、RIP、RFLAGS、セグメントレジスタ）にアクセスでき、レジスタの値を変更することも可能です。ブレークポイントヒット時には、RIP を 1 バイト進めて INT3 命令（0xCC）をスキップし、GDB Stub に制御を移します。シングルステップ実行では、RFLAGS.TF ビット（BIT8）をセットして実行を再開し、1 命令実行後に再び例外ハンドラが呼ばれます。このように、UEFI デバッグサポートは、OS が存在しない環境でも高度なデバッグ機能を実現する基盤となります。

**DWARF（Debugging With Attributed Record Formats）** は、ELF バイナリに埋め込まれるデバッグ情報の標準フォーマットであり、複数のセクションで構成されます。`.debug_info` セクションには、変数・関数・型の詳細情報（名前、型、スコープ、アドレス範囲）が含まれ、`.debug_line` セクションには、機械語命令アドレスとソースコード行番号のマッピングが記録されます。`.debug_frame` セクションには、スタックフレームの巻き戻し（Unwinding）情報が含まれ、バックトレースの生成に使用されます。GDB は、これらの DWARF 情報を読み取ることで、`break DxeMain.c:123` のようなソースコードレベルでのブレークポイント設定や、`print HobStart` のような変数名での表示を実現します。`readelf --debug-dump=info` や `readelf --debug-dump=line` コマンドで、DWARF 情報の内容を確認できます。一方、UEFI モジュールは **PE/COFF フォーマット**を使用し、**CodeView** 形式（RSDS 署名）のデバッグ情報を含むことがあります。CodeView デバッグディレクトリには、モジュール GUID や PDB ファイル名が記録され、Windows デバッガ（WinDbg）との連携に使用されます。

**プロファイリング機構**には、サンプリングベースとインストルメンテーションベースの 2 つの主要なアプローチがあります。**サンプリングベースプロファイリング**は、定期的なタイマー割り込み（例: 1ms ごと）で現在のプログラムカウンタ（RIP）を記録し、統計的にホットスポットを特定します。この手法は、オーバーヘッドが小さく（通常 1-5%）、実環境でも使用できるのが利点です。記録されたサンプルを集計し、各関数のアドレス範囲ごとにカウントすることで、「関数 A が全体の 40% の時間を占める」といった情報が得られます。**インストルメンテーションベースプロファイリング**は、関数の開始・終了時に計測コードを挿入し、パフォーマンスカウンタで正確な実行時間を測定します。この手法は、正確な実行経路とタイミング情報が得られますが、オーバーヘッドが大きく（10-50%）、実環境での使用には注意が必要です。したがって、パフォーマンス問題の大まかな特定にはサンプリング、詳細な分析にはインストルメンテーションを使い分けることが推奨されます。

**ハードウェアトレース機構**は、非侵襲的に詳細な実行フローを記録する強力な手法です。**ARM CoreSight ETM（Embedded Trace Macrocell）** は、CPU コアの命令実行情報を圧縮してトレースバッファ（ETB/ETF）やシステムメモリに記録し、SWO ピン経由でデバッグホストに送信します。ETM は、実時間での命令フロー記録、分岐予測ミスの検出、コードカバレッジ測定といった高度な解析を可能にします。**Intel Processor Trace (PT)** は、Intel CPU に組み込まれたハードウェアトレース機能であり、IA32_RTIT_CTL MSR（0x570）で有効化します。PT は、実行された分岐命令の方向（taken/not-taken）やターゲットアドレスを記録し、後でデコードすることで完全な実行フローを再構築できます。トレースデータは、ToPA（Table of Physical Addresses）で指定したメモリ領域に書き込まれます。これらのハードウェアトレース機構は、タイミング問題やレアケースのバグ調査に非常に有効であり、ソフトウェアベースのデバッグでは困難な問題にも対処できます。

デバッグツールの選択は、開発フェーズや問題の性質によって異なります。**初期開発**では、GDB + QEMU の組み合わせが高速なイテレーションを可能にし、ソースコードレベルでのデバッグが容易です。**ハードウェア依存のバグ**（特定のチップセットやペリフェラルに関連する問題）では、JTAG/SWD デバッガを使用し、実機で詳細に制御しながらデバッグします。**パフォーマンス問題**では、サンプリングプロファイラでホットスポットを特定し、オーバーヘッドを最小限に抑えます。**コードカバレッジ測定**では、インストルメンテーションベースの手法で正確な実行経路を記録します。**タイミング依存の問題**（Race Condition、Heisenbug）では、ETM や Intel PT といったハードウェアトレースを使用し、非侵襲的に実行フローを記録します。このように、各ツールの特性を理解し、状況に応じて適切に使い分けることが、効率的なデバッグの鍵となります。

---

次章では、ファームウェアで頻繁に遭遇する典型的な問題パターンとその原因について解説します。

📚 **参考資料**
- [JTAG IEEE 1149.1 Specification](https://standards.ieee.org/standard/1149_1-2013.html)
- [ARM Debug Interface Architecture Specification](https://developer.arm.com/documentation/ihi0031/latest/)
- [GDB Remote Serial Protocol](https://sourceware.org/gdb/current/onlinedocs/gdb/Remote-Protocol.html)
- [DWARF Debugging Standard](https://dwarfstd.org/)
- [Intel 64 and IA-32 Architectures Software Developer Manuals](https://www.intel.com/sdm)
