# ARM と x86 の違い

🎯 **この章で学ぶこと**
- アーキテクチャレベルの基本的な違い
- ブートプロセスの比較
- ファームウェア実装の差異
- それぞれの利点と適用場面

📚 **前提知識**
- [Part I: x86_64 ブート基礎](../part1/01-reset-vector.md)
- [Part VI Chapter 7: ARM64 ブートアーキテクチャ](07-arm64-boot-architecture.md)

---

## はじめに

**ARM と x86 の違い**は、単なる命令セットの違いではなく、設計思想、セキュリティモデル、ブートプロセス、デバイス列挙、電源管理といった多岐にわたる差異を含んでいます。x86 は CISC（Complex Instruction Set Computing）アーキテクチャとして設計され、高性能なデスクトップとサーバ市場を支配してきました。ARM は RISC（Reduced Instruction Set Computing）アーキテクチャとして設計され、低消費電力が求められるモバイルと組込み市場で圧倒的なシェアを持っています。近年では、Apple M1/M2 や AWS Graviton のように、ARM64 がデスクトップとサーバ市場にも進出しており、両アーキテクチャの競争が激化しています。ファームウェア開発者は、両アーキテクチャの違いを理解し、それぞれの長所を活かした実装を行う必要があります。この章では、命令セット、メモリモデル、ブートプロセス、セキュリティモデル、デバイス列挙、電源管理、パフォーマンス特性を比較し、それぞれの適用場面を明確にします。

## アーキテクチャの基本的な違い

### 命令セット

| 項目 | x86/x86_64 | ARM64 |
|------|-----------|-------|
| **設計** | CISC (Complex) | RISC (Reduced) |
| **命令長** | 可変長 (1-15バイト) | 固定長 (4バイト) |
| **レジスタ** | 16本 (x86_64) | 31本汎用 + SP |
| **エンディアン** | Little Endian | Bi-Endian (通常LE) |
| **条件実行** | フラグ+分岐 | 条件付き命令 |

### メモリモデル

**x86**:
- Strong Memory Ordering (厳格な順序保証)
- MFENCE, LFENCE, SFENCE命令

**ARM**:
- Weak Memory Ordering (弱い順序保証)
- DMB, DSB, ISB命令

```asm
; x86: メモリバリア
MFENCE  ; Full memory fence

; ARM: メモリバリア
DMB SY  ; Data Memory Barrier
```

---

## ブートプロセスの比較

### x86ブートフロー

```
Reset (0xFFFFFFF0)
  → Real Mode (16bit)
    → Protected Mode (32bit)
      → Long Mode (64bit)
        → OS
```

### ARM64ブートフロー

```
Reset (SoC dependent)
  → BL1 (EL3 Secure)
    → BL2 (EL1 Secure)
      → BL31 (EL3 Runtime)
        → BL33 (EL2 Non-Secure)
          → OS (EL1)
```

---

## セキュリティモデル

### x86: SMM (System Management Mode)

```c
// SMI Handler
VOID SmiHandler(VOID)
{
  // SMRAM内でのみ実行
  // OSから隔離
  HandleSmi();
}
```

### ARM: TrustZone

```c
// Secure World (EL3)
void SecureService(void)
{
  // Secure メモリアクセス可能
  ProcessSecureRequest();
}

// Normal World (EL1)
// Secure メモリアクセス不可
```

---

## 割り込み処理

### x86: APIC/x2APIC

```c
// Local APIC設定
WriteMsr(IA32_APIC_BASE, apic_base | 0x800);

// 割り込み送信
WriteApic(ICR_LOW, vector | destination);
```

### ARM: GIC (Generic Interrupt Controller)

```c
// GIC初期化
GicDistributorInit();
GicCpuInterfaceInit();

// 割り込み有効化
GicEnableInterrupt(irq_id);
```

---

## 電源管理

### x86: ACPI P-states/C-states

```asl
// ACPI DSDT
PowerResource(PUBS, 0, 0) {
  Method(_STA) { Return (1) }
  Method(_ON)  { /* Power on */ }
  Method(_OFF) { /* Power off */ }
}
```

