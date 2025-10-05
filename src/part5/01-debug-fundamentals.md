# ファームウェアデバッグの基礎

🎯 **この章で学ぶこと**
- ファームウェアデバッグの特殊性と課題
- デバッグ環境の構築方法
- シリアルポートを使った基本的なデバッグ手法
- QEMU を使ったエミュレーション環境でのデバッグ
- 実機デバッグの準備と注意点

📚 **前提知識**
- [Part 0: 開発環境の構築](../part0/README.md)
- [Part I: x86_64 ブート基礎](../part1/README.md)
- [Part II: EDK II 実装](../part2/README.md)

---

## ファームウェアデバッグの特殊性

ファームウェアのデバッグは、アプリケーション開発とは大きく異なる独自の課題を抱えています。

### アプリケーションデバッグとの違い

| 観点 | アプリケーション | ファームウェア |
|------|----------------|--------------|
| **実行環境** | OS カーネル上 | ベアメタル（OS なし） |
| **デバッガ** | gdb, Visual Studio など | JTAG, シリアル、エミュレータ |
| **出力手段** | printf, ログファイル | シリアルポート、POST コード |
| **メモリ保護** | あり（ページング、ASLR） | なし（物理アドレス直接アクセス） |
| **クラッシュ時** | コアダンプ、スタックトレース | 即座にハング、再起動 |
| **再現性** | 比較的高い | 低い（タイミング依存が多い） |
| **デバッグサイクル** | 数秒～数分 | 数分～数十分（書き込み時間含む） |

### ファームウェアデバッグ固有の課題

```mermaid
graph TB
    A[ファームウェアデバッグの課題] --> B[環境の制約]
    A --> C[可視性の欠如]
    A --> D[タイミング依存]
    A --> E[再現性の低さ]

    B --> B1[OS が存在しない]
    B --> B2[標準ライブラリがない]
    B --> B3[メモリが限られている]

    C --> C1[画面出力がない<br/>PEI/SEC段階]
    C --> C2[スタックトレースが<br/>取得困難]
    C --> C3[変数の内容が<br/>見えない]

    D --> D1[ハードウェア初期化の<br/>タイミング]
    D --> D2[割り込みの影響]
    D --> D3[マルチコアの同期]

    E --> E1[特定のハードウェアでのみ発生]
    E --> E2[電源状態に依存]
    E --> E3[温度やクロックに影響される]
```

---

## デバッグ環境の階層

ファームウェアのデバッグには、複数の環境を組み合わせて使用します。

### デバッグ環境の種類

```mermaid
graph LR
    A[デバッグ環境] --> B[エミュレーション]
    A --> C[仮想化]
    A --> D[実機]

    B --> B1[QEMU]
    B --> B2[Simics]

    C --> C1[VMware/VirtualBox<br/>UEFI サポート]

    D --> D1[開発ボード]
    D --> D2[量産機]

    B1 --> E1[完全制御<br/>高速イテレーション]
    C1 --> E2[準実環境<br/>手軽さ]
    D1 --> E3[実ハードウェア<br/>最終検証]

    style B1 fill:#afa,stroke:#0a0
    style C1 fill:#ffa,stroke:#fa0
    style D1 fill:#faa,stroke:#f00
```

### 環境ごとの用途

| 環境 | 用途 | メリット | デメリット |
|------|------|---------|----------|
| **QEMU** | 初期開発、機能実装 | 高速、完全制御、再現性高 | ハードウェアの細部は再現されない |
| **仮想マシン** | OS ブート検証、統合テスト | 手軽、スナップショット可能 | UEFI 機能に制限あり |
| **開発ボード** | ハードウェア依存機能の実装 | 実ハードウェアで検証可能 | 高価、セットアップが複雑 |
| **量産機** | 最終検証、バグ再現 | 実環境と同一 | デバッグ機能が制限される |

---

## シリアルデバッグの基礎

最も基本的で重要なデバッグ手法がシリアルポート経由のログ出力です。

### シリアルポートの役割

