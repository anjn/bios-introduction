# 参考文献とリソース

本書の執筆にあたって参照した主要な文献・資料をカテゴリ別にまとめました。

---

## 📚 公式仕様書

### UEFI/ACPI 仕様

| 仕様書 | URL | 説明 |
|--------|-----|------|
| **UEFI Specification** | https://uefi.org/specifications | UEFI の公式仕様書（最新版 2.10） |
| **ACPI Specification** | https://uefi.org/specifications | ACPI の公式仕様書（最新版 6.5） |
| **PI Specification** | https://uefi.org/specifications | Platform Initialization 仕様 |
| **UEFI Shell Specification** | https://uefi.org/specifications | UEFI シェルの仕様 |

### プロセッサアーキテクチャ

| 仕様書 | URL | 説明 |
|--------|-----|------|
| **Intel® 64 and IA-32 Architectures Software Developer Manuals** | https://www.intel.com/sdm | Intel x86/x86_64 の完全な仕様書 |
| **AMD64 Architecture Programmer's Manual** | https://www.amd.com/en/support/tech-docs | AMD64 アーキテクチャの仕様書 |
| **ARM Architecture Reference Manual** | https://developer.arm.com/architectures | ARM アーキテクチャの公式仕様書 |
| **RISC-V Specifications** | https://riscv.org/technical/specifications/ | RISC-V ISA の仕様書 |

### ハードウェア仕様

| 仕様書 | URL | 説明 |
|--------|-----|------|
| **PCI/PCIe Base Specification** | https://pcisig.com/specifications | PCI-SIG の PCIe 仕様書 |
| **USB Specifications** | https://www.usb.org/documents | USB-IF の USB 仕様書 |
| **NVMe Specification** | https://nvmexpress.org/specifications/ | NVMe の仕様書 |
| **SATA AHCI Specification** | https://www.intel.com/content/www/us/en/io/serial-ata/ahci.html | AHCI 仕様書 |

### セキュリティ仕様

| 仕様書 | URL | 説明 |
|--------|-----|------|
| **TPM 2.0 Library Specification** | https://trustedcomputinggroup.org/resource/tpm-library-specification/ | TPM 2.0 の仕様書 |
| **TCG PC Client Platform Firmware Profile** | https://trustedcomputinggroup.org/ | TPM を使用した PC ファームウェアの仕様 |
| **Intel Boot Guard Reference** | Intel の公式ドキュメント | Boot Guard の実装仕様 |

---

## 📖 EDK II ドキュメント

### 公式ドキュメント

| ドキュメント | URL | 説明 |
|------------|-----|------|
| **EDK II GitHub** | https://github.com/tianocore/edk2 | EDK II のメインリポジトリ |
| **TianoCore Wiki** | https://github.com/tianocore/tianocore.github.io/wiki | EDK II の公式 Wiki |
| **EDK II Module Writer's Guide** | https://tianocore-docs.github.io/edk2-ModuleWriteGuide/ | モジュール開発ガイド |
| **EDK II Build Specification** | https://tianocore-docs.github.io/edk2-BuildSpecification/ | ビルドシステムの仕様 |
| **EDK II DEC Specification** | https://tianocore-docs.github.io/edk2-DecSpecification/ | DEC ファイルの仕様 |
| **EDK II INF Specification** | https://tianocore-docs.github.io/edk2-InfSpecification/ | INF ファイルの仕様 |
| **EDK II DSC Specification** | https://tianocore-docs.github.io/edk2-DscSpecification/ | DSC ファイルの仕様 |

### 実装ガイド

| ドキュメント | URL | 説明 |
|------------|-----|------|
| **Getting Started with EDK II** | https://github.com/tianocore/tianocore.github.io/wiki/Getting-Started-with-EDK-II | 初心者向けガイド |
| **OVMF** | https://github.com/tianocore/tianocore.github.io/wiki/OVMF | QEMU/KVM 用 UEFI ファームウェア |
| **EDK II Platforms** | https://github.com/tianocore/edk2-platforms | 各種プラットフォームの実装例 |

---

## 🔧 coreboot ドキュメント

| ドキュメント | URL | 説明 |
|------------|-----|------|
| **coreboot Documentation** | https://doc.coreboot.org/ | coreboot の公式ドキュメント |
| **coreboot Developer Manual** | https://doc.coreboot.org/getting_started/index.html | 開発者向けマニュアル |
| **coreboot GitHub** | https://github.com/coreboot/coreboot | coreboot のリポジトリ |
| **flashrom** | https://www.flashrom.org/ | フラッシュ書き込みツール |

---

## 🌐 その他のファームウェア

