# ARM64 ブートアーキテクチャ

🎯 **この章で学ぶこと**
- ARM64 (AARCH64) のブート手順
- ARM Trusted Firmware (ATF) の役割
- UEFI on ARMの実装
- Device Treeとの連携

📚 **前提知識**
- [Part I: x86_64 ブート基礎](../part1/01-reset-vector.md)

---

## ARM64ブートフロー

```
BL1 (Boot ROM) → BL2 (Trusted Firmware) → BL31 (Secure Monitor)
  → BL33 (UEFI/U-Boot) → OS Kernel
```

### 各ブートステージ

| Stage | 名前 | Exception Level | 役割 |
|-------|------|----------------|------|
| **BL1** | AP Trusted ROM | EL3 (Secure) | 初期化、BL2ロード |
| **BL2** | Trusted Boot Firmware | EL1 (Secure) | BL31/BL33ロード |
| **BL31** | EL3 Runtime Firmware | EL3 (Secure) | PSCI実装 |
| **BL33** | Non-Trusted Firmware | EL2 (Non-Secure) | UEFI/U-Boot |

---

## ARM Trusted Firmware (ATF)

ARMのセキュアブート実装です。

### PSCI (Power State Coordination Interface)

```c
// BL31での PSCI実装例
int32_t psci_cpu_on(u_register_t target_cpu,
                    uintptr_t entrypoint,
                    u_register_t context_id)
{
  // CPUをパワーオン
  plat_cpu_pwron(target_cpu);

  // エントリポイント設定
  plat_set_cpu_entrypoint(target_cpu, entrypoint);

  return PSCI_E_SUCCESS;
}
```

### SMC (Secure Monitor Call)

```asm
; Linux から PSCI呼び出し
; X0 = PSCI Function ID
; X1-X3 = Parameters
MOV X0, #0xC4000003  ; PSCI_CPU_ON
MOV X1, #1           ; Target CPU
LDR X2, =entry_point ; Entry point
SMC #0               ; Secure Monitor Call
```

---

## UEFI on ARM

### EDK II ARM実装

```c
// ArmPlatformPkg/PrePi/MainMPCore.c
VOID CEntryPoint(
  IN UINTN MpId,
  IN UINTN SecBootMode
)
{
  // MMU設定
  ArmConfigureMmu();

  // HOB構築
  BuildHobList();

  // DXEコアロード
  LoadDxeCore();
}
```

---

## Device Tree

ARM システムではハードウェア記述にDevice Treeを使用します。

### 例: Raspberry Pi 4

```dts
/ {
  compatible = "raspberrypi,4-model-b", "brcm,bcm2711";
  model = "Raspberry Pi 4 Model B";

  memory@0 {
    device_type = "memory";
    reg = <0x0 0x0 0x0 0x40000000>;  // 1GB
  };

  soc {
    uart0: serial@7e201000 {
      compatible = "arm,pl011", "arm,primecell";
      reg = <0x7e201000 0x200>;
      interrupts = <GIC_SPI 57 IRQ_TYPE_LEVEL_HIGH>;
    };
  };
};
```

---

## x86との主な違い

| 項目 | x86 | ARM64 |
|------|-----|-------|
| **リセットベクタ** | 0xFFFFFFF0 | SoC依存 |
| **セキュリティ** | SMM | TrustZone (EL3) |
| **初期化** | BIOS/UEFI | ATF + UEFI/U-Boot |
| **ハードウェア記述** | ACPI | Device Tree + ACPI |
| **割り込み** | APIC/x2APIC | GIC (Generic Interrupt Controller) |

---

次章: [Part VI Chapter 8: ARM と x86 の違い](08-arm-vs-x86.md)