```mermaid
sequenceDiagram
    participant FW as Firmware<br/>(UEFI BIOS)
    participant UART as UART Controller<br/>(COM1: 0x3F8)
    participant Serial as シリアルケーブル
    participant Host as ホスト PC<br/>(minicom/PuTTY)

    FW->>FW: DEBUG((DEBUG_INFO, "Boot started"))
    FW->>UART: 文字列を送信
    UART->>Serial: RS-232C 信号
    Serial->>Host: USB-Serial 変換
    Host->>Host: ターミナルに表示
```

### シリアルポートの設定

#### UEFI 側の設定 (.dsc ファイル)

```ini
[PcdsFixedAtBuild]
  # シリアルポートの基本設定
  gEfiMdeModulePkgTokenSpaceGuid.PcdSerialUseMmio|FALSE
  gEfiMdeModulePkgTokenSpaceGuid.PcdSerialRegisterBase|0x3F8
  gEfiMdeModulePkgTokenSpaceGuid.PcdSerialBaudRate|115200
  gEfiMdeModulePkgTokenSpaceGuid.PcdSerialLineControl|0x03  # 8N1
  gEfiMdeModulePkgTokenSpaceGuid.PcdSerialFifoControl|0x07  # FIFO enabled
  gEfiMdeModulePkgTokenSpaceGuid.PcdSerialDetectCable|FALSE
  gEfiMdeModulePkgTokenSpaceGuid.PcdSerialRegisterStride|1

  # デバッグレベルの設定
  gEfiMdePkgTokenSpaceGuid.PcdDebugPrintErrorLevel|0x8000004F
  # 0x80000000 = DEBUG_ERROR
  # 0x00000040 = DEBUG_INFO
  # 0x00000008 = DEBUG_WARN
  # 0x00000004 = DEBUG_LOAD
  # 0x00000002 = DEBUG_FS
  # 0x00000001 = DEBUG_INIT

  # デバッグプロパティ
  gEfiMdePkgTokenSpaceGuid.PcdDebugPropertyMask|0x1F
  # 0x01 = DEBUG_PROPERTY_DEBUG_ASSERT_ENABLED
  # 0x02 = DEBUG_PROPERTY_DEBUG_PRINT_ENABLED
  # 0x04 = DEBUG_PROPERTY_DEBUG_CODE_ENABLED
  # 0x08 = DEBUG_PROPERTY_CLEAR_MEMORY_ENABLED
  # 0x10 = DEBUG_PROPERTY_ASSERT_DEADLOOP_ENABLED
```

#### デバッグ出力の例

```c
// MyDriver.c
#include <Uefi.h>
#include <Library/UefiLib.h>
#include <Library/DebugLib.h>

EFI_STATUS
EFIAPI
MyDriverEntry (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  EFI_STATUS  Status;

  //
  // デバッグ出力の基本形
  //
  DEBUG((DEBUG_INFO, "MyDriver: Entry point called\n"));

  //
  // 変数の値を出力
  //
  UINTN  MemorySize = 0x100000;
  DEBUG((DEBUG_INFO, "Memory size: 0x%lx (%ld bytes)\n",
         MemorySize, MemorySize));

  //
  // 条件付きデバッグ
  //
  if (ImageHandle == NULL) {
    DEBUG((DEBUG_ERROR, "ERROR: ImageHandle is NULL!\n"));
    ASSERT(ImageHandle != NULL);  // Assert も出力される
    return EFI_INVALID_PARAMETER;
  }

  //
  // ポインタの値を出力
  //
  DEBUG((DEBUG_VERBOSE, "ImageHandle: 0x%p\n", ImageHandle));
  DEBUG((DEBUG_VERBOSE, "SystemTable: 0x%p\n", SystemTable));

  //
  // GUID の出力
  //
  EFI_GUID  TestGuid = { 0x12345678, 0x1234, 0x5678,
                         { 0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0 } };
  DEBUG((DEBUG_INFO, "GUID: %g\n", &TestGuid));

  //
  // Unicode 文字列の出力
  //
  CHAR16  *DevicePath = L"\\EFI\\BOOT\\BOOTX64.EFI";
  DEBUG((DEBUG_INFO, "Device path: %s\n", DevicePath));

  Status = DoSomething();
  if (EFI_ERROR(Status)) {
    DEBUG((DEBUG_ERROR, "DoSomething failed: %r\n", Status));
    // %r はEFI_STATUS を文字列化（例: "Not Found"）
    return Status;
  }

  DEBUG((DEBUG_INFO, "MyDriver: Initialization complete\n"));
  return EFI_SUCCESS;
}
```

