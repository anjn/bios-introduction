# 用語集

本書で使用する主要な用語を五十音順にまとめました。

---

## A

### ACPI (Advanced Configuration and Power Interface)
OS とファームウェア間でハードウェア情報・電源管理情報をやり取りするための規格。テーブル形式でプラットフォーム情報を提供。

### AHCI (Advanced Host Controller Interface)
SATA デバイスを制御するための標準インターフェース。

### AML (ACPI Machine Language)
ACPI テーブル内で実行されるバイトコード言語。

### AP (Application Processor)
マルチコアシステムにおいて、BSP 以外の CPU コア。

### APIC (Advanced Programmable Interrupt Controller)
x86 アーキテクチャの割り込みコントローラ。Local APIC と I/O APIC がある。

## B

### BAR (Base Address Register)
PCI/PCIe デバイスのメモリ・I/O 空間のベースアドレスを格納するレジスタ。

### BDA (BIOS Data Area)
実モードのメモリ 0x400-0x4FF に配置される BIOS データ領域。

### BDS (Boot Device Selection)
UEFI ブートフローの第4フェーズ。起動デバイスを選択してブートローダを起動。

### BIOS (Basic Input/Output System)
コンピュータの基本的な入出力を制御するファームウェア。レガシーBIOS と UEFI を区別する文脈で使われる。

### Boot Guard
Intel のハードウェアベース Verified Boot/Measured Boot 機能。

### BSP (Bootstrap Processor)
マルチコアシステムで最初に起動する CPU コア。

## C

### coreboot
軽量・高速なオープンソースファームウェア。LinuxBIOS の後継。

### CRTM (Core Root of Trust for Measurement)
Measured Boot の起点となる、最初に測定されるコード。

### CSM (Compatibility Support Module)
UEFI 環境でレガシーBIOS をエミュレートするモジュール。

## D

### DMA (Direct Memory Access)
CPU を介さずにデバイスがメモリに直接アクセスする仕組み。

### DSDT (Differentiated System Description Table)
ACPI のメインテーブル。システム固有のハードウェア構成を記述。

### DXE (Driver Execution Environment)
UEFI ブートフローの第3フェーズ。ドライバを実行しデバイスを初期化。

## E

### E820
BIOS INT 15h, AX=E820h で取得できる物理メモリマップ。

### ECAM (Enhanced Configuration Access Mechanism)
PCIe のコンフィグレーション空間へメモリマップドでアクセスする仕組み。

### EDK II (EFI Development Kit II)
Intel が提供する UEFI/PI 仕様の参照実装。

### EFI System Partition (ESP)
GPT ディスクの UEFI ブートローダが格納されるパーティション。FAT32 でフォーマット。

## F

### FADT (Fixed ACPI Description Table)
ACPI の固定情報テーブル。電源管理などの基本情報を含む。

### FSP (Firmware Support Package)
Intel が提供するプラットフォーム初期化コードのバイナリパッケージ。

## G

### GDT (Global Descriptor Table)
x86 プロテクトモードでセグメント記述子を格納するテーブル。

### GOP (Graphics Output Protocol)
UEFI でフレームバッファへアクセスするためのプロトコル。

### GPT (GUID Partition Table)
MBR の後継となるパーティションテーブル形式。UEFI で標準。

## H

### HOB (Hand-Off Block)
UEFI の PEI から DXE へ情報を渡すためのデータ構造。

### HPET (High Precision Event Timer)
高精度イベントタイマ。ACPI で定義。

## I

### IDT (Interrupt Descriptor Table)
x86 で割り込みハンドラのアドレスを格納するテーブル。

### IOMMU (Input-Output Memory Management Unit)
デバイスからのメモリアクセスを仮想化・保護するハードウェア。Intel VT-d, AMD-Vi など。

## L

### Long Mode
x86_64 の 64bit ネイティブモード。

## M

### MADT (Multiple APIC Description Table)
ACPI テーブルの一つ。APIC の構成情報を記述。

### MBR (Master Boot Record)
レガシーBIOS で使われるパーティションテーブル形式。2TB の制限あり。

### MCFG (Memory Mapped Configuration Table)
PCIe ECAM の設定を記述する ACPI テーブル。

### MMIO (Memory-Mapped I/O)
デバイスのレジスタをメモリ空間にマップしてアクセスする方式。

### MRC (Memory Reference Code)
Intel プラットフォームの DRAM 初期化コード。

### MSR (Model-Specific Register)
CPU 固有の機能を制御するレジスタ。`rdmsr`/`wrmsr` 命令でアクセス。

## N

### NVMe (Non-Volatile Memory Express)
高速 SSD のための通信プロトコル。PCIe ベース。

### NVRAM
不揮発性メモリ。UEFI 変数の保存に使用。

## O

### OVMF (Open Virtual Machine Firmware)
QEMU/KVM 用の EDK II ベース UEFI ファームウェア。

## P

### Pcd (Platform Configuration Database)
EDK II でプラットフォーム固有の設定値を管理する仕組み。

### PCI (Peripheral Component Interconnect)
周辺デバイス接続用のバス規格。

### PCIe (PCI Express)
PCI の後継。高速シリアル通信。

### PEI (Pre-EFI Initialization)
UEFI ブートフローの第2フェーズ。メモリ初期化など最小限の初期化を実行。

### PIC (Programmable Interrupt Controller)
レガシーな割り込みコントローラ (8259)。

### POST (Power-On Self-Test)
電源投入時のハードウェア自己診断。

### PSP (Platform Security Processor)
AMD プラットフォームのセキュリティプロセッサ。

### PXE (Preboot Execution Environment)
ネットワーク経由でブートするための規格。

## R

### RAS (Reliability, Availability, Serviceability)
サーバの信頼性・可用性・保守性を高める機能群。

### RSDP (Root System Description Pointer)
ACPI テーブルのルートポインタ。

## S

### SEC (Security Phase)
UEFI ブートフローの第1フェーズ。リセット直後の最小限の初期化。

### Secure Boot
UEFI の署名検証機能。不正なブートローダの実行を防ぐ。

### SMBIOS (System Management BIOS)
システム情報（CPU、メモリ、マザーボード情報など）を OS に提供する規格。

### SMBus (System Management Bus)
システム管理用の低速バス。SPD の読み出しなどに使用。

### SMM (System Management Mode)
x86 の特権モード。OS から独立して動作。ファームウェアの特権的な処理に使用。

### SPD (Serial Presence Detect)
メモリモジュールに搭載された設定情報。SMBus 経由で読み出し。

### SPI (Serial Peripheral Interface)
シリアル通信規格。BIOS フラッシュメモリの接続に使用。

## T

### TCG (Trusted Computing Group)
TPM などのトラステッドコンピューティング技術を標準化する団体。

### TPM (Trusted Platform Module)
暗号鍵・測定値を安全に保存するセキュリティチップ。

### TSC (Time Stamp Counter)
CPU クロックをカウントする x86 のカウンタ。

## U

### UEFI (Unified Extensible Firmware Interface)
レガシーBIOS の後継となる標準ファームウェアインターフェース。

## V

### VT-d (Intel Virtualization Technology for Directed I/O)
Intel の IOMMU 実装。

## X

### XHCI (eXtensible Host Controller Interface)
USB 3.0 以降のホストコントローラインターフェース。

---

[目次に戻る](../SUMMARY.md)
