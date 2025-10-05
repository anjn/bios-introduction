# プラットフォーム別の特性：サーバ/組込み/モバイル

🎯 **この章で学ぶこと**
- サーバプラットフォームの要件 (RAS, IPMI)
- 組込みシステムの制約 (起動時間、フラッシュサイズ)
- モバイルデバイスの特性 (省電力、Modern Standby)

📚 **前提知識**
- [Part VI Chapter 1: ファームウェアの多様性](01-firmware-diversity.md)

---

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

次章: [Part VI Chapter 7: ARM64 ブートアーキテクチャ](07-arm64-boot-architecture.md)