### ホスト側のシリアル受信設定

#### Linux での設定 (minicom)

```bash
# minicom のインストール
sudo apt install minicom

# シリアルポート権限の付与
sudo usermod -a -G dialout $USER
# ログアウト・ログインが必要

# minicom 設定
sudo minicom -s

# 設定内容:
# Serial port setup:
#   A - Serial Device: /dev/ttyUSB0
#   E - Baud rate: 115200 8N1
#   F - Hardware Flow Control: No
#   G - Software Flow Control: No

# 設定を保存して終了後、接続
minicom -D /dev/ttyUSB0 -b 115200
```

#### Windows での設定 (PuTTY)

```
PuTTY Configuration:
  Connection type: Serial
  Serial line: COM3 (デバイスマネージャーで確認)
  Speed: 115200

Session > Logging:
  Session logging: All session output
  Log file name: C:\uefi_debug.log
```

### 実際の出力例

```
PROGRESS CODE: V03020002 I0
PROGRESS CODE: V03020003 I0
SecCoreStartupWithStack(0xFFFCC000, 0x820000)
SEC: Normal boot
PeiCoreImageHandle: 0xFFFC1010
PeiCoreEntryPoint: 0xFFFC5000
Install PPI: 8C8CE578-8A3D-4F1C-9935-896185C32DD3 (gEfiPeiMemoryDiscoveredPpiGuid)
Install PPI: 49EDB1C1-BF21-4761-BB12-EB0031AABB39 (gEfiPeiResetPpiGuid)
Temp RAM: BaseAddress=0xFEF00000 Length=0x10000
Heap: BaseAddress=0xFEF08000 Length=0x6000
Stack: BaseAddress=0xFEF00000 Length=0x8000
PEI Phase started...
Install PPI: 8D8A88FF-2E1C-4677-8DD8-A8A48B39C3BB (gEfiPeiBootInRecoveryModePpiGuid)

DXE Core Entry Point: 0x7F800000
DXE: Loading drivers...
Loading driver 80CF7257-87AB-47F9-A3FE-D50B76D89541 (PcdDxe)
  - InstallProtocolInterface: 13A3F0F6-264A-3EF0-F2E0-DEC512342F34 (gPcdProtocolGuid)
Loading driver D93CE3D8-A7EB-4730-8C8F-917C23B3F2F2 (RuntimeDxe)
  - InstallProtocolInterface: B7DFB4E1-052F-449F-87BE-9818FC91B733 (gEfiRuntimeArchProtocolGuid)
```

---

## QEMU エミュレーション環境でのデバッグ

### QEMU の起動オプション

```bash
#!/bin/bash
# debug_qemu.sh - QEMU デバッグセッション起動スクリプト

OVMF_CODE=/usr/share/OVMF/OVMF_CODE.fd
OVMF_VARS=/usr/share/OVMF/OVMF_VARS.fd
DISK_IMAGE=test.img

qemu-system-x86_64 \
  -machine q35 \
  -cpu qemu64 \
  -m 2048 \
  -drive if=pflash,format=raw,readonly=on,file=${OVMF_CODE} \
  -drive if=pflash,format=raw,file=${OVMF_VARS} \
  -drive format=raw,file=${DISK_IMAGE} \
  -serial stdio \
  -debugcon file:debug.log \
  -global isa-debugcon.iobase=0x402 \
  -monitor unix:/tmp/qemu-monitor,server,nowait \
  -S -s
  # -S: 起動時に一時停止
  # -s: GDB サーバーを localhost:1234 で起動
```

**オプション解説**:

| オプション | 説明 |
|----------|------|
| `-serial stdio` | シリアル出力を標準入出力に |
| `-debugcon file:debug.log` | デバッグコンソールをファイルに |
| `-global isa-debugcon.iobase=0x402` | I/O ポート 0x402 をデバッグ出力に |
| `-S` | 起動時に CPU を停止（GDB 接続待ち） |
| `-s` | GDB サーバーを TCP:1234 で起動 |

