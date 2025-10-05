# Summary

[はじめに](./introduction.md)

---

# Part 0. BIOS/UEFIの全体像

- [本書のゴールと学習ロードマップ](./part0/01-goals-and-roadmap.md)
- [BIOS/UEFIとは何か：歴史と役割](./part0/02-what-is-bios-uefi.md)
- [ファームウェアエコシステム全体像](./part0/03-firmware-ecosystem.md)
- [学習環境の概要とツールの位置づけ](./part0/04-learning-environment.md)
- [Part 0 まとめ](./part0/05-part0-summary.md)

---

# Part I. x86_64 ブート基礎：CPUとメモリ

- [リセットから最初の命令まで](./part1/01-reset-vector.md)
- [メモリマップと E820](./part1/02-memory-map.md)
- [CPU モード遷移の全体像](./part1/03-cpu-mode-transition.md)
- [割り込みとタイマの仕組み](./part1/04-interrupts-and-timers.md)
- [UEFI ブートフェーズの全体像](./part1/05-uefi-boot-flow.md)
- [各ブートフェーズの役割と責務](./part1/06-boot-phase-responsibilities.md)
- [Part I まとめ](./part1/07-part1-summary.md)

---

# Part II. EDK II アーキテクチャの理解

- [EDK II の設計思想と全体構成](./part2/01-edk2-architecture.md)
- [モジュール構造とビルドシステム](./part2/02-module-and-build-system.md)
- [プロトコルとドライバモデル](./part2/03-protocol-and-driver-model.md)
- [ライブラリアーキテクチャ](./part2/04-library-architecture.md)
- [ハードウェア抽象化の仕組み](./part2/05-hardware-abstraction.md)
- [グラフィックスサブシステム (GOP)](./part2/06-graphics-subsystem.md)
- [ストレージスタックの構造](./part2/07-storage-stack.md)
- [USB スタックの構造](./part2/08-usb-stack.md)
- [ブートマネージャとブートローダの役割](./part2/09-boot-manager-loader.md)
- [Part II まとめ](./part2/10-part2-summary.md)

---

# Part III. プラットフォーム初期化の仕組み

- [PEI フェーズの役割と構造](./part3/01-pei-phase-architecture.md)
- [DRAM 初期化の仕組み](./part3/02-dram-init.md)
- [CPU とチップセット初期化](./part3/03-cpu-chipset-init.md)
- [PCH/SoC の役割と初期化](./part3/04-pch-soc-init.md)
- [PCIe の仕組みとデバイス列挙](./part3/05-pcie-enumeration.md)
- [ACPI の目的と構造](./part3/06-acpi-architecture.md)
- [ACPI テーブルの役割](./part3/07-acpi-tables.md)
- [SMBIOS と MP テーブルの役割](./part3/08-smbios-and-mp.md)
- [Part III まとめ](./part3/09-part3-summary.md)

---

# Part IV. セキュリティアーキテクチャ

- [ファームウェアセキュリティの全体像](./part4/01-firmware-security-overview.md)
- [信頼チェーンの構築](./part4/02-chain-of-trust.md)
- [UEFI Secure Boot の仕組み](./part4/03-secure-boot-architecture.md)
- [TPM と Measured Boot](./part4/04-tpm-and-measured-boot.md)
- [Intel Boot Guard の役割と仕組み](./part4/05-intel-boot-guard.md)
- [AMD PSP の役割と仕組み](./part4/06-amd-psp.md)
- [SPI フラッシュ保護機構](./part4/07-spi-flash-protection.md)
- [SMM の仕組みとセキュリティ](./part4/08-smm-security.md)
- [攻撃事例から学ぶ設計原則](./part4/09-security-case-studies.md)
- [Part IV まとめ](./part4/10-part4-summary.md)

---

# Part V. デバッグと最適化の原理

- [ファームウェアデバッグの基礎](./part5/01-debug-fundamentals.md)
- [デバッグツールの仕組み](./part5/02-debug-tools-mechanism.md)
- [典型的な問題パターンと原因](./part5/03-common-issues.md)
- [ログとトレースの設計](./part5/04-logging-and-tracing.md)
- [パフォーマンス測定の原理](./part5/05-performance-measurement.md)
- [ブート時間最適化の考え方](./part5/06-boot-time-optimization.md)
- [電源管理の仕組み (S3/Modern Standby)](./part5/07-power-management.md)
- [ファームウェア更新の仕組み](./part5/08-firmware-update-mechanism.md)
- [Part V まとめ](./part5/09-part5-summary.md)

---

# Part VI. 他のファームウェア実装と発展

- [ファームウェアの多様性](./part6/01-firmware-diversity.md)
- [coreboot の設計思想](./part6/02-coreboot-philosophy.md)
- [coreboot と EDK II の比較](./part6/03-coreboot-vs-edk2.md)
- [レガシー BIOS アーキテクチャ](./part6/04-legacy-bios-architecture.md)
- [ネットワークブートの仕組み](./part6/05-network-boot.md)
- [プラットフォーム別の特性：サーバ/組込み/モバイル](./part6/06-platform-characteristics.md)
- [ARM64 ブートアーキテクチャ](./part6/07-arm64-boot-architecture.md)
- [ARM と x86 の違い](./part6/08-arm-vs-x86.md)
- [ファームウェアの将来展望](./part6/09-future-of-firmware.md)
- [Part VI まとめ](./part6/10-part6-summary.md)

---

# 付録・リファレンス

- [用語集](./appendix/glossary.md)
- [参考文献とリソース](./appendix/bibliography.md)
- [仕様書クイックリファレンス](./appendix/spec-quick-reference.md)
- [コミュニティとリソース](./appendix/communities-and-resources.md)
- [索引](./appendix/index.md)
