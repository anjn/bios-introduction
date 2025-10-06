# プラットフォーム別の特性：サーバ/組込み/モバイル

🎯 **この章で学ぶこと**
- サーバプラットフォームの要件 (RAS, IPMI)
- 組込みシステムの制約 (起動時間、フラッシュサイズ)
- モバイルデバイスの特性 (省電力、Modern Standby)

📚 **前提知識**
- [Part VI Chapter 1: ファームウェアの多様性](01-firmware-diversity.md)

---

## はじめに

**プラットフォームの多様性**は、ファームウェア設計における最も重要な考慮事項の一つです。サーバ、組込みシステム、モバイルデバイスは、それぞれ異なる要件、制約、設計目標を持ち、ファームウェアの実装もそれに応じて大きく異なります。サーバプラットフォームは **RAS（Reliability, Availability, Serviceability）** と**リモート管理**を重視し、24時間365日の稼働を保証するために冗長化とホットプラグをサポートします。組込みシステムは**起動時間の短縮**と**リソースの最小化**を重視し、限られたフラッシュサイズとメモリで動作する必要があります。モバイルデバイスは**省電力**と**即座のレジューム**を重視し、Modern Standby や ACPI S0ix といった高度な電源管理技術を活用します。

**サーバプラットフォーム**の核心は、**高可用性**（High Availability）と**保守性**（Serviceability）です。サーバは、データセンターやエンタープライズ環境で重要なサービスを提供するため、ハードウェア障害による停止を最小化する必要があります。ECC（Error Correcting Code）メモリは、メモリエラーを検出して訂正し、DIMM Sparing はエラーが発生したメモリモジュールを自動的に切り離して予備のモジュールに切り替えます。IPMI（Intelligent Platform Management Interface）や Redfish API は、OS が起動していない状態でもリモートからハードウェアを監視・制御できる Out-of-Band Management を提供します。ホットプラグ（Hot-Plug）は、サーバを停止せずに PCIe カード、CPU、メモリ、電源ユニットを交換できる機能であり、ダウンタイムを最小化します。

**組込みシステム**の核心は、**リソースの制約**と**リアルタイム性**です。産業用コントローラ、ルータ、IoT デバイスなどの組込みシステムは、コストと消費電力を最小化するために、限られたハードウェアリソースで動作する必要があります。フラッシュサイズは通常 1-8 MB であり、UEFI ファームウェア（4-8 MB）を格納するには不十分です。したがって、coreboot や U-Boot といった軽量なファームウェアが使用されます。起動時間は 2 秒未満が求められることが多く、並列初期化、遅延初期化、不要なドライバの削除といった最適化が不可欠です。また、Device Tree（デバイスツリー）を使用してハードウェア構成を宣言的に記述し、コードの再利用性を高めます。

**モバイルデバイス**の核心は、**省電力**と**ユーザーエクスペリエンス**です。ノート PC、タブレット、スマートフォンなどのモバイルデバイスは、バッテリーで動作するため、消費電力を最小化しながら高いパフォーマンスを提供する必要があります。Modern Standby（Connected Standby）は、画面をオフにしてもバックグラウンドでメール受信やメッセージ通知を継続し、即座にレジューム（1 秒未満）できる省電力状態です。ACPI S0ix は、Modern Standby を実現するための低電力アイドル状態であり、CPU をディープスリープ状態にしながらネットワーク接続を維持します。DPTF（Dynamic Platform Thermal Framework）は、温度センサーの情報に基づいて CPU 周波数、ファン速度、ディスプレイ輝度を動的に調整し、性能と温度のバランスを最適化します。

この章では、サーバ、組込みシステム、モバイルデバイスという 3 つの代表的なプラットフォームの特性、要件、ファームウェア実装の違いを学びます。それぞれのプラットフォームが直面する課題と、それに対するファームウェアの設計手法を理解することで、プラットフォームに最適なファームウェアを選択・実装できるようになります。

## サーバプラットフォーム

### 主要な要件

| 要件 | 説明 | 実装 |
|------|------|------|
| **RAS** | Reliability, Availability, Serviceability | ECC Memory, DIMM Sparing |
| **リモート管理** | Out-of-band Management | IPMI, Redfish API |
| **ホットプラグ** | 稼働中の交換 | PCIe Hot-Plug, Hot-Add CPU |
| **大容量メモリ** | TB級メモリ | NUMA, Memory Mirroring |
| **冗長化** | 単一障害点の排除 | Redundant PSU, Network |

### IPMI (Intelligent Platform Management Interface)

```c
// BMC (Baseboard Management Controller) との通信
EFI_STATUS IpmiSendCommand(
  UINT8 NetFunction,
  UINT8 Command,
  VOID *Request,
  UINT32 RequestSize,
  VOID *Response,
  UINT32 *ResponseSize
)
{
  // KCS (Keyboard Controller Style) インターフェース
  WriteKcsCommand(NetFunction, Command);
  WriteKcsData(Request, RequestSize);
  ReadKcsData(Response, ResponseSize);
  return EFI_SUCCESS;
}
```

