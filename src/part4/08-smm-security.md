# SMM の仕組みとセキュリティ

<!-- Status: completed -->
<!-- Last Updated: 2025-10-05 -->

🎯 **この章で学ぶこと**
- SMM（System Management Mode）の役割と動作原理
- SMRAM（System Management RAM）の仕組み
- SMI（System Management Interrupt）の発生と処理
- SMM のセキュリティリスクと脆弱性
- SMRAM ロックと保護機構
- SMM 攻撃の事例と対策
- SMM Transfer Monitor（STM）による分離
- SMM のデバッグ方法

📚 **前提知識**
- [Part I Chapter 3: x86_64 特権レベルとメモリ保護](../part1/03-privilege-and-protection.md)
- [Part IV Chapter 7: SPI フラッシュ保護機構](./07-spi-flash-protection.md)
- x86 アーキテクチャの基礎

---

## SMM（System Management Mode）とは

**System Management Mode（SMM）** は、x86 プロセッサの**最高特権モード**であり、通称 **Ring -2** と呼ばれます。SMM は、OS（Ring 0）やハイパーバイザー（Ring -1）よりも**さらに高い権限**を持ち、システムのあらゆるリソースに無制限にアクセスできます。SMM は、1990年代の Intel 386SL プロセッサで導入され、当初は電源管理やレガシーハードウェアのエミュレーションを目的としていました。しかし、現代のシステムでは、BIOS Flash の更新、Secure Boot 変数の保護、ハードウェアエラーの処理など、**セキュリティに関わる重要な機能**を担っています。SMM の最大の特徴は、**完全に透過的**であることです。SMM は、SMI（System Management Interrupt）という特殊な割り込みによって起動され、処理が完了すると元の実行状態に戻ります。OS やハイパーバイザーは、SMM が実行されたことを検知できず、SMM の存在すら意識しません。この透過性により、SMM は OS から独立してシステムを制御できますが、同時に**攻撃者にとって魅力的なターゲット**となります。

SMM の主要な役割は、**5つの重要な機能**に集約されます。まず、**電源管理**では、ACPI S3（Suspend to RAM）、S4（Hibernate）、S5（Shutdown）といった電源状態の遷移を制御します。SMM は、メモリの内容を保存し、デバイスの電源を制御し、復帰時にシステムを元の状態に戻します。次に、**ハードウェア制御**では、CPU ファン速度の制御、温度センサーの監視、Over-Temperature Protection（OTP）といった、OS では直接制御できないハードウェア機能を管理します。さらに、**セキュリティ機能**では、[Part IV Chapter 7](./07-spi-flash-protection.md) で説明した BIOS Flash の更新を SMM のみに制限し、Secure Boot 変数（PK、KEK、db、dbx）を保護し、不正な変更を防ぎます。また、**エミュレーション**では、レガシーハードウェア（PS/2 キーボード、フロッピーディスク）を USB やその他の現代的なデバイスでエミュレートし、古い OS やソフトウェアとの互換性を維持します。最後に、**エラーハンドリング**では、Machine Check Exception（MCE）などのハードウェアエラーを処理し、システムをクラッシュから回復させます。

SMM の特権レベルを理解することは、そのセキュリティリスクを把握する上で極めて重要です。x86 アーキテクチャでは、伝統的に **Ring 0（カーネル）** から **Ring 3（ユーザーランド）** までの 4 つの特権レベルが定義されていますが、現代のプロセッサでは、仮想化技術（VT-x/AMD-V）により **Ring -1（ハイパーバイザー）** が追加されました。SMM は、これらよりもさらに高い **Ring -2** に位置します。具体的には、SMM は**すべてのメモリにアクセス**でき、**すべての I/O ポートを制御**でき、**すべての CPU レジスタを読み書き**できます。ページング保護、セグメンテーション保護、VT-x の EPT（Extended Page Tables）といった保護機構は、SMM には適用されません。したがって、攻撃者が SMM のコードを制御できれば、**システム全体を完全に支配**できます。SMM コードは、OS のカーネルを改ざんし、ハイパーバイザーをバイパスし、Hardware Root of Trust を無効化することが可能です。このため、SMM のセキュリティは、プラットフォームセキュリティ全体の**最も重要な要素**の 1 つとなっています。

