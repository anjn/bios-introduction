# ブートマネージャとブートローダの役割

🎯 **この章で学ぶこと**
- UEFI Boot Manager の役割とアーキテクチャ
- Boot#### UEFI 変数によるブートオプション管理
- デバイスパスと Load Option の構造
- BDS (Boot Device Selection) Phase の動作
- Boot Manager と Boot Loader の違いと関係

📚 **前提知識**
- [Part I: UEFI ブートフローの全体像](../part1/05-uefi-boot-flow.md)
- [Part II: ハードウェア抽象化の仕組み](05-hardware-abstraction.md)

---

## Boot Manager と Boot Loader の違い

### 役割の分離

多くの人が混同しがちですが、**Boot Manager** と **Boot Loader** は異なる役割を持ちます。

```mermaid
graph TB
    subgraph "UEFI Firmware"
        BDS[BDS Phase]
        BOOTMGR[UEFI Boot Manager]
    end

    subgraph "ESP (EFI System Partition)"
        GRUB[GRUB<br/>Boot Loader]
        SYSTEMD[systemd-boot<br/>Boot Loader]
        WINBOOT[Windows Boot Manager<br/>Boot Loader]
    end

    subgraph "OS"
        LINUX[Linux Kernel]
        WINDOWS[Windows Kernel]
    end

    BDS --> BOOTMGR
    BOOTMGR -->|Load & Execute| GRUB
    BOOTMGR -->|Load & Execute| SYSTEMD
    BOOTMGR -->|Load & Execute| WINBOOT
    GRUB --> LINUX
    SYSTEMD --> LINUX
    WINBOOT --> WINDOWS

    style BOOTMGR fill:#e1f5ff
    style GRUB fill:#fff4e1
    style SYSTEMD fill:#fff4e1
    style WINBOOT fill:#fff4e1
```

### 定義と責務

| コンポーネント | 実装場所 | 責務 | 例 |
|--------------|---------|------|-----|
| **Boot Manager** | UEFI Firmware 内蔵 | ブートオプション管理、選択、EFI アプリケーションのロード | UEFI Boot Manager |
| **Boot Loader** | ESP 上の EFI アプリ | カーネルのロード、起動パラメータ設定 | GRUB、systemd-boot、Windows Boot Manager |

**重要なポイント**: Boot Loader も UEFI アプリケーションであり、Boot Manager によってロードされます。

---

## UEFI Boot Manager のアーキテクチャ

### Boot Manager の役割

UEFI Boot Manager は **BDS (Boot Device Selection) Phase** で動作し、以下の責務を持ちます：

1. **ブートオプションの管理**: UEFI 変数に保存されたブートオプションを読み込み
2. **ブートデバイスの列挙**: 接続されたストレージデバイスを検出
3. **ユーザーインタラクション**: ブートメニューの表示（オプション）
4. **EFI アプリケーションのロード**: 選択されたブートオプションを実行

### BDS Phase でのブートフロー

```mermaid
sequenceDiagram
    participant DXE as DXE Dispatcher
    participant BDS as BDS Phase
    participant BOOTMGR as Boot Manager
    participant ESP as ESP (File System)
    participant LOADER as Boot Loader

    DXE->>BDS: DXE 完了、BDS へ遷移
    BDS->>BOOTMGR: ブートオプション処理開始

    BOOTMGR->>BOOTMGR: BootOrder 読み込み
    BOOTMGR->>BOOTMGR: Boot0000, Boot0001... 読み込み

    alt タイムアウト内にユーザー入力なし
        BOOTMGR->>BOOTMGR: BootOrder の最初のオプションを選択
    else ユーザーが Boot Menu を開いた
        BOOTMGR->>BOOTMGR: ブートメニュー表示
        BOOTMGR->>BOOTMGR: ユーザー選択を待機
    end

    BOOTMGR->>ESP: デバイスパスから EFI アプリを探索
    ESP-->>BOOTMGR: \\EFI\\BOOT\\BOOTX64.EFI を発見
    BOOTMGR->>LOADER: LoadImage() & StartImage()
    LOADER->>LOADER: カーネルをロード
    LOADER->>OS: カーネルに制御を渡す
```

