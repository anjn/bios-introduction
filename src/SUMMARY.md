# Summary

[はじめに](./introduction.md)

---

# Part 0. ウォームアップ：道具と全体像

- [本書のゴールと学習ロードマップ](./part0/01-goals-and-roadmap.md)
- [開発環境のセットアップ (Linux/macOS)](./part0/02-dev-environment-unix.md)
- [開発環境のセットアップ (Windows)](./part0/03-dev-environment-windows.md)
- [デバッグ環境の準備](./part0/04-debug-setup.md)
- [Part 0 まとめとチェックリスト](./part0/05-warmup-checklist.md)

---

# Part I. x86_64 ブートの基礎を最短理解

- [リセットから最初の命令まで](./part1/01-reset-vector.md)
- [メモリマップと E820](./part1/02-memory-map.md)
- [CPU モード遷移の全体像](./part1/03-cpu-mode-transition.md)
- [割り込みとタイマ](./part1/04-interrupts-and-timers.md)
- [UEFI ブートフローの全体像](./part1/05-uefi-boot-flow.md)
- [UEFI ドライバとアプリケーション](./part1/06-uefi-drivers-and-apps.md)
- [Part I まとめと演習](./part1/07-basics-summary.md)

---

# Part II. 実装に踏み込む：EDK II で手を動かす

- [最小の UEFI アプリを作る](./part2/01-hello-world.md)
- [.inf/.dec/.dsc ファイルの理解](./part2/02-edk2-files.md)
- [DXE ドライバ入門](./part2/03-dxe-driver-basics.md)
- [メモリとデバイスアクセス](./part2/04-memory-and-device-access.md)
- [画面出力と GOP](./part2/05-graphics-output.md)
- [ストレージブート](./part2/06-storage-boot.md)
- [USB ブート](./part2/07-usb-boot.md)
- [Part II 実践演習：ブートローダを作る](./part2/08-bootloader-exercise.md)

---

# Part III. プラットフォーム初期化の勘所

- [DRAM 初期化とメモリサービス](./part3/01-dram-init.md)
- [CPU とチップセット初期化](./part3/02-cpu-chipset-init.md)
- [PCH/SoC 初期化](./part3/03-pch-soc-init.md)
- [PCIe 初期化とデバイス列挙](./part3/04-pcie-enumeration.md)
- [ACPI テーブル基礎](./part3/05-acpi-basics.md)
- [ACPI テーブル実装](./part3/06-acpi-implementation.md)
- [SMBIOS と MP テーブル](./part3/07-smbios-and-mp.md)
- [Part III まとめとハマりポイント](./part3/08-platform-init-summary.md)

---

# Part IV. セキュリティと信頼の確立

- [UEFI Secure Boot 基礎](./part4/01-secure-boot-basics.md)
- [UEFI Secure Boot 実装](./part4/02-secure-boot-implementation.md)
- [TPM と Measured Boot](./part4/03-tpm-and-measured-boot.md)
- [Intel Boot Guard と BIOS Guard](./part4/04-intel-boot-guard.md)
- [AMD Platform Security Processor (PSP)](./part4/05-amd-psp.md)
- [SPI フラッシュ保護](./part4/06-spi-flash-protection.md)
- [SMM セキュリティ](./part4/07-smm-security.md)
- [セキュリティ CVE 事例研究](./part4/08-security-cve-cases.md)
- [Part IV まとめ：セキュリティチェックリスト](./part4/09-security-checklist.md)

---

# Part V. デバッグ、最適化、実機展開

- [デバッグの実践：失敗パターン別対処](./part5/01-debug-failure-patterns.md)
- [デバッグツールの活用](./part5/02-debug-tools.md)
- [ブート時間短縮術](./part5/03-boot-time-optimization.md)
- [S3/Modern Standby 対応](./part5/04-s3-modern-standby.md)
- [品質保証と自動テスト](./part5/05-qa-and-testing.md)
- [ファームウェア更新](./part5/06-firmware-update.md)
- [実機展開と量産](./part5/07-production-deployment.md)
- [Part V 実践演習：デバッグチャレンジ](./part5/08-debug-challenge.md)

---

# Part VI. オルタナティブと発展

- [coreboot で学ぶ軽量ブートフロー](./part6/01-coreboot-intro.md)
- [coreboot ビルドと実行](./part6/02-coreboot-build.md)
- [レガシー BIOS の最小限](./part6/03-legacy-bios.md)
- [ネットワークブート](./part6/04-network-boot.md)
- [サーバプラットフォーム固有事項](./part6/05-server-platforms.md)
- [組込み・ノート PC 固有事項](./part6/06-embedded-notebook.md)
- [ARM64 ブート入門](./part6/07-arm64-boot.md)
- [総合演習：ゼロから Linux 起動](./part6/08-zero-to-linux.md)
- [Part VI まとめ](./part6/09-alternative-summary.md)

---

# 付録・リファレンス

- [コミュニティとリソース](./appendix/communities-and-resources.md)
- [クイックリファレンス](./appendix/quick-reference.md)
- [用語集](./appendix/glossary.md)
- [索引](./appendix/index.md)
- [参考文献](./appendix/bibliography.md)
- [演習解答例](./appendix/exercise-solutions.md)