SMM が攻撃されると、**システム全体が危殆化**する理由は、その透過性と永続性にあります。まず、SMM で実行されるコード（SMI Handler）は、OS やセキュリティソフトウェアから**見えない**ため、検出が極めて困難です。マルウェアが SMM に常駐すると、OS を再インストールしても、ディスクを暗号化しても、除去できません。次に、SMM コードは **SMRAM（System Management RAM）** という専用のメモリ領域に配置され、通常モードからはアクセスできません。SMRAM は、OS やハイパーバイザーから完全に隔離されているため、アンチウイルスソフトウェアはスキャンできません。さらに、SMM は**永続性**を持ちます。SMI Handler は BIOS 起動時に SMRAM にロードされ、システムがシャットダウンするまで常駐します。SMM に注入されたマルウェアは、OS のブートプロセス全体を監視し、セキュアブートを無効化し、カーネルを改ざんできます。このため、SMM のセキュリティは、Boot Guard、Secure Boot、TPM といった他のセキュリティ機構の**前提条件**となっています。

### 補足図：SMM の特権レベル

```mermaid
graph TD
    APP[Ring 3: Applications]
    OS[Ring 0: OS Kernel]
    HV[Ring -1: Hypervisor<br/>VMX Root Mode]
    ME[Ring -2: Intel ME / AMD PSP]
    SMM[Ring -2: SMM]

    APP --> OS
    OS --> HV
    HV --> SMM
    SMM -.同等.-> ME

    style SMM fill:#ff6b6b
    style ME fill:#ff6b6b
    style HV fill:#feca57
    style OS fill:#48dbfb
```

---

## SMM の動作原理

### SMI（System Management Interrupt）

**SMI** は、SMM に遷移するための**特殊な割り込み**です：

**SMI の発生源**：
- **Software SMI**: `OUT 0xB2, AL` 命令（I/O ポート 0xB2 への書き込み）
- **Hardware SMI**: チップセットからの SMI 信号
  - 電源ボタン
  - 温度センサー
  - タイマー
  - PCIe Hot Plug

### SMM 遷移のフロー

```mermaid
sequenceDiagram
    participant OS as OS / Hypervisor
    participant CPU as CPU
    participant SMI_SRC as SMI Source
    participant SMRAM as SMRAM
    participant HANDLER as SMI Handler

    OS->>OS: 通常実行
    SMI_SRC->>CPU: SMI 発生
    CPU->>CPU: 1. すべての CPU を停止
    CPU->>CPU: 2. 現在の状態を保存
    CPU->>SMRAM: 3. SMM State Save Area に保存
    CPU->>CPU: 4. SMM に遷移
    CPU->>HANDLER: 5. SMI Handler を実行
    HANDLER->>HANDLER: SMI 処理
    HANDLER->>CPU: 6. RSM 命令
    CPU->>SMRAM: 7. State Save Area から状態を復元
    CPU->>OS: 8. 通常モードに復帰
    OS->>OS: 実行再開
```

### SMM State Save Area

**State Save Area** は、SMM 遷移時の CPU 状態を保存する領域です：

```c
typedef struct {
  // 汎用レジスタ
  UINT64  Rax;
  UINT64  Rbx;
  UINT64  Rcx;
  UINT64  Rdx;
  UINT64  Rsi;
  UINT64  Rdi;
  UINT64  Rbp;
  UINT64  Rsp;
  UINT64  R8;
  UINT64  R9;
  UINT64  R10;
  UINT64  R11;
  UINT64  R12;
  UINT64  R13;
  UINT64  R14;
  UINT64  R15;

  // 制御レジスタ
  UINT64  Rip;
  UINT64  Rflags;
  UINT64  Cr0;
  UINT64  Cr3;
  UINT64  Cr4;

  // セグメントレジスタ
  UINT16  Cs;
  UINT16  Ds;
  UINT16  Es;
  UINT16  Fs;
  UINT16  Gs;
  UINT16  Ss;

  // その他
  UINT64  GdtrBase;
  UINT64  IdtrBase;
  UINT32  SmiHandlerBase;  // SMI Handler のエントリポイント
  UINT32  AutoHalt;         // Auto Halt Restart
  // ...
} SMM_STATE_SAVE_AREA;
```

