# コミュニティとリソース

ファームウェア開発に関わるコミュニティ、フォーラム、学習リソースをまとめました。

---

## 💬 オープンソースコミュニティ

### TianoCore (EDK II)

**公式サイト**: https://www.tianocore.org/

#### メーリングリスト

| リスト名 | 説明 | URL |
|---------|------|-----|
| **edk2-devel** | EDK II 開発全般 | https://edk2.groups.io/g/devel |
| **edk2-discuss** | 一般的な議論 | https://edk2.groups.io/g/discuss |
| **edk2-rfc** | RFC (Request for Comments) | https://edk2.groups.io/g/rfc |

#### GitHub

- **メインリポジトリ**: https://github.com/tianocore/edk2
- **edk2-platforms**: https://github.com/tianocore/edk2-platforms
- **Issue Tracker**: https://github.com/tianocore/edk2/issues

#### コントリビューション方法

1. **Bugzilla でバグ報告**: https://bugzilla.tianocore.org/
2. **GitHub で Pull Request** を作成
3. **メーリングリストでパッチ送信**（従来の方法）

**開発者ガイド**: https://github.com/tianocore/tianocore.github.io/wiki/EDK-II-Development-Process

---

### coreboot

**公式サイト**: https://www.coreboot.org/

#### コミュニケーションチャネル

| チャネル | 説明 | URL/場所 |
|---------|------|---------|
| **IRC** | リアルタイムチャット | `#coreboot` on libera.chat |
| **メーリングリスト** | 開発議論 | https://www.coreboot.org/Mailinglist |
| **Gerrit** | コードレビュー | https://review.coreboot.org/ |

#### ドキュメント

- **Documentation**: https://doc.coreboot.org/
- **Getting Started**: https://doc.coreboot.org/getting_started/index.html
- **Developer Guide**: https://doc.coreboot.org/contributing/index.html

#### コントリビューション方法

1. **Gerrit でアカウント作成**
2. **パッチを投稿**（`git push` で Gerrit へ）
3. **コードレビューを受ける**
4. **承認後にマージ**

**詳細**: https://doc.coreboot.org/contributing/gerrit_guidelines.html

---

### U-Boot

**公式サイト**: https://www.denx.de/wiki/U-Boot

#### コミュニケーション

| チャネル | 説明 | URL |
|---------|------|-----|
| **メーリングリスト** | u-boot@lists.denx.de | https://lists.denx.de/listinfo/u-boot |
| **IRC** | `#u-boot` on libera.chat | - |

#### リポジトリ

- **GitLab**: https://source.denx.de/u-boot/u-boot
- **GitHub (ミラー)**: https://github.com/u-boot/u-boot

#### コントリビューション

- **パッチ送信**: メーリングリストへメール
- **Custodian Tree**: 各サブシステムごとに担当者あり

**ガイド**: https://u-boot.readthedocs.io/en/latest/develop/sending_patches.html

---

### Linux Kernel (ACPI/EFI)

#### サブシステム

| サブシステム | メーリングリスト | 担当者 |
|------------|---------------|--------|
| **EFI** | linux-efi@vger.kernel.org | Ard Biesheuvel |
| **ACPI** | linux-acpi@vger.kernel.org | Rafael J. Wysocki |

#### リソース

- **LKML**: https://lkml.org/
- **LWN.net**: https://lwn.net/ (Kernel ニュース)

---

## 🏢 業界団体・標準化組織

### UEFI Forum

**公式サイト**: https://uefi.org/

#### 活動内容

- UEFI/ACPI 仕様の策定
- UEFI Plugfest (開発者イベント)
- 技術ワーキンググループ

#### メンバーシップ

| レベル | 費用 | 権限 |
|--------|------|------|
| **Promoter** | $50,000/年 | 仕様策定に参加 |
| **Contributor** | $5,000/年 | 技術貢献 |
| **Adopter** | 無料 | 仕様の利用 |

**詳細**: https://uefi.org/join

---

### Trusted Computing Group (TCG)

**公式サイト**: https://trustedcomputinggroup.org/

#### 主要な仕様

- TPM 2.0 Library Specification
- TCG PC Client Platform Firmware Profile
- TCG Network Device

#### ワーキンググループ

- PC Client WG
- Storage WG
- Embedded Systems WG

---

### PCI-SIG

**公式サイト**: https://pcisig.com/

#### 主要な活動

- PCI/PCIe 仕様策定
- Compliance Workshop (準拠性テスト)

---

## 🎓 学習コミュニティ

### OSDev.org

**公式サイト**: https://wiki.osdev.org/

#### 主要コンテンツ

- **Wiki**: OS 開発の総合知識ベース
- **Forum**: https://forum.osdev.org/
- **Discord**: https://discord.gg/RnCtsqD