| プロジェクト | URL | 説明 |
|-----------|-----|------|
| **U-Boot** | https://www.denx.de/wiki/U-Boot | 組込み向けブートローダ |
| **ARM Trusted Firmware** | https://www.trustedfirmware.org/ | ARM の Trusted Firmware |
| **Slim Bootloader** | https://slimbootloader.github.io/ | Intel の軽量ブートローダ |
| **OpenSBI** | https://github.com/riscv-software-src/opensbi | RISC-V Supervisor Binary Interface |
| **RISC-V U-Boot** | https://www.denx.de/wiki/U-Boot/RISC-V | RISC-V 向け U-Boot |

---

## 📘 書籍

### UEFI/BIOS 関連

| 書籍名 | 著者 | 出版年 | 説明 |
|--------|------|--------|------|
| **Beyond BIOS: Developing with the Unified Extensible Firmware Interface** | Vincent Zimmer, Michael Rothman, et al. | 2017 | UEFI 開発の決定版書籍 |
| **UEFI原理とプログラミング** | 戎 耀宗 | 2015 | UEFI の日本語解説書 |
| **Harnessing the UEFI Shell** | Michael Rothman, et al. | 2016 | UEFI シェルの詳細解説 |

### x86 アーキテクチャ

| 書籍名 | 著者 | 出版年 | 説明 |
|--------|------|--------|------|
| **Intel® 64 and IA-32 Architectures Software Developer's Manual** | Intel | 最新版 | x86/x86_64 の完全リファレンス |
| **コンピュータの構成と設計** | David A. Patterson, John L. Hennessy | 2021 | コンピュータアーキテクチャの教科書 |

### OS 開発

| 書籍名 | 著者 | 出版年 | 説明 |
|--------|------|--------|------|
| **30日でできる！OS自作入門** | 川合秀実 | 2006 | OS 開発の入門書 |
| **はじめてのOSコードリーディング** | 青柳隆宏 | 2013 | Linux カーネルの解説 |
| **ゼロからのOS自作入門** | 内田公太 | 2021 | UEFI からの OS 開発 |

---

## 🎓 オンラインリソース

### チュートリアル・ガイド

| リソース | URL | 説明 |
|---------|-----|------|
| **OSDev.org** | https://wiki.osdev.org/ | OS 開発の総合 Wiki |
| **UEFI Programming - First Steps** | https://wiki.osdev.org/UEFI | UEFI プログラミング入門 |
| **Bare Metal Programming Guide** | https://github.com/cpq/bare-metal-programming-guide | ベアメタルプログラミング |

### ブログ・記事

| リソース | 説明 |
|---------|------|
| **Intel Firmware Engineering Blog** | Intel のファームウェア技術ブログ |
| **Tianocore Community** | EDK II コミュニティのブログ |
| **coreboot Blog** | coreboot プロジェクトのブログ |

---

## 🛠️ 開発ツール

### デバッグツール

| ツール | URL | 説明 |
|--------|-----|------|
| **GDB (GNU Debugger)** | https://www.gnu.org/software/gdb/ | デバッガ |
| **QEMU** | https://www.qemu.org/ | エミュレータ |
| **JTAG Debuggers** | 各ベンダー | ハードウェアデバッガ |

### ビルドツール

| ツール | URL | 説明 |
|--------|-----|------|
| **acpica** | https://www.acpica.org/ | ACPI ツール（iasl, acpidump） |
| **UEFITool** | https://github.com/LongSoft/UEFITool | UEFI イメージ解析ツール |
| **flashrom** | https://www.flashrom.org/ | フラッシュメモリ書き込み |

---

## 💬 コミュニティ

### メーリングリスト

| コミュニティ | URL | 説明 |
|------------|-----|------|
| **TianoCore (EDK II)** | https://edk2.groups.io/ | EDK II のメーリングリスト |
| **coreboot** | https://www.coreboot.org/Mailinglist | coreboot メーリングリスト |
| **U-Boot** | https://lists.denx.de/listinfo/u-boot | U-Boot メーリングリスト |

### フォーラム・チャット

| コミュニティ | URL | 説明 |
|------------|-----|------|
| **UEFI Forum** | https://uefi.org/ | UEFI の公式フォーラム |
| **coreboot IRC** | `#coreboot` on libera.chat | coreboot IRC チャンネル |
| **OSDev Discord** | https://discord.gg/RnCtsqD | OS 開発 Discord |

---

## 🎤 カンファレンス・イベント

| イベント | URL | 説明 |
|---------|-----|------|
| **UEFI Plugfest** | https://uefi.org/ | UEFI の開発者イベント |
| **Open Source Firmware Conference (OSFC)** | https://osfc.io/ | オープンソースファームウェアのカンファレンス |
| **Linaro Connect** | https://connect.linaro.org/ | ARM エコシステムのイベント |

---

## 📰 ニュース・最新情報

| リソース | URL | 説明 |
|---------|-----|------|
| **Phoronix** | https://www.phoronix.com/ | Linux/オープンソースのニュース |
| **LWN.net** | https://lwn.net/ | Linux カーネル関連ニュース |
| **The Register - Systems** | https://www.theregister.com/systems/ | ハードウェア・システムニュース |