**配置**：
- 各 CPU コアごとに **SMRAM の末尾** に配置
- サイズ: 約 512 バイト

---

## SMRAM（System Management RAM）

### SMRAM の構造

**SMRAM** は、SMM 専用のメモリ領域です：

```
+---------------------------+ TSEG Base + TSEG Size (例: 0xA0000000)
| CPU 0 State Save Area     | ← 512 bytes
+---------------------------+
| CPU 1 State Save Area     |
+---------------------------+
| ...                       |
+---------------------------+
| CPU N State Save Area     |
+---------------------------+
| SMM Stack                 |
+---------------------------+
| SMM Heap                  |
+---------------------------+
| SMM Code                  |
| - SMI Entry Point         |
| - SMI Handlers            |
| - SMM Services            |
+---------------------------+ TSEG Base (例: 0x9F000000)
```

### TSEG（Top of Memory Segment）

**TSEG** は、メインメモリの**最上位部分**に確保される SMRAM です：

**設定方法**：
```c
// TSEG は PCH の SMRAM レジスタで設定
// MCH (Memory Controller Hub) のレジスタ
typedef union {
  struct {
    UINT32  TsegBase  : 20;  // TSEG の開始アドレス（1MB 単位）
    UINT32  Reserved  : 11;
    UINT32  Lock      : 1;   // ロックビット
  } Bits;
  UINT32  Uint32;
} TSEG_BASE_REGISTER;

typedef union {
  struct {
    UINT32  TsegSize  : 3;   // TSEG のサイズ
                             // 0: 1 MB
                             // 1: 2 MB
                             // 2: 4 MB
                             // 3: 8 MB
    UINT32  Reserved  : 29;
  } Bits;
  UINT32  Uint32;
} TSEG_SIZE_REGISTER;
```

**TSEG の保護**：
- 通常モード（Ring 0-3）からは**アクセス不可**
- SMM 内からのみアクセス可能
- ロックビットを設定すると、TSEG の位置とサイズが変更不可

---

## SMM のセキュリティリスク

### 1. SMM Callout

**問題**：
- SMI Handler が **通常メモリ上のコード**を呼び出す
- OS が通常メモリを書き換えて任意コードを実行

```c
// 脆弱な SMI Handler の例
EFI_STATUS
VulnerableSmiHandler (
  IN EFI_HANDLE  DispatchHandle,
  IN VOID        *Context
  )
{
  // 通常メモリ上の関数ポインタを呼び出し
  VOID (*UserFunction)(VOID) = (VOID (*)(VOID)) 0x10000000;

  // これは危険！OS が 0x10000000 を書き換え可能
  UserFunction ();

  return EFI_SUCCESS;
}
```

**攻撃**：
```c
// OS から攻撃
// 1. 0x10000000 に悪意あるコードを配置
memcpy ((VOID *) 0x10000000, ShellcodeForSmm, sizeof (ShellcodeForSmm));

// 2. SMI を発生させる
__outbyte (0xB2, 0x55);  // Software SMI

// 3. SMI Handler が ShellcodeForSmm を SMM 権限で実行
```

### 2. TOCTOU（Time-of-Check to Time-of-Use）

**問題**：
- SMI Handler が通常メモリのデータを**チェック後に使用**
- OS がチェックと使用の間にデータを書き換え

```c
// 脆弱な例
EFI_STATUS
ToctouVulnerableSmiHandler (
  IN SMM_COMM_BUFFER  *Buffer
  )
{
  // 1. バッファのサイズをチェック
  if (Buffer->Size > MAX_SIZE) {
    return EFI_INVALID_PARAMETER;
  }

  // 2. バッファをコピー（危険！）
  // チェックから使用までの間に Buffer->Size が変更される可能性
  CopyMem (SmmLocalBuffer, Buffer->Data, Buffer->Size);

  return EFI_SUCCESS;
}
```