### ARM: PSCI

```c
// PSCI CPU ON
psci_cpu_on(target_cpu, entry_point, context_id);

// PSCI CPU OFF
psci_cpu_off();
```

---

## デバイス列挙

### x86: PCI/PCIe

```c
// PCI Configuration Space アクセス
UINT32 ReadPciConfig(UINT8 bus, UINT8 dev, UINT8 func, UINT8 reg)
{
  UINT32 address = (1U << 31) | (bus << 16) | (dev << 11) | (func << 8) | reg;
  IoWrite32(0xCF8, address);
  return IoRead32(0xCFC);
}
```

### ARM: Device Tree

```dts
soc {
  i2c0: i2c@7e205000 {
    compatible = "brcm,bcm2835-i2c";
    reg = <0x7e205000 0x200>;
    clocks = <&clocks BCM2835_CLOCK_VPU>;
    #address-cells = <1>;
    #size-cells = <0>;
  };
};
```

---

## パフォーマンス特性

### 典型的な用途別比較

| 用途 | x86 | ARM64 |
|------|-----|-------|
| **デスクトップ** | ✅ 優位 | △ Apple M1/M2 |
| **サーバ** | ✅ 優位 | △ AWS Graviton |
| **モバイル** | ❌ 不向き | ✅ 優位 |
| **組込み** | △ Atom系 | ✅ 優位 |
| **消費電力** | 15-65W (デスクトップ) | 5-15W (同性能) |
| **性能/W** | 低い | 高い |

---

## まとめ

この章では、**ARM と x86 の違い**を命令セット、メモリモデル、ブートプロセス、セキュリティモデル、割り込み処理、電源管理、デバイス列挙、パフォーマンス特性という多面的な視点から比較しました。両アーキテクチャは異なる設計思想を持ち、それぞれの得意分野で優位性を発揮します。

**命令セットアーキテクチャ（ISA）の違い**として、x86 は CISC（複雑命令セット）であり、命令長が可変（1-15 バイト）、レジスタは 16 本（x86_64）です。ARM64 は RISC（縮小命令セット）であり、命令長が固定（4 バイト）、汎用レジスタは 31 本 + SP です。CISC は複雑な操作を単一命令で実行でき、コード密度が高いですが、デコードが複雑です。RISC は命令がシンプルで、パイプライン効率が高く、低消費電力ですが、同じ処理に複数命令が必要です。

**メモリモデルの違い**として、x86 は Strong Memory Ordering（厳格な順序保証）であり、メモリアクセスの順序が保証され、MFENCE/LFENCE/SFENCE 命令でメモリバリアを明示します。ARM は Weak Memory Ordering（弱い順序保証）であり、メモリアクセスの順序は保証されず、DMB/DSB/ISB 命令で明示的に同期が必要です。マルチコア環境では、この違いが重要であり、ARM では適切なメモリバリアを使用しないと、データ競合や不整合が発生します。

**ブートプロセスの違い**として、x86 は Reset（0xFFFFFFF0）→ Real Mode（16 bit）→ Protected Mode（32 bit）→ Long Mode（64 bit）→ OS という CPU モード遷移を伴います。ARM64 は Reset（SoC 依存）→ BL1（EL3 Secure）→ BL2（EL1 Secure）→ BL31（EL3 Runtime）→ BL33（EL2 Non-Secure）→ OS（EL1）という Exception Level 遷移を伴います。x86 のモード遷移は歴史的な互換性を維持するための複雑性であり、ARM64 の Exception Level は TrustZone によるセキュリティ分離を実現します。

**セキュリティモデルの違い**として、x86 は SMM（System Management Mode）で、SMI（System Management Interrupt）により SMM に遷移し、SMRAM（隔離されたメモリ領域）で実行します。OS から完全に隔離されていますが、SMM 自体が攻撃対象となる脆弱性が報告されています。ARM は TrustZone で、Secure World（EL3/EL1 Secure）と Normal World（EL2/EL1 Non-Secure）を CPU レベルで分離します。Secure World は Secure メモリにアクセスできますが、Normal World はアクセスできません。SMC（Secure Monitor Call）により、Normal World から Secure World を呼び出します。TrustZone は SMM よりも柔軟で強力なセキュリティモデルです。