### GDB を使ったデバッグ

#### GDB の起動と接続

```bash
# GDB を起動
gdb

# QEMU に接続
(gdb) target remote localhost:1234
Remote debugging using localhost:1234
0x000000000000fff0 in ?? ()

# シンボルファイルをロード
(gdb) symbol-file Build/OvmfX64/DEBUG_GCC5/X64/MdeModulePkg/Core/Dxe/DxeMain/DEBUG/DxeCore.dll
Reading symbols from Build/OvmfX64/DEBUG_GCC5/X64/MdeModulePkg/Core/Dxe/DxeMain/DEBUG/DxeCore.dll...

# DxeCore エントリポイントにブレークポイント
(gdb) break DxeMain
Breakpoint 1 at 0x12345: file DxeMain.c, line 123.

# 実行を継続
(gdb) continue
Continuing.

Breakpoint 1, DxeMain (
    HobStart=0x7f000000)
    at /path/to/edk2/MdeModulePkg/Core/Dxe/DxeMain/DxeMain.c:123
123       DEBUG((DEBUG_INFO, "DXE Core Entry Point\n"));

# 変数の表示
(gdb) print HobStart
$1 = (VOID *) 0x7f000000

# スタックトレースの表示
(gdb) backtrace
#0  DxeMain (HobStart=0x7f000000) at DxeMain.c:123
#1  0x000000007f801234 in _ModuleEntryPoint () at AutoGen.c:45

# 次の行に進む
(gdb) next
124       InitializeCore (HobStart);

# 関数内にステップイン
(gdb) step
InitializeCore (HobStart=0x7f000000) at DxeInit.c:89
89        gHobList = HobStart;
```

### デバッグコンソール (DebugCon) の活用

```c
// DebugLib の内部実装例（簡略版）
VOID
EFIAPI
DebugPrint (
  IN  UINTN        ErrorLevel,
  IN  CONST CHAR8  *Format,
  ...
  )
{
  CHAR8    Buffer[256];
  VA_LIST  Marker;
  UINTN    Index;

  // 可変長引数を展開
  VA_START(Marker, Format);
  AsciiVSPrint(Buffer, sizeof(Buffer), Format, Marker);
  VA_END(Marker);

  // DebugCon ポート (0x402) に出力
  for (Index = 0; Buffer[Index] != '\0'; Index++) {
    IoWrite8(0x402, Buffer[Index]);
  }

  // シリアルポート (COM1: 0x3F8) にも出力
  for (Index = 0; Buffer[Index] != '\0'; Index++) {
    SerialPortWrite((UINT8 *)&Buffer[Index], 1);
  }
}
```

**出力先の違い**:

| 出力先 | I/O ポート | 用途 | QEMU オプション |
|-------|-----------|------|----------------|
| **DebugCon** | 0x402 | デバッグ専用（高速） | `-debugcon file:debug.log` |
| **Serial** | 0x3F8 (COM1) | 標準出力、対話も可能 | `-serial stdio` |
| **POST コード** | 0x80 | ブート進行状況 | デフォルトで QEMU 内部ログ |

---

## POST コードによるデバッグ

### POST コードとは

POST (Power-On Self-Test) コードは、ブートプロセスの進行状況を示す 1 バイトの値です。

```c
// POST コードの例
#define POST_CODE_SEC_ENTRY           0x01
#define POST_CODE_PEI_CORE_ENTRY      0x10
#define POST_CODE_MEMORY_INIT         0x15
#define POST_CODE_DXE_CORE_ENTRY      0x30
#define POST_CODE_BDS_ENTRY           0x60
#define POST_CODE_BOOT_DEVICE_SELECT  0x61
#define POST_CODE_OS_HANDOFF          0xA0

// POST コードの出力
VOID
PostCode (
  IN UINT8  Value
  )
{
  IoWrite8(0x80, Value);  // I/O ポート 0x80 に書き込み
}

// 使用例
EFI_STATUS
EFIAPI
PeiCoreEntryPoint (
  IN CONST EFI_PEI_SERVICES  **PeiServices,
  IN EFI_PEI_PPI_DESCRIPTOR  *PpiList
  )
{
  PostCode(POST_CODE_PEI_CORE_ENTRY);  // 0x10 を出力

  // メモリ初期化
  PostCode(POST_CODE_MEMORY_INIT);  // 0x15 を出力

  // ...
}
```