**攻撃**：
```c
// 並行スレッドから攻撃
while (1) {
  Buffer->Size = 100;       // チェックを通過
  // SMI Handler がチェック中
  Buffer->Size = 0x100000;  // チェック後にサイズを変更
  // SMI Handler が巨大なサイズでコピー → バッファオーバーフロー
}
```

### 3. ポインタ検証の欠如

**問題**：
- SMI Handler が通常メモリからの**ポインタを検証せず**に使用
- SMRAM 内部を指すポインタを渡して SMRAM を読み書き

```c
// 脆弱な例
EFI_STATUS
PointerVulnerableSmiHandler (
  IN UINT8  *Pointer
  )
{
  // ポインタが SMRAM を指していないかチェックしていない
  *Pointer = 0x42;  // 任意アドレスへの書き込み

  return EFI_SUCCESS;
}
```

**攻撃**：
```c
// SMI Handler に SMRAM 内のアドレスを渡す
UINT8 *SmramAddress = (UINT8 *) 0x9F000000;  // TSEG Base
__outbyte (0xB2, SMI_NUMBER);                 // SMI 発生

// SMI Handler が SMRAM を書き換えてしまう
```

---

## SMM の保護機構

### 1. SMRAM ロック

**D_LCK（SMRAM Lock）**：
```c
// SMRAMC (SMRAM Control) レジスタ
// MCH のコンフィグレーション空間
typedef union {
  struct {
    UINT8  CState     : 3;  // C_BASE_SEG
    UINT8  GState     : 1;  // G_SMRAME
    UINT8  DState     : 1;  // D_OPEN
    UINT8  DLock      : 1;  // D_LCK (SMRAM Lock)
    UINT8  Reserved   : 2;
  } Bits;
  UINT8  Uint8;
} SMRAM_CONTROL;

VOID
LockSmram (
  VOID
  )
{
  SMRAM_CONTROL  Smramc;

  // SMRAMC レジスタを読み取り
  Smramc.Uint8 = MmioRead8 (MCH_BASE + SMRAMC_OFFSET);

  // D_LCK ビットを設定
  Smramc.Bits.DLock = 1;

  // レジスタに書き戻し
  MmioWrite8 (MCH_BASE + SMRAMC_OFFSET, Smramc.Uint8);

  // これ以降、SMRAM の設定は変更不可（リセットまで）
}
```

### 2. SMM_BWP（SMM BIOS Write Protection）

**仕組み**：
- **SMM 外からの BIOS 書き込みを禁止**
- BIOSWE=1 でも、SMM 外からは Flash を書き込めない

```c
// BIOS Control レジスタ (前章参照)
// SMM_BWP ビットを設定
VOID
EnableSmmBiosWriteProtection (
  VOID
  )
{
  BIOS_CONTROL  Bc;

  Bc.Uint8 = MmioRead8 (PCH_LPC_BASE + 0xDC);
  Bc.Bits.SmmBiosWriteProtect = 1;
  MmioWrite8 (PCH_LPC_BASE + 0xDC, Bc.Uint8);

  // SMM 外からは BIOS を書き換えられない
}
```

### 3. SMM Code Access Check（SMRR）

**SMRR（SMM Range Register）**：
- **SMRAM の範囲**を MSR で定義
- SMM 外からの SMRAM アクセスを禁止

```c
// SMRR MSR
#define MSR_IA32_SMRR_PHYS_BASE  0x1F2
#define MSR_IA32_SMRR_PHYS_MASK  0x1F3

VOID
ConfigureSmrr (
  IN UINT64  SmramBase,
  IN UINT64  SmramSize
  )
{
  UINT64  SmrrPhysBase;
  UINT64  SmrrPhysMask;

  // 1. SMRR Base を設定
  // ビット 12-35: Physical Base
  // ビット 0-7: Memory Type (WB = 6)
  SmrrPhysBase = SmramBase | 0x06;
  AsmWriteMsr64 (MSR_IA32_SMRR_PHYS_BASE, SmrrPhysBase);

  // 2. SMRR Mask を設定
  // ビット 12-35: Physical Mask
  // ビット 11: Valid
  SmrrPhysMask = (~(SmramSize - 1) & 0xFFFFFFFFF000ULL) | BIT11;
  AsmWriteMsr64 (MSR_IA32_SMRR_PHYS_MASK, SmrrPhysMask);

  // SMM 外から SMRAM へのアクセスは例外が発生
}
```