#### 人気トピック

- [UEFI](https://wiki.osdev.org/UEFI)
- [ACPI](https://wiki.osdev.org/ACPI)
- [PCI](https://wiki.osdev.org/PCI)

---

### Reddit

| サブレディット | 説明 | 購読者数 |
|-------------|------|---------|
| **r/osdev** | OS 開発全般 | ~40k |
| **r/lowlevel** | 低レベルプログラミング | ~25k |
| **r/ReverseEngineering** | リバースエンジニアリング | ~180k |

---

## 📅 カンファレンス・イベント

### 主要なカンファレンス

| イベント | 頻度 | 説明 | URL |
|---------|------|------|-----|
| **UEFI Plugfest** | 年2回 | UEFI 開発者イベント | https://uefi.org/ |
| **Open Source Firmware Conference (OSFC)** | 年1回 | オープンソースファームウェア | https://osfc.io/ |
| **Linaro Connect** | 年2回 | ARM エコシステム | https://connect.linaro.org/ |
| **Linux Plumbers Conference** | 年1回 | Linux カーネル開発 | https://www.linuxplumbersconf.org/ |
| **FOSDEM** | 年1回 | 欧州最大の OSS イベント | https://fosdem.org/ |

### 日本国内のイベント

| イベント | 頻度 | 説明 |
|---------|------|------|
| **カーネル/VM探検隊** | 年数回 | OS 内部の勉強会 |
| **セキュリティ・キャンプ** | 年1回 | 学生向けセキュリティ講座 |
| **OSC (Open Source Conference)** | 年数回 | 各地で開催される OSS イベント |

---

## 📺 学習リソース

### YouTube チャンネル

| チャンネル | 説明 | 購読者数 |
|-----------|------|---------|
| **Low Level Learning** | 低レベルプログラミング解説 | ~450k |
| **Ben Eater** | コンピュータアーキテクチャ | ~1.1M |
| **LiveOverflow** | セキュリティ・リバエン | ~800k |

### オンラインコース

| プラットフォーム | コース | 説明 |
|---------------|--------|------|
| **Coursera** | Computer Architecture | Princeton 大学の講座 |
| **edX** | Computer Systems | MIT の講座 |
| **Udemy** | x86 Assembly | アセンブリ入門 |

---

## 🐦 ソーシャルメディア

### Twitter/X

主要なアカウント:

| アカウント | 説明 |
|-----------|------|
| **@tianocore** | TianoCore (EDK II) 公式 |
| **@coreboot** | coreboot プロジェクト |
| **@UEFIForum** | UEFI Forum 公式 |
| **@IntelSecurity** | Intel セキュリティ技術 |

ハッシュタグ:

- `#UEFI`
- `#coreboot`
- `#firmware`
- `#osdev`
- `#lowlevel`

---

## 📚 書籍・ドキュメント

### おすすめの書籍

#### UEFI/ファームウェア

1. **Beyond BIOS: Developing with the Unified Extensible Firmware Interface**
   - 著者: Vincent Zimmer, Michael Rothman, et al.
   - 出版: 2017
   - 説明: UEFI 開発のバイブル

2. **UEFI原理とプログラミング**
   - 著者: 戎 耀宗
   - 出版: 2015
   - 説明: 日本語の UEFI 解説書

#### OS 開発

1. **ゼロからのOS自作入門**
   - 著者: 内田公太
   - 出版: 2021
   - 説明: UEFI からの OS 開発

2. **30日でできる！OS自作入門**
   - 著者: 川合秀実
   - 出版: 2006
   - 説明: 古典的 OS 開発入門書

#### アーキテクチャ

1. **Intel® 64 and IA-32 Architectures Software Developer's Manual**
   - 著者: Intel
   - 無料公開
   - URL: https://www.intel.com/sdm

2. **コンピュータの構成と設計**
   - 著者: David A. Patterson, John L. Hennessy
   - 説明: ハードウェア・アーキテクチャの教科書

---

## 🔬 研究機関・大学

### 主要な研究グループ

| 機関 | グループ/研究者 | 専門分野 |
|------|---------------|---------|
| **MIT CSAIL** | Computer Systems | OS・セキュリティ |
| **Stanford** | Computer Architecture | ハードウェア・アーキテクチャ |
| **UC Berkeley** | RISC-V | RISC-V 開発 |
| **CMU** | Systems Group | システムソフトウェア |

### 日本の研究機関

| 機関 | 説明 |
|------|------|
| **産業技術総合研究所 (AIST)** | セキュアシステム研究 |
| **情報通信研究機構 (NICT)** | サイバーセキュリティ |
| **大学共同利用機関** | 各大学の計算機科学研究室 |

---

## 🛡️ セキュリティコミュニティ

### 脆弱性情報

| リソース | URL | 説明 |
|---------|-----|------|
| **CVE (Common Vulnerabilities and Exposures)** | https://cve.mitre.org/ | 脆弱性データベース |
| **NVD (National Vulnerability Database)** | https://nvd.nist.gov/ | NIST の脆弱性 DB |
| **Binarly** | https://www.binarly.io/ | ファームウェア脆弱性 |

### セキュリティカンファレンス

| イベント | 説明 |
|---------|------|
| **Black Hat** | セキュリティカンファレンス |
| **DEF CON** | ハッカーカンファレンス |
| **CanSecWest** | セキュリティ研究 |
| **CODE BLUE** | 日本のセキュリティカンファレンス |

---

## 🌏 地域別コミュニティ

### 北米

- **UEFI Forum** (本部: Beaverton, OR)
- **Linux Foundation** (本部: San Francisco, CA)

### 欧州

- **FOSDEM** (ブリュッセル)
- **Open Source Summit Europe**

### アジア

#### 日本

- **カーネル/VM探検隊**
- **セキュリティ・キャンプ**
- **SECCON**

#### 中国

- **UEFI.org.cn**: http://www.uefi.org.cn/
- **Linux Kernel China**

#### インド

- **ILUG (Indian Linux Users Group)**
- **Linaro India**

---

## 💼 企業の技術コミュニティ

### Intel

- **Intel Developer Zone**: https://www.intel.com/content/www/us/en/developer/overview.html
- **Intel Software Blogs**: https://www.intel.com/content/www/us/en/developer/topic-technology/software-development.html

### AMD

- **AMD Developer Central**: https://developer.amd.com/
- **AMD Open Source**: https://github.com/amd

### ARM

- **ARM Developer**: https://developer.arm.com/
- **ARM Community**: https://community.arm.com/

### Microsoft

- **Project Mu**: https://microsoft.github.io/mu/
- **Windows Hardware Dev Center**: https://docs.microsoft.com/en-us/windows-hardware/

### Google

- **Chromium OS Docs**: https://www.chromium.org/chromium-os/
- **Android Open Source Project**: https://source.android.com/

---

## 📖 Wiki・ドキュメント集

### 技術 Wiki

| Wiki | URL | 説明 |
|------|-----|------|
| **OSDev Wiki** | https://wiki.osdev.org/ | OS 開発総合 |
| **Gentoo Wiki** | https://wiki.gentoo.org/ | Linux 技術情報 |
| **ArchWiki** | https://wiki.archlinux.org/ | Arch Linux 技術情報 |

### GitHub Awesome リスト

| リポジトリ | 説明 |
|-----------|------|
| **awesome-uefi** | UEFI リソース集 |
| **awesome-firmware-security** | ファームウェアセキュリティ |
| **awesome-low-level-programming** | 低レベルプログラミング |

---

## 🗣️ 質問・サポート

### Stack Exchange

| サイト | URL | 説明 |
|--------|-----|------|
| **Stack Overflow** | https://stackoverflow.com/ | プログラミング全般 |
| **Super User** | https://superuser.com/ | システム管理 |
| **Unix & Linux** | https://unix.stackexchange.com/ | Unix/Linux |

### その他フォーラム

- **OSDev Forum**: https://forum.osdev.org/
- **coreboot Mailing List**: https://www.coreboot.org/Mailinglist
- **LKML (Linux Kernel Mailing List)**: https://lkml.org/

---

## 🚀 次のステップ

### 初心者向け

1. **OSDev Wiki** で基礎を学ぶ
2. **r/osdev** で質問する
3. **YouTube チュートリアル** を視聴

### 中級者向け

1. **EDK II メーリングリスト** に参加
2. **coreboot IRC** でリアルタイム議論
3. **GitHub で Issue** を報告

### 上級者向け

1. **UEFI Plugfest** に参加
2. **オープンソースプロジェクトにコントリビュート**
3. **カンファレンスで発表**

---

## 📬 連絡先

### コミュニティに参加する際のマナー

1. **検索してから質問**: 既知の問題か確認
2. **具体的に質問**: エラーメッセージ、環境情報を含める
3. **パッチ送信時**: コーディングスタイルを守る
4. **レビュー対応**: フィードバックに丁寧に対応

### メーリングリストのエチケット

- **plain text** でメール送信（HTML メール NG）
- **トップポスト禁止**（インラインで返信）
- **適切な件名**（`[PATCH]`, `[RFC]` などのプレフィックス）

---

**コミュニティは学びの宝庫です。積極的に参加して、知識を共有しましょう！**

---

[目次に戻る](../SUMMARY.md)