---

## Boot#### UEFI 変数

### UEFI 変数とは

**UEFI 変数**は、ファームウェアが不揮発性ストレージ（通常は SPI フラッシュ）に保存する設定データです。ブートオプションは以下の変数で管理されます：

| 変数名 | 用途 | データ型 |
|--------|------|---------|
| **BootOrder** | ブートオプションの優先順位 | UINT16 配列 |
| **Boot0000** | ブートオプション 0 の詳細 | EFI_LOAD_OPTION |
| **Boot0001** | ブートオプション 1 の詳細 | EFI_LOAD_OPTION |
| **BootNext** | 次回起動時のみ使用するブートオプション | UINT16 |
| **BootCurrent** | 現在起動したブートオプション（読み取り専用） | UINT16 |

### BootOrder の例

```
BootOrder = [0x0001, 0x0000, 0x0003]
```

この場合、以下の順序でブートを試みます：

1. `Boot0001`（例: Ubuntu）
2. `Boot0000`（例: Windows Boot Manager）
3. `Boot0003`（例: UEFI Shell）

### Boot#### 変数の構造

**`EFI_LOAD_OPTION`** 構造体は、各ブートオプションの詳細を保存します。

```c
typedef struct {
  UINT32 Attributes;         // ブートオプションの属性
  UINT16 FilePathListLength; // デバイスパスのバイト数
  CHAR16 Description[];      // NULL終端の説明文字列
  // Description の直後に以下が続く
  // EFI_DEVICE_PATH_PROTOCOL FilePathList[];
  // UINT8 OptionalData[];
} EFI_LOAD_OPTION;
```

### Attributes の定義

| ビット | 名前 | 説明 |
|-------|------|------|
| 0 | LOAD_OPTION_ACTIVE | 1 = 有効、0 = 無効 |
| 1 | LOAD_OPTION_FORCE_RECONNECT | デバイス再接続を強制 |
| 2 | LOAD_OPTION_HIDDEN | ブートメニューに表示しない |
| 8-15 | LOAD_OPTION_CATEGORY | カテゴリ（App, Boot, etc.） |

---

## デバイスパスによるブートターゲット指定

### デバイスパスの役割

Boot#### 変数の `FilePathList` には、**ブートローダへの完全なパス**が保存されます。これは Device Path Protocol を使って表現されます。

### 典型的なデバイスパスの例

**Ubuntu の GRUB**:

```
HD(1,GPT,<GUID>,0x800,0x100000)/\EFI\ubuntu\grubx64.efi
```

**解析**:

1. **HD(1,GPT,<GUID>,0x800,0x100000)**
   - パーティション 1（GPT、固有 GUID）
   - 開始 LBA: 0x800
   - サイズ: 0x100000 ブロック

2. **\EFI\ubuntu\grubx64.efi**
   - パーティション内のファイルパス

### リムーバブルメディアのデバイスパス

USB フラッシュドライブなど、リムーバブルメディアの場合：

```
PciRoot(0x0)/Pci(0x14,0x0)/USB(0,0)/HD(1,MBR,0x12345678,0x800,0x100000)/\EFI\BOOT\BOOTX64.EFI
```

**解析**:

1. **PciRoot(0x0)**: ルート複合デバイス
2. **Pci(0x14,0x0)**: PCI デバイス（USB コントローラ）
3. **USB(0,0)**: USB ポート 0
4. **HD(...)**: パーティション情報
5. **\EFI\BOOT\BOOTX64.EFI**: ファイルパス

---

## Load Option の実例

### Boot0001 (Ubuntu) の例

```
Attributes: 0x00000001 (LOAD_OPTION_ACTIVE)
FilePathListLength: 112
Description: "ubuntu"
FilePathList:
  HD(1,GPT,12345678-1234-1234-1234-123456789abc,0x800,0x100000)
  File(\EFI\ubuntu\shimx64.efi)
OptionalData: (空)
```

