# ARM64 ブートアーキテクチャ

🎯 **この章で学ぶこと**
- ARM64 (AARCH64) のブート手順
- ARM Trusted Firmware (ATF) の役割
- UEFI on ARMの実装
- Device Treeとの連携

📚 **前提知識**
- [Part I: x86_64 ブート基礎](../part1/01-reset-vector.md)

---

## はじめに

**ARM64（AARCH64）** は、モバイルデバイス、サーバ、組込みシステムで広く使用されるアーキテクチャであり、x86_64 とは根本的に異なるブート手順とセキュリティモデルを持っています。ARM64 のブートは **ARM Trusted Firmware（ATF）** を中心に設計されており、TrustZone テクノロジーによるセキュアブートと PSCI（Power State Coordination Interface）による電源管理が統合されています。x86 では BIOS や UEFI がハードウェア初期化とブート手順を一手に引き受けますが、ARM64 では BL1（Boot ROM）、BL2（Trusted Boot Firmware）、BL31（EL3 Runtime Firmware）、BL33（UEFI/U-Boot）という 4 段階のブートステージが明確に分離され、それぞれが異なる Exception Level（特権レベル）で動作します。また、ARM システムではハードウェア構成を Device Tree（デバイスツリー）で記述し、OS に渡すため、x86 の ACPI とは異なるアプローチを取ります。この章では、ARM64 のブートフロー、ARM Trusted Firmware の役割、UEFI on ARM の実装、Device Tree との連携、そして x86 との主な違いを学びます。

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

## まとめ

この章では、**ARM64 ブートアーキテクチャ**として、ARM Trusted Firmware（ATF）による 4 段階のブートフロー、PSCI と SMC、UEFI on ARM の実装、Device Tree によるハードウェア記述、そして x86 との主な違いを学びました。ARM64 は、TrustZone テクノロジーと Exception Level を活用した堅牢なセキュリティモデルを持ち、モバイルからサーバまで幅広いプラットフォームで採用されています。

**ARM64 ブートフローの 4 段階**は、BL1（AP Trusted ROM、EL3 Secure）→ BL2（Trusted Boot Firmware、EL1 Secure）→ BL31（EL3 Runtime Firmware、EL3 Secure）→ BL33（Non-Trusted Firmware、EL2 Non-Secure）→ OS Kernel という流れです。BL1 は SoC の ROM に焼き込まれたコードであり、最初に実行され、BL2 をロードします。BL2 は BL31 と BL33 をロードして検証します。BL31 は PSCI（Power State Coordination Interface）を実装し、OS からの電源管理要求（CPU ON/OFF、スリープ）を処理します。BL33 は UEFI や U-Boot といった非セキュアなファームウェアであり、最終的に OS カーネルをロードします。この 4 段階の分離により、セキュアな初期化（BL1/BL2/BL31）と非セキュアなブート（BL33）が明確に区別され、TrustZone によるセキュリティが保証されます。

**ARM Trusted Firmware（ATF）** は、ARM のセキュアブート実装であり、BL1、BL2、BL31 を提供します。ATF は、PSCI（Power State Coordination Interface）の参照実装であり、psci_cpu_on 関数で CPU をパワーオンし、エントリポイントを設定します。SMC（Secure Monitor Call）により、非セキュアな OS から EL3 のセキュアモニタを呼び出し、PSCI 機能（CPU ON/OFF、スリープ、リセット）を実行できます。Linux カーネルは、X0 レジスタに PSCI Function ID（例: 0xC4000003 for PSCI_CPU_ON）、X1-X3 にパラメータ（Target CPU、Entry point）を設定し、SMC #0 命令で ATF を呼び出します。

**UEFI on ARM の実装**は、EDK II の ArmPlatformPkg で提供されます。CEntryPoint 関数は、MMU（Memory Management Unit）を設定し、HOB（Hand-Off Block）リストを構築し、DXE コアをロードします。ARM では MMU の初期化が重要であり、ArmConfigureMmu 関数で仮想メモリマッピングを設定します。その後、x86 と同様の DXE → BDS → OS Loader というフローに進みます。

**Device Tree（デバイスツリー）** は、ARM システムでハードウェア構成を記述する宣言的なデータ構造であり、.dts ファイルで記述され、.dtb（Device Tree Blob）にコンパイルされます。Raspberry Pi 4 の例では、compatible プロパティでボードを識別し、memory@0 ノードでメモリアドレスとサイズを記述し、uart0 ノードで UART の互換性、レジスタアドレス、割り込み番号を記述します。UEFI や U-Boot は、この Device Tree を OS に渡し、OS はデバイスドライバを動的にロードします。x86 では ACPI が同様の役割を果たしますが、ARM では Device Tree が主流です（ただし、サーバ向け ARM64 では ACPI も使用されます）。

**x86 との主な違い**として、まず**リセットベクタ**は、x86 が固定アドレス 0xFFFFFFF0 ですが、ARM64 は SoC 依存（通常は ROM の先頭アドレス）です。次に**セキュリティ**は、x86 が SMM（System Management Mode）を使用し、ARM64 は TrustZone（EL3）を使用します。さらに**初期化**は、x86 が BIOS/UEFI で統合的に行いますが、ARM64 は ATF + UEFI/U-Boot という分離アーキテクチャです。また**ハードウェア記述**は、x86 が ACPI を使用し、ARM64 は Device Tree + ACPI（サーバ）を使用します。最後に**割り込み**は、x86 が APIC/x2APIC を使用し、ARM64 は GIC（Generic Interrupt Controller）を使用します。

ARM64 のブートアーキテクチャは、x86 よりもセキュリティを重視した設計であり、TrustZone と Exception Level により、セキュアな処理と非セキュアな処理を明確に分離します。モバイルデバイスやクラウドサーバでのセキュリティ要件の高まりに伴い、ARM64 の採用が拡大しており、ファームウェア開発者は x86 と ARM64 の両方のアーキテクチャを理解することが重要になっています。

以下の参考表は、x86 と ARM64 の主な違いをまとめたものです。

**参考表: x86 と ARM64 の比較**

| 項目 | x86 | ARM64 |
|------|-----|-------|
| **リセットベクタ** | 0xFFFFFFF0 | SoC依存 |
| **セキュリティ** | SMM | TrustZone (EL3) |
| **初期化** | BIOS/UEFI | ATF + UEFI/U-Boot |
| **ハードウェア記述** | ACPI | Device Tree + ACPI |
| **割り込み** | APIC/x2APIC | GIC (Generic Interrupt Controller) |

---

次章: [Part VI Chapter 8: ARM と x86 の違い](08-arm-vs-x86.md)
