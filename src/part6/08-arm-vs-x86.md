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

### それぞれの強み

**x86**:
- 豊富なソフトウェア資産
- 高性能 (シングルスレッド)
- Windows完全対応

**ARM**:
- 低消費電力
- スケーラビリティ (組込み〜サーバ)
- カスタマイズ容易 (ライセンス)

---

次章: [Part VI Chapter 9: ファームウェアの将来展望](09-future-of-firmware.md)