### 4. ポインタ検証

**SmmIsBufferOutsideSmram**：
```c
/**
  バッファが SMRAM 外にあるか確認

  @param[in] Buffer     バッファのアドレス
  @param[in] BufferSize バッファのサイズ

  @retval TRUE   SMRAM 外
  @retval FALSE  SMRAM 内（危険）
**/
BOOLEAN
SmmIsBufferOutsideSmram (
  IN VOID   *Buffer,
  IN UINTN  BufferSize
  )
{
  UINT64  BufferStart;
  UINT64  BufferEnd;

  BufferStart = (UINT64) Buffer;
  BufferEnd = BufferStart + BufferSize - 1;

  // SMRAM の範囲をチェック
  if ((BufferStart >= gSmramBase && BufferStart < gSmramBase + gSmramSize) ||
      (BufferEnd >= gSmramBase && BufferEnd < gSmramBase + gSmramSize)) {
    // SMRAM 内を指している → 危険
    return FALSE;
  }

  return TRUE;
}

// 使用例
EFI_STATUS
SecureSmiHandler (
  IN SMM_COMM_BUFFER  *Buffer
  )
{
  // 1. ポインタが SMRAM を指していないか確認
  if (!SmmIsBufferOutsideSmram (Buffer, sizeof (SMM_COMM_BUFFER))) {
    return EFI_SECURITY_VIOLATION;
  }

  // 2. データを安全にコピー
  CopyMem (SmmLocalBuffer, Buffer->Data, MIN (Buffer->Size, MAX_SIZE));

  return EFI_SUCCESS;
}
```

### 5. TOCTOU の回避

**対策**：
```c
EFI_STATUS
ToctouSecureSmiHandler (
  IN SMM_COMM_BUFFER  *Buffer
  )
{
  SMM_COMM_BUFFER  LocalBuffer;

  // 1. バッファ全体を SMRAM にコピー（アトミック）
  if (!SmmIsBufferOutsideSmram (Buffer, sizeof (SMM_COMM_BUFFER))) {
    return EFI_SECURITY_VIOLATION;
  }
  CopyMem (&LocalBuffer, Buffer, sizeof (SMM_COMM_BUFFER));

  // 2. ローカルコピーに対して処理
  // 以降、Buffer->Size が変更されても影響しない
  if (LocalBuffer.Size > MAX_SIZE) {
    return EFI_INVALID_PARAMETER;
  }

  CopyMem (SmmDestination, LocalBuffer.Data, LocalBuffer.Size);

  return EFI_SUCCESS;
}
```

---

## SMM Transfer Monitor（STM）

### STM の目的

**STM** は、SMM を**監視・分離**する仮想化技術です：

1. **SMM の分離**: SMI Handler を独立した VM として実行
2. **ポリシー強制**: SMM からのリソースアクセスを制限
3. **脆弱性の軽減**: SMM Callout などの攻撃を防止

```mermaid
graph TD
    OS[OS / Hypervisor] --> VMM[VMM]
    SMI[SMI 発生] --> STM[STM<br/>SMM Transfer Monitor]
    STM --> HANDLER[SMI Handler<br/>独立 VM]
    HANDLER --> STM
    STM --> OS

    style STM fill:#ff6b6b
```

### STM の動作

**SMI 発生時**：
1. STM が SMI を捕捉
2. SMI Handler を**独立した VM** として起動
3. Handler からのリソースアクセスを STM が監視
4. ポリシー違反があれば拒否
5. Handler 終了後、STM が制御を OS に戻す

---

## SMM のデバッグ

### 1. シリアルコンソールでのログ

```c
// SMI Handler 内からログ出力
VOID
SmiHandlerEntry (
  VOID
  )
{
  SerialPortWrite ((UINT8 *) "[SMM] SMI Handler entered\n", 28);

  // SMI 処理

  SerialPortWrite ((UINT8 *) "[SMM] SMI Handler exiting\n", 27);
}
```