### POST コードカードの使用

物理的な POST コードカード（PCIe または LPC バス接続）は、画面出力がない状態でも進行状況を確認できます。

```
┌─────────────────────┐
│  POST Code Card     │
│  ┌───────────────┐  │
│  │  Segment LED  │  │
│  │   ┌─┐ ┌─┐     │  │
│  │   │1│ │5│     │  │  ← "15" を表示
│  │   └─┘ └─┘     │  │     (Memory Init)
│  └───────────────┘  │
└─────────────────────┘
```

**典型的な POST コードシーケンス**:

```
01 → SEC Entry
0F → Microcode Load
10 → PEI Core Entry
12 → CPU Init
15 → Memory Init
31 → DXE Core Entry
60 → BDS Entry
61 → Boot Device Select
A0 → OS Handoff
```

---

## ASSERT とデッドループ

### ASSERT マクロの動作

```c
// DebugLib.h から抜粋
#define ASSERT(Expression)  \
  do {  \
    if (DebugAssertEnabled()) {  \
      if (!(Expression)) {  \
        _ASSERT(__FILE__, __LINE__, #Expression);  \
      }  \
    }  \
  } while (FALSE)

// ASSERT の実装例
VOID
EFIAPI
_ASSERT (
  IN CONST CHAR8  *FileName,
  IN UINTN        LineNumber,
  IN CONST CHAR8  *Description
  )
{
  // シリアル出力
  DebugPrint(DEBUG_ERROR,
    "ASSERT_EFI_ERROR (Status = %r)\n",
    Status);
  DebugPrint(DEBUG_ERROR,
    "%a(%d): %a\n",
    FileName, LineNumber, Description);

  // スタックトレース（アーキテクチャ依存）
  DumpStackTrace();

  // デッドループに入る
  if (DebugDeadLoopEnabled()) {
    CpuDeadLoop();
  }

  // リセット（デッドループが無効の場合）
  gRT->ResetSystem(EfiResetCold, EFI_ABORTED, 0, NULL);
}

// デッドループの実装
VOID
EFIAPI
CpuDeadLoop (
  VOID
  )
{
  volatile UINTN  Index;

  // 無限ループ（デバッガからの介入を待つ）
  for (Index = 0; ;) {
    // volatile により最適化で削除されない
  }
}
```

### ASSERT の実用例

```c
EFI_STATUS
EFIAPI
AllocateAndInitialize (
  OUT VOID  **Buffer,
  IN  UINTN Size
  )
{
  EFI_STATUS  Status;

  // 入力検証
  ASSERT(Buffer != NULL);  // NULL ポインタチェック
  ASSERT(Size > 0);        // サイズが正の値であることを確認

  *Buffer = AllocatePool(Size);
  if (*Buffer == NULL) {
    DEBUG((DEBUG_ERROR, "AllocatePool failed for size %ld\n", Size));
    return EFI_OUT_OF_RESOURCES;
  }

  ZeroMem(*Buffer, Size);

  return EFI_SUCCESS;
}

// 使用例
VOID TestFunction(VOID) {
  VOID  *MyBuffer;
  EFI_STATUS  Status;

  Status = AllocateAndInitialize(&MyBuffer, 1024);
  ASSERT_EFI_ERROR(Status);  // Status が EFI_SUCCESS でない場合 ASSERT

  // MyBuffer を使用
  // ...

  FreePool(MyBuffer);
}
```

**ASSERT 出力例**:

```
ASSERT_EFI_ERROR (Status = Not Found)
/path/to/edk2/MyPkg/MyDriver/MyDriver.c(123): !EFI_ERROR (Status)

Call Stack:
  0x7F801234 in AllocateAndInitialize() at MyDriver.c:123
  0x7F801456 in TestFunction() at MyDriver.c:145
  0x7F801678 in DriverEntry() at MyDriver.c:200

Entering dead loop...
```