---

## 🔐 セキュリティリソース

| リソース | URL | 説明 |
|---------|-----|------|
| **NIST SP 800-193** | https://csrc.nist.gov/publications/detail/sp/800-193/final | Platform Firmware Resiliency Guidelines |
| **MITRE ATT&CK - Firmware** | https://attack.mitre.org/ | ファームウェア攻撃の分類 |
| **Binarly** | https://www.binarly.io/ | ファームウェアセキュリティ |

---

## 🔬 学術論文・研究

### 主要な論文

| タイトル | 著者 | 年 | 説明 |
|---------|------|-----|------|
| **Attacking Intel BIOS** | Invisible Things Lab | 2009 | SMM 攻撃の先駆的研究 |
| **Defeating Signed BIOS Enforcement** | Copernicus et al. | 2014 | Boot Guard 攻撃 |
| **Thunderstrike** | Trammell Hudson | 2015 | Mac ファームウェア攻撃 |
| **SPI Flash Security** | Intel | 2016 | SPI フラッシュ保護 |

### 研究機関

| 機関 | URL | 説明 |
|------|-----|------|
| **MITRE** | https://www.mitre.org/ | サイバーセキュリティ研究 |
| **NIST** | https://www.nist.gov/ | 米国標準技術研究所 |
| **University Research** | 各大学 | セキュリティ研究 |

---

## 📦 実装例・サンプルコード

| リソース | URL | 説明 |
|---------|-----|------|
| **edk2-platforms** | https://github.com/tianocore/edk2-platforms | EDK II プラットフォーム実装集 |
| **MdeModulePkg** | EDK II リポジトリ | EDK II の標準モジュール |
| **coreboot mainboards** | coreboot リポジトリ | coreboot のボード実装集 |

---

## 🌏 各国のコミュニティ

### 日本語リソース

| リソース | URL | 説明 |
|---------|-----|------|
| **OS自作入門wiki** | https://osdev-jp.readthedocs.io/ | 日本語 OS 開発 Wiki |
| **UEFI 勉強会** | 各種イベント | 日本国内の勉強会 |

### 中国語リソース

| リソース | URL | 説明 |
|---------|-----|------|
| **UEFI.org.cn** | http://www.uefi.org.cn/ | 中国語 UEFI コミュニティ |

---

## 📌 その他の有用なリソース

### GitHub リポジトリ

| リポジトリ | URL | 説明 |
|-----------|-----|------|
| **Awesome UEFI** | https://github.com/ffri/awesome-uefi | UEFI リソース集 |
| **Awesome Firmware Security** | https://github.com/PreOS-Security/awesome-firmware-security | ファームウェアセキュリティリソース集 |

### ベンダー公式ドキュメント

| ベンダー | URL | 説明 |
|---------|-----|------|
| **Intel Resource & Design Center** | https://www.intel.com/content/www/us/en/design/resource-design-center.html | Intel の技術資料 |
| **AMD Developer Central** | https://developer.amd.com/ | AMD の技術資料 |
| **ARM Developer** | https://developer.arm.com/ | ARM の技術資料 |

---

## 📝 関連する標準化団体

| 団体 | URL | 説明 |
|------|-----|------|
| **UEFI Forum** | https://uefi.org/ | UEFI/ACPI の標準化 |
| **Trusted Computing Group (TCG)** | https://trustedcomputinggroup.org/ | TPM などの標準化 |
| **PCI-SIG** | https://pcisig.com/ | PCI/PCIe の標準化 |
| **USB-IF** | https://www.usb.org/ | USB の標準化 |
| **JEDEC** | https://www.jedec.org/ | メモリ規格の標準化 |

---

## 🔄 継続的な学習

### 推奨する学習パス

1. **基礎**: 本書 Part 0-I を完了
2. **実装**: Part II-III で EDK II 開発を習得
3. **セキュリティ**: Part IV でセキュアブートを理解
4. **実践**: 実機でのデバッグと最適化 (Part V)
5. **応用**: coreboot や ARM への展開 (Part VI)
6. **コントリビューション**: オープンソースプロジェクトへの貢献

### 実践プロジェクト

1. QEMU 上で UEFI アプリケーションを作成
2. coreboot を実機でビルド・実行
3. Raspberry Pi 4 で UEFI を動かす
4. オープンソースプロジェクトへバグ報告
5. 自作ドライバを公開

---

**参考文献の活用方法**

- 仕様書は最初から読むのではなく、必要な部分を辞書的に参照
- コミュニティでの質問前に公式ドキュメントを確認
- 新しい情報はカンファレンスやメーリングリストで入手
- 実装例は edk2-platforms や coreboot のコードを参照

---

[目次に戻る](../SUMMARY.md)