### 2. UEFI デバッガでの SMM デバッグ

**SourceLevel Debugger（UDK Debugger）**：
```bash
# QEMU で SMM デバッグを有効化
qemu-system-x86_64 \
  -bios OVMF.fd \
  -s -S \
  -enable-kvm \
  -m 4096

# GDB で接続
gdb
(gdb) target remote localhost:1234
(gdb) b SmiHandlerEntry
(gdb) c
```

### 3. chipsec での SMM チェック

```bash
# SMM の設定を確認
sudo chipsec_main -m common.smm

# 出力例:
# [*] running module: chipsec.modules.common.smm
# [*] Checking SMM configuration...
# [+] SMRAMC.D_LCK = 1 (SMRAM is locked)
# [+] TSEG.Lock = 1 (TSEG is locked)
# [+] SMRR configured: Base=0x9F000000, Mask=0xFF000800
# [+] PASSED: SMM configuration is secure
```

---

## 既知の SMM 攻撃と対策

### 1. ThinkPwn (CVE-2016-3287)

**脆弱性**：
- Lenovo の SMI Handler に **TOCTOU 脆弱性**
- OS から SMRAM を書き換え可能

**対策**：
- ポインタ検証の徹底
- SMRAM へのアクセスチェック

### 2. SMM Privilege Escalation

**脆弱性**：
- SMI Handler が OS から渡されたポインタを検証せず
- SMRAM 内のデータを書き換え

**対策**：
- SmmIsBufferOutsideSmram を使用
- すべてのポインタを検証

---

## トラブルシューティング

### Q1: SMM に入ると応答しなくなる

**原因**：
- SMI Handler に無限ループ
- デッドロック

**デバッグ**：
```c
// タイムアウト機構を追加
UINT64 StartTick = AsmReadTsc ();
while (Condition) {
  if (AsmReadTsc () - StartTick > TIMEOUT_TICKS) {
    SerialPortWrite ((UINT8 *) "[SMM] Timeout!\n", 16);
    break;
  }
}
```

### Q2: chipsec で SMM が FAILED

**原因**：
- SMRAM がロックされていない

**解決策**：
```c
// PEI/DXE Phase で SMRAM をロック
LockSmram ();
ConfigureSmrr (TSEG_BASE, TSEG_SIZE);
```

---

## 💻 演習

### 演習 1: SMM 設定の確認

**手順**：

```bash
# chipsec で SMM を検証
sudo chipsec_main -m common.smm
sudo chipsec_main -m common.smrr

# SMRAMC レジスタを確認
sudo setpci -s 00:00.0 88.b

# SMRR MSR を確認
sudo rdmsr 0x1F2
sudo rdmsr 0x1F3
```

---

## まとめ

この章では、**SMM（System Management Mode）のセキュリティ**について詳しく学びました。SMM は、x86 プロセッサの**最高特権モード**（Ring -2）であり、OS（Ring 0）やハイパーバイザー（Ring -1）よりも高い権限を持ちます。SMM は、電源管理、ハードウェア制御、BIOS Flash の更新、Secure Boot 変数の保護といった重要な機能を担っています。SMM の最大の特徴は、**完全に透過的**であり、OS やハイパーバイザーから検知されないことです。この透過性により、SMM は OS から独立してシステムを制御できますが、同時に**攻撃者にとって魅力的なターゲット**となります。攻撃者が SMM のコードを制御できれば、システム全体を完全に支配でき、OS の再インストールやディスク暗号化でも除去できない永続的なマルウェアを注入できます。