---

## 実機デバッグの準備

### 必要なハードウェア

```mermaid
graph LR
    A[開発PC] -->|USB-Serial| B[シリアルケーブル]
    B -->|RS-232C| C[ターゲットマシン]

    A -->|JTAG/SWD| D[デバッグプローブ]
    D -->|20pin| E[ターゲットマシン<br/>デバッグヘッダ]

    F[POST カード] -->|PCIe/LPC| C

    style A fill:#afa,stroke:#0a0
    style C fill:#faa,stroke:#f00
```

**推奨ハードウェア**:

| 項目 | 製品例 | 用途 |
|------|-------|------|
| **USB-Serial アダプタ** | FTDI FT232RL | シリアルログ取得 |
| **POST カード** | PC POST Card (LPC/PCIe) | ハング時の状態確認 |
| **JTAG/SWD プローブ** | Segger J-Link, Lauterbach | ハードウェアデバッグ |
| **ロジックアナライザ** | Saleae Logic 8 | バス信号解析 |

### BIOS 書き込みツール

```bash
# flashrom - Linux でのSPI Flash 書き込み
sudo flashrom -p internal -r backup.bin     # バックアップ
sudo flashrom -p internal -w new_bios.bin   # 書き込み
sudo flashrom -p internal -v new_bios.bin   # ベリファイ

# 外部プログラマ使用（CH341A など）
sudo flashrom -p ch341a_spi -r backup.bin
sudo flashrom -p ch341a_spi -w new_bios.bin

# Intel CSME/AMD PSP を含む場合の注意
# → ME/PSP 領域を保護して BIOS 領域のみ更新
sudo flashrom -p internal --ifd -i bios -w new_bios.bin
```

### 実機デバッグ時の注意点

**⚠️ 重要な注意事項**:

1. **必ずバックアップを取る**: BIOS 書き込み前に必ず元のイメージを保存
2. **電源管理**: 書き込み中に電源を切らない（ブリック の原因）
3. **WP# ピン**: ハードウェアライトプロテクトが有効な場合は無効化が必要
4. **ME/PSP 領域**: Intel ME や AMD PSP 領域は通常触らない
5. **リカバリ手段の確保**: SPI Flash プログラマを用意しておく

---

## デバッグワークフロー

### 典型的なデバッグサイクル

```mermaid
graph TB
    A[問題発生] --> B{再現性は？}

    B -->|常に再現| C[QEMU で再現を試みる]
    B -->|時々再現| D[ログを大量に仕込む]

    C -->|再現成功| E[GDB でデバッグ]
    C -->|再現失敗| F[実機固有の問題<br/>シリアルログで追跡]

    E --> G[原因特定]
    F --> G

    D --> H[統計的に分析]
    H --> G

    G --> I[修正実装]
    I --> J[QEMU でテスト]
    J -->|OK| K[実機でテスト]
    K -->|OK| L[完了]
    K -->|NG| D

    J -->|NG| I
```

### ステップ・バイ・ステップデバッグ

**ケーススタディ: 起動時にハングする問題**

```
症状: DXE Phase で進行が止まる
POST コード: 0x35 で停止
シリアルログ: "Install Protocol: ..." の後に出力なし
```

**デバッグ手順**:

1. **POST コードから位置を特定**
   ```
   0x30: DXE Core Entry
   0x35: Loading drivers ← ここで停止
   ```

2. **シリアルログを詳細化**
   ```c
   // DxeMain.c に詳細ログを追加
   DEBUG((DEBUG_INFO, "Loading driver %g\n", &DriverGuid));
   DEBUG((DEBUG_INFO, "  Entry point: 0x%lx\n", EntryPoint));

   Status = EntryPoint(ImageHandle, SystemTable);

   DEBUG((DEBUG_INFO, "  Driver returned: %r\n", Status));
   ```

3. **ログから原因を特定**
   ```
   Loading driver 12345678-1234-1234-1234-123456789ABC
     Entry point: 0x7F850000
   [ここで停止 → このドライバのEntryPointで問題発生]
   ```