### OptionalData の用途

`OptionalData` には、ブートローダに渡す追加パラメータを保存できます。

**例**: Linux カーネルパラメータ

```
OptionalData: "root=/dev/sda2 quiet splash"
```

ただし、実際には多くのブートローダは `OptionalData` を使わず、独自の設定ファイル（GRUB の grub.cfg など）を使用します。

---

## ブートオプションの作成と管理

### efibootmgr (Linux)

Linux では **efibootmgr** コマンドでブートオプションを管理します。

```bash
# 現在のブートオプションを表示
$ efibootmgr
BootCurrent: 0001
BootOrder: 0001,0000,0003
Boot0000* Windows Boot Manager
Boot0001* ubuntu
Boot0003* UEFI Shell

# 新しいブートオプションを作成
$ efibootmgr --create \
  --disk /dev/sda \
  --part 1 \
  --label "My Linux" \
  --loader '\EFI\mylinux\grubx64.efi'

# ブートオプションを削除
$ efibootmgr --bootnum 0003 --delete-bootnum

# BootOrder を変更
$ efibootmgr --bootorder 0001,0000
```

### bcdedit (Windows)

Windows では **bcdedit** コマンドを使用します。

```cmd
REM ブート設定を表示
bcdedit /enum firmware

REM UEFI ファームウェア設定を開くオプションを追加
bcdedit /set {fwbootmgr} displayorder {bootmgr} /addlast
```

---

## Fallback Boot Path

### デフォルトブートパスの仕組み

UEFI 仕様では、**リムーバブルメディア**用のデフォルトパスを定義しています。これにより、Boot#### 変数がなくてもブート可能です。

| アーキテクチャ | デフォルトパス |
|-------------|---------------|
| x86_64 | \EFI\BOOT\BOOTX64.EFI |
| x86 (32-bit) | \EFI\BOOT\BOOTIA32.EFI |
| ARM64 | \EFI\BOOT\BOOTAA64.EFI |
| ARM (32-bit) | \EFI\BOOT\BOOTARM.EFI |

### Fallback の動作

```mermaid
sequenceDiagram
    participant BOOTMGR as Boot Manager
    participant VAR as UEFI Variables
    participant ESP as ESP

    BOOTMGR->>VAR: BootOrder を読み込み
    VAR-->>BOOTMGR: 空（変数なし）

    BOOTMGR->>BOOTMGR: Fallback モードに切り替え
    BOOTMGR->>ESP: \EFI\BOOT\BOOTX64.EFI を探索

    alt ファイルが存在
        ESP-->>BOOTMGR: ファイル発見
        BOOTMGR->>BOOTMGR: LoadImage() & StartImage()
    else ファイルが存在しない
        BOOTMGR->>BOOTMGR: 次のデバイスを試行
    end
```

この仕組みにより、**USB インストールメディア**は特別な設定なしでブート可能です。

---

## Boot Loader の種類と動作

### GRUB (GRand Unified Bootloader)

**GRUB** は Linux で最も一般的なブートローダです。

```mermaid
graph TB
    subgraph "UEFI Firmware"
        BOOTMGR[Boot Manager]
    end

    subgraph "ESP"
        SHIM[shimx64.efi<br/>Secure Boot 対応]
        GRUB[grubx64.efi]
        GRUBCFG[grub.cfg<br/>設定ファイル]
    end

    subgraph "Linux Partition"
        KERNEL[vmlinuz<br/>カーネルイメージ]
        INITRD[initrd.img<br/>初期 RAM ディスク]
    end

    BOOTMGR --> SHIM
    SHIM --> GRUB
    GRUB --> GRUBCFG
    GRUB --> KERNEL
    GRUB --> INITRD

    style BOOTMGR fill:#e1f5ff
    style GRUB fill:#fff4e1
    style KERNEL fill:#e1ffe1
```

**GRUB の動作**:

1. **shimx64.efi** が Secure Boot 検証を実行
2. **grubx64.efi** がロードされる
3. **grub.cfg** を読み込み、ブートメニューを表示
4. ユーザー選択に基づき **vmlinuz** と **initrd.img** をロード
5. カーネルに制御を渡す

### systemd-boot

**systemd-boot** は、シンプルで高速なブートローダです。

**特徴**:

- UEFI のみサポート（BIOS 非対応）
- 設定ファイルが非常にシンプル
- Secure Boot サポート

**設定例** (`loader/entries/arch.conf`):

```
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=/dev/sda2 rw quiet
```

### Windows Boot Manager

**Windows Boot Manager** (`\EFI\Microsoft\Boot\bootmgfw.efi`) は、Windows 専用のブートローダです。

**動作**:

1. **BCD (Boot Configuration Data)** を読み込み
2. ブートメニュー表示（複数の Windows がある場合）
3. **winload.efi** をロードし、Windows カーネルを起動

---

## Secure Boot とブートプロセス

### Secure Boot の影響

**Secure Boot** が有効な場合、Boot Manager は署名されていない EFI アプリケーションの実行を拒否します。

```mermaid
sequenceDiagram
    participant BOOTMGR as Boot Manager
    participant SHIM as shimx64.efi
    participant GRUB as grubx64.efi
    participant DB as Signature Database

    BOOTMGR->>SHIM: LoadImage()
    BOOTMGR->>DB: shimx64.efi の署名検証
    DB-->>BOOTMGR: OK（Microsoft 署名済み）
    BOOTMGR->>SHIM: StartImage()

    SHIM->>GRUB: LoadImage()
    SHIM->>SHIM: grubx64.efi の署名検証（shim 内蔵 DB）
    SHIM->>GRUB: StartImage()
```

**shim の役割**:

- Microsoft によって署名された中間ローダー
- ディストリビューション固有の証明書で GRUB を検証

---

## まとめ

### この章で学んだこと

✅ **Boot Manager と Boot Loader の違い**
- Boot Manager: UEFI Firmware 内蔵、ブートオプション管理
- Boot Loader: ESP 上の EFI アプリ、カーネルをロード

✅ **Boot#### UEFI 変数**
- BootOrder: ブート優先順位
- Boot0000, Boot0001, ...: 各ブートオプションの詳細
- EFI_LOAD_OPTION 構造体

✅ **デバイスパス**
- ブートターゲットを一意に識別
- パーティション + ファイルパスで構成

✅ **BDS Phase の動作**
- BootOrder に従ってブートオプションを試行
- タイムアウトまたはユーザー選択でブート

✅ **Fallback Boot Path**
- \EFI\BOOT\BOOTX64.EFI がデフォルト
- リムーバブルメディアで使用

✅ **Boot Loader の種類**
- GRUB: 汎用、高機能
- systemd-boot: シンプル、高速
- Windows Boot Manager: Windows 専用

✅ **Secure Boot**
- 署名検証により信頼できるコードのみ実行
- shim が中間ローダーとして機能

### 次章の予告

次章は **Part II のまとめ**です。これまで学んだ EDK II のアーキテクチャ、モジュール構造、プロトコル、ドライバモデル、ハードウェア抽象化、各種サブシステム（グラフィックス、ストレージ、USB）、そしてブート管理の全体像を振り返ります。Part II で得た知識は、次の Part III「プラットフォーム初期化の仕組み」へとつながります。

---

📚 **参考資料**
- [UEFI Specification v2.10 - Chapter 3: Boot Manager](https://uefi.org/specifications)
- [UEFI Specification v2.10 - Section 3.1.1: UEFI Variables](https://uefi.org/specifications)
- [UEFI Specification v2.10 - Section 3.1.3: Load Option](https://uefi.org/specifications)
- [GRUB Manual](https://www.gnu.org/software/grub/manual/)
- [systemd-boot Documentation](https://www.freedesktop.org/wiki/Software/systemd/systemd-boot/)
- [efibootmgr Man Page](https://linux.die.net/man/8/efibootmgr)