SMM には、**3つの主要なセキュリティリスク**があります。まず、**SMM Callout** は、SMM が通常メモリのコードやデータを呼び出す脆弱性です。SMM は SMRAM 内のコードのみを実行すべきですが、誤って通常メモリのポインタを関数ポインタとして呼び出すと、攻撃者が用意した悪意あるコードを SMM 権限で実行してしまいます。これにより、攻撃者は OS レベルの権限から SMM レベルの権限に昇格できます。次に、**TOCTOU（Time-of-Check to Time-of-Use）攻撃**は、SMM がポインタを検証した後、実際に使用するまでの間にデータを書き換える攻撃です。SMM は、OS から渡されたポインタが SMRAM 外を指していることを確認しますが、検証後に別の CPU コアがそのメモリを書き換えると、SMM は改ざんされたデータを使用してしまいます。この攻撃を防ぐには、検証後にデータを SMRAM 内にコピーし、ローカルコピーを使用する必要があります。さらに、**ポインタ検証の欠如**は、SMM が OS から渡されたポインタを検証せずに使用する脆弱性です。攻撃者は、SMRAM 内のアドレスを指すポインタを渡し、SMM に SMRAM のデータを読み書きさせることができます。これにより、SMM のコードやデータを改ざんし、永続的なバックドアを埋め込むことが可能になります。

SMM を保護するための**主要な保護機構**は、階層的に組み合わされています。まず、**SMRAM Lock（D_LCK ビット）** は、TSEG（Top of Memory Segment）の設定を固定します。SMRAMC レジスタの D_LCK ビットを 1 に設定すると、TSEG の Base アドレスと Size が変更不可になり、リセットまでロックされます。これにより、攻撃者がソフトウェアから TSEG の位置を変更し、SMRAM をアクセス可能にすることを防ぎます。次に、**SMRR（SMM Range Registers）** は、各 CPU コアの MSR（Model Specific Register）を使用して、SMRAM へのアクセスを制御します。SMRR は、SMRAM のアドレス範囲を指定し、SMM モード以外からのアクセスを禁止します。これにより、OS やハイパーバイザーが物理アドレスを直接操作しても、SMRAM にアクセスできません。さらに、**SMM_BWP（SMM BIOS Write Protect）** は、SMM 外からの BIOS Flash への書き込みを禁止します。BIOS Control レジスタの SMM_BWP ビットを 1 に設定すると、BIOSWE=1 であっても、SMM 以外からの Flash 書き込みは拒否されます。最後に、**SMM Transfer Monitor（STM）** は、Intel VT-x の技術を使用して、SMM 内の異なるコンポーネントを分離します。STM は、SMM のハイパーバイザーとして動作し、各 SMI Handler を独立した VM として実行し、相互の干渉を防ぎます。

SMM を安全に実装するための**ベストプラクティス**は、開発者が遵守すべき重要な原則です。まず、**すべてのポインタを検証**することです。SMM は、OS から渡されたすべてのポインタが SMRAM 外を指していることを確認する必要があります。具体的には、`(Pointer < TSEG_BASE) || (Pointer >= TSEG_BASE + TSEG_SIZE)` という条件をチェックし、SMRAM 内を指すポインタを拒否します。次に、**TOCTOU を回避**するため、検証後のデータを SMRAM 内のローカル変数にコピーし、ローカルコピーを使用します。これにより、検証後にデータが書き換えられても、SMM は元のデータを使用します。さらに、**SMM Callout を避ける**ため、SMM は通常メモリの関数を呼び出さず、すべてのコードを SMRAM 内に配置します。関数ポインタを使用する場合は、ポインタが SMRAM 内を指していることを確認します。また、**最小権限の原則**に従い、SMM は必要最小限の機能のみを実装します。不要な機能は削除し、攻撃面を縮小します。最後に、**定期的なセキュリティ監査**を実施し、chipsec や FWTS（Firmware Test Suite）といったツールを使用して、SMRAM のロック状態や SMRR の設定を検証します。

---

次章では、**攻撃事例から学ぶ設計原則**について学びます。

📚 **参考資料**
- [Intel 64 and IA-32 Architectures Software Developer Manual Volume 3: System Programming Guide](https://www.intel.com/sdm)
- [UEFI Platform Initialization Specification](https://uefi.org/specifications)
- [chipsec: Platform Security Assessment Framework](https://github.com/chipsec/chipsec)
- [Attacking SMM Memory via Intel CPU Cache Poisoning](https://invisiblethingslab.com/resources/2015/x86_sinkhole.pdf)