---

## 組込みシステム

### 制約と要件

| 項目 | 典型値 | 対策 |
|------|--------|------|
| **起動時間** | < 2秒 | 並列初期化、最小化 |
| **フラッシュサイズ** | 1-8 MB | コード圧縮、最小構成 |
| **メモリ** | 512MB - 2GB | 動的メモリ割り当て最小化 |
| **消費電力** | < 5W | S3/S4サポート、動的周波数調整 |

### U-Bootでの実装例

```c
// board/myboard/board.c
int board_init(void)
{
  // 最小限の初期化のみ
  enable_uart();
  init_ddr();
  return 0;
}

int board_late_init(void)
{
  // 遅延可能な初期化
  init_ethernet();
  init_usb();
  return 0;
}
```

---

## モバイルデバイス

### 省電力技術

| 技術 | 説明 | 効果 |
|------|------|------|
| **Modern Standby** | 即座のレジューム | < 1秒 |
| **Dynamic Platform Thermal Framework (DPTF)** | 動的な温度管理 | 性能/温度バランス |
| **ACPI S0ix** | Connected Standby | バックグラウンド動作 |
| **Panel Self Refresh (PSR)** | ディスプレイ省電力 | 30-40%省電力 |

### ACPI S0ix実装

```asl
// DSDT.asl
Device (SLPB) // Sleep Button
{
  Name(_HID, EISAID("PNP0C0E"))
  Method(_DSM, 4) {
    If (Arg0 == ToUUID("c4eb40a0-6cd2-11e2-bcfd-0800200c9a66")) {
      // Low Power S0 Idle Capable
      Return (1)
    }
    Return (0)
  }
}
```

---

## プラットフォーム比較

| 項目 | サーバ | 組込み | モバイル |
|------|--------|--------|----------|
| **起動時間** | 30秒-2分 | < 2秒 | 5-10秒 |
| **メモリ** | 16GB-4TB | 512MB-2GB | 4GB-64GB |
| **ストレージ** | SAS/NVMe | eMMC/SD | NVMe |
| **ネットワーク** | 10/25/100 GbE | 100Mbps-1GbE | WiFi/LTE |
| **電源管理** | 冗長PSU | 単一電源 | バッテリー |
| **リモート管理** | IPMI/Redfish | 限定的 | なし |

---

## まとめ

この章では、**プラットフォーム別の特性**として、サーバ、組込みシステム、モバイルデバイスという 3 つの代表的なプラットフォームの要件、制約、ファームウェア実装の違いを学びました。それぞれのプラットフォームは異なる目標を持ち、ファームウェア設計もそれに応じて最適化されます。

**サーバプラットフォームの要件**は、**RAS（Reliability, Availability, Serviceability）** が中心です。**Reliability**（信頼性）として、ECC メモリでメモリエラーを訂正し、DIMM Sparing でエラーが発生したメモリモジュールを自動的に切り離します。**Availability**（可用性）として、ホットプラグ（Hot-Plug）によりサーバを停止せずにハードウェアコンポーネント（PCIe カード、CPU、メモリ、電源ユニット）を交換でき、冗長電源（Redundant PSU）により単一障害点を排除します。**Serviceability**（保守性）として、IPMI（Intelligent Platform Management Interface）や Redfish API により、リモートから OS が起動していない状態でもハードウェアを監視・制御できます。サーバは大容量メモリ（16 GB から 4 TB）をサポートし、NUMA（Non-Uniform Memory Access）やメモリミラーリングを実装します。起動時間は 30 秒から 2 分と比較的長いですが、POST でのハードウェア診断とメモリトレーニングが含まれるため許容されます。

**IPMI（Intelligent Platform Management Interface）** は、サーバのリモート管理を実現する標準プロトコルです。BMC（Baseboard Management Controller）は、メインの CPU とは独立したマイクロコントローラであり、サーバの電源がオフでも動作します。ファームウェアは、IpmiSendCommand 関数で BMC と通信し、KCS（Keyboard Controller Style）インターフェースを使用してコマンドを送信しレスポンスを受信します。IPMI により、リモートから電源の ON/OFF、シリアルコンソールへのアクセス（SOL: Serial Over LAN）、センサー情報の取得（温度、電圧、ファン速度）、ブートデバイスの設定、ファームウェア更新が可能です。Redfish API は、IPMI の後継として DMTF が策定した RESTful API ベースの管理インターフェースであり、JSON 形式でデータをやり取りし、HTTP/HTTPS でアクセスします。