**割り込み処理の違い**として、x86 は APIC/x2APIC（Advanced Programmable Interrupt Controller）を使用し、Local APIC（各 CPU）と I/O APIC（外部デバイス）で構成されます。ARM は GIC（Generic Interrupt Controller）を使用し、Distributor（割り込みルーティング）と CPU Interface（各 CPU）で構成されます。両者は役割が似ていますが、レジスタマップと初期化手順が異なります。

**電源管理の違い**として、x86 は ACPI P-states（CPU 周波数）と C-states（CPU アイドル状態）を使用し、ACPI テーブル（DSDT/SSDT）で記述します。ARM は PSCI（Power State Coordination Interface）を使用し、ATF（ARM Trusted Firmware）が実装し、SMC 経由で呼び出します。PSCI は psci_cpu_on、psci_cpu_off、psci_system_suspend といったシンプルな API を提供します。

**デバイス列挙の違い**として、x86 は PCI/PCIe Configuration Space（I/O ポート 0xCF8/0xCFC または MMIO）でデバイスを列挙し、ACPI テーブルで記述します。ARM は Device Tree（.dts ファイル、.dtb バイナリ）でハードウェア構成を宣言的に記述し、ファームウェアが OS に渡します。サーバ向け ARM64 では ACPI も使用されます。

**パフォーマンス特性の違い**として、デスクトップでは x86 が優位（豊富なソフトウェア資産、高性能）ですが、Apple M1/M2 により ARM64 も競争力を持ちます。サーバでは x86 が優位ですが、AWS Graviton により ARM64 も性能/コストで競争力を持ちます。モバイルでは ARM64 が圧倒的に優位（低消費電力）です。組込みでも ARM64 が優位（スケーラビリティ、カスタマイズ容易）です。消費電力は、x86 が 15-65 W（デスクトップ）、ARM64 が 5-15 W（同性能）であり、性能/W では ARM64 が優位です。

**それぞれの強み**として、**x86 の強み**は、豊富なソフトウェア資産（Windows、Linux、macOS の完全対応、膨大なアプリケーション）、高性能（シングルスレッド性能が高い、高クロック動作）、成熟したエコシステム（ベンダーサポート、ツールチェーン、ドキュメント）です。**ARM の強み**は、低消費電力（同性能で消費電力が 1/2 から 1/3）、スケーラビリティ（組込みからサーバまで同じアーキテクチャ）、カスタマイズ容易（ISA ライセンスによりカスタム CPU 設計が可能）、コスト効率（性能/コスト、性能/W が高い）です。

**将来展望**として、x86 と ARM64 の競争が激化しています。Apple M シリーズの成功により、ARM64 デスクトップの実用性が証明されました。AWS Graviton の成功により、ARM64 サーバの性能とコスト効率が証明されました。RISC-V という新しいオープンソース ISA も台頭しており、将来的には 3 つのアーキテクチャが共存する可能性があります。ファームウェア開発者は、マルチアーキテクチャ対応を考慮した設計を行うことが重要です。

以下の参考表は、用途別の適性を示しています。

**参考表: 用途別の適性**

| 用途 | x86 | ARM64 |
|------|-----|-------|
| **デスクトップ** | ✅ 優位 | △ Apple M1/M2 |
| **サーバ** | ✅ 優位 | △ AWS Graviton |
| **モバイル** | ❌ 不向き | ✅ 優位 |
| **組込み** | △ Atom系 | ✅ 優位 |
| **消費電力** | 15-65W (デスクトップ) | 5-15W (同性能) |
| **性能/W** | 低い | 高い |

---

次章: [Part VI Chapter 9: ファームウェアの将来展望](09-future-of-firmware.md)