4. **該当ドライバを無効化**
   ```ini
   # .dsc ファイルで該当ドライバをコメントアウト
   # MyPkg/ProblematicDriver/ProblematicDriver.inf
   ```

5. **起動確認 → 原因ドライバを特定**

6. **ドライバ内部をデバッグ**
   ```c
   EFI_STATUS
   EFIAPI
   ProblematicDriverEntry (...)
   {
     DEBUG((DEBUG_INFO, "ProblematicDriver: Start\n"));

     // この行まで実行されているか？
     DEBUG((DEBUG_INFO, "Before InitializeHardware\n"));
     InitializeHardware();

     // ここまで到達していない → InitializeHardware が原因
     DEBUG((DEBUG_INFO, "After InitializeHardware\n"));

     return EFI_SUCCESS;
   }
   ```

7. **根本原因を特定 → 修正**

---

## 💻 演習

### 演習 1: デバッグ環境の構築

QEMU + GDB のデバッグ環境を構築し、以下を実行してください。

1. OVMF (EDK II for QEMU) をビルド
2. QEMU を `-S -s` オプション付きで起動
3. GDB で接続し、`DxeMain` にブレークポイントを設定
4. 実行を再開し、ブレークポイントで停止することを確認
5. 変数 `HobStart` の値を確認

### 演習 2: シリアルデバッグの実践

簡単な UEFI アプリケーションを作成し、以下のデバッグ出力を実装してください。

1. `DEBUG_INIT` レベルでエントリポイントの実行を記録
2. `DEBUG_INFO` レベルで処理の進行状況を記録
3. `DEBUG_WARN` レベルで警告を記録
4. `DEBUG_ERROR` レベルでエラーを記録
5. QEMU のシリアル出力でログを確認

**ヒント**:
```c
DEBUG((DEBUG_INIT, "Application started\n"));
DEBUG((DEBUG_INFO, "Processing step 1...\n"));
DEBUG((DEBUG_WARN, "Unusual condition detected\n"));
DEBUG((DEBUG_ERROR, "Critical error occurred\n"));
```

### 演習 3: ASSERT の動作確認

意図的に ASSERT を発生させるコードを書き、その動作を観察してください。

```c
EFI_STATUS TestAssert(VOID) {
  VOID  *NullPointer = NULL;

  // 以下の ASSERT が発動する
  ASSERT(NullPointer != NULL);

  return EFI_SUCCESS;
}
```

出力されるファイル名、行番号、スタックトレースを確認してください。

---

## まとめ

本章では、ファームウェアデバッグの基礎として以下を学びました。

### 重要なポイント

| トピック | 重要事項 |
|---------|---------|
| **デバッグ環境** | QEMU（開発）→ 仮想マシン（統合）→ 実機（検証）の3段階 |
| **シリアルデバッグ** | 最も基本的で重要。常に有効化しておく |
| **GDB デバッグ** | QEMU 環境で強力。シンボル情報が必須 |
| **POST コード** | ハング時の位置特定に不可欠 |
| **ASSERT** | 異常を早期に発見。デバッグビルドでは必須 |

### デバッグのベストプラクティス

1. **段階的デバッグ**: QEMU で大まかに、実機で最終確認
2. **ログの粒度調整**: 問題が起きている箇所は詳細に、それ以外は簡潔に
3. **再現性の確保**: 同じ条件で何度も再現できるようにする
4. **バックアップ**: 実機デバッグ前に必ずバックアップ
5. **ツールの活用**: GDB, POST カード、ロジックアナライザを使い分ける

---

次章では、デバッグツールの内部動作と、より高度なデバッグ手法について詳しく学びます。

📚 **参考資料**
- [EDK II Debugging](https://github.com/tianocore/tianocore.github.io/wiki/Debugging)
- [QEMU Documentation](https://www.qemu.org/docs/master/)
- [GDB Manual](https://sourceware.org/gdb/current/onlinedocs/gdb/)
- [UEFI Debug Support](https://uefi.org/specs/UEFI/2.10/02_Overview.html#debug-support)