**組込みシステムの制約と要件**は、**リソースの最小化**と**高速起動**です。フラッシュサイズは通常 1-8 MB であり、UEFI ファームウェア（4-8 MB）を格納できません。したがって、coreboot（256 KB）や U-Boot（100-500 KB）といった軽量なファームウェアが使用されます。メモリは 512 MB から 2 GB と限られており、動的メモリ割り当てを最小化する必要があります。起動時間は 2 秒未満が求められ、並列初期化（複数のハードウェアを同時に初期化）、遅延初期化（必須でない初期化を後回しにする）、不要なドライバの削除（使用しないデバイスのドライバを削除）が不可欠です。消費電力も 5 W 以下が求められることが多く、S3/S4 サポートや動的周波数調整（DVFS: Dynamic Voltage and Frequency Scaling）が実装されます。U-Boot での実装例として、board_init 関数では UART と DDR といった最小限の初期化のみを行い、board_late_init 関数では Ethernet や USB といった遅延可能な初期化を実行します。

**モバイルデバイスの省電力技術**は、**Modern Standby** と **ACPI S0ix** が中心です。**Modern Standby**（Connected Standby）は、画面をオフにしてもバックグラウンドでメール受信やメッセージ通知を継続し、即座にレジューム（1 秒未満）できる省電力状態です。従来の S3（Suspend to RAM）では、ネットワーク接続が切断され、レジュームに数秒かかりましたが、Modern Standby では常時接続を維持しながら低消費電力を実現します。**ACPI S0ix** は、Modern Standby を実現するための低電力アイドル状態であり、OS は動作し続けますが、CPU をディープスリープ状態にし、不要なデバイスを停止します。**DPTF（Dynamic Platform Thermal Framework）** は、ACPI を拡張した温度管理フレームワークであり、温度センサー、冷却デバイス（ファン）、パフォーマンス制御（CPU 周波数）を統合的に管理します。センサーが高温を検出すると、DPTF はファン速度を上げ、CPU 周波数を下げ、ディスプレイ輝度を下げることで、温度を許容範囲内に保ちます。**PSR（Panel Self Refresh）** は、ディスプレイの省電力技術であり、画面内容が変化しない場合にディスプレイコントローラへのフレームバッファ転送を停止し、ディスプレイ自身が内部メモリから画面を更新します。これにより 30-40% の省電力が可能です。

**ACPI S0ix の実装**は、DSDT（Differentiated System Description Table）で宣言します。SLPB（Sleep Button）デバイスに _DSM（Device Specific Method）を実装し、Low Power S0 Idle Capable UUID（c4eb40a0-6cd2-11e2-bcfd-0800200c9a66）を認識すると、1 を返して S0ix 対応を示します。OS は、この情報に基づいて Modern Standby を有効化し、アイドル時に S0ix 状態に遷移します。ファームウェアは、S0ix 状態で CPU を C10（最も深いスリープ状態）に遷移させ、チップセットを低電力モードにし、不要な電源レールを停止します。

**プラットフォーム比較**として、**起動時間**はサーバが 30 秒から 2 分、組込みが 2 秒未満、モバイルが 5-10 秒です。**メモリ**はサーバが 16 GB から 4 TB、組込みが 512 MB から 2 GB、モバイルが 4 GB から 64 GB です。**ストレージ**はサーバが SAS/NVMe（高速・高信頼性）、組込みが eMMC/SD（低コスト）、モバイルが NVMe（高速）です。**ネットワーク**はサーバが 10/25/100 GbE（超高速）、組込みが 100 Mbps から 1 GbE、モバイルが WiFi/LTE（無線）です。**電源管理**はサーバが冗長 PSU（可用性重視）、組込みが単一電源（コスト重視）、モバイルがバッテリー（省電力重視）です。**リモート管理**はサーバが IPMI/Redfish（フル機能）、組込みが限定的（シリアルコンソールのみ）、モバイルがなし（ユーザーが直接操作）です。

**プラットフォーム選択の指針**として、まず**用途の特定**（サーバ、組込み、モバイル）を行い、次に**要件の優先順位**（RAS、起動時間、省電力、リモート管理）を決定し、さらに**制約の確認**（フラッシュサイズ、メモリサイズ、消費電力、コスト）を行い、最後に**ファームウェアの選択**（UEFI、coreboot、U-Boot）を決定します。サーバでは RAS とリモート管理が最優先であり、UEFI ファームウェアが標準です。組込みシステムでは起動時間とリソースの最小化が最優先であり、coreboot や U-Boot が適しています。モバイルデバイスでは省電力とユーザーエクスペリエンスが最優先であり、Modern Standby をサポートする UEFI ファームウェアが標準です。

以下の参考表は、プラットフォーム別の特性を要約したものです。

**参考表: プラットフォーム別の特性**

| 項目 | サーバ | 組込み | モバイル |
|------|--------|--------|----------|
| **起動時間** | 30秒-2分 | < 2秒 | 5-10秒 |
| **メモリ** | 16GB-4TB | 512MB-2GB | 4GB-64GB |
| **ストレージ** | SAS/NVMe | eMMC/SD | NVMe |
| **ネットワーク** | 10/25/100 GbE | 100Mbps-1GbE | WiFi/LTE |
| **電源管理** | 冗長PSU | 単一電源 | バッテリー |
| **リモート管理** | IPMI/Redfish | 限定的 | なし |

---

次章: [Part VI Chapter 7: ARM64 ブートアーキテクチャ](07-arm64-boot-architecture.md)
