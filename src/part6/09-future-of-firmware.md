# ファームウェアの将来展望

🎯 **この章で学ぶこと**
- ファームウェア技術の最新動向
- セキュリティ強化の方向性
- オープンソース化の進展
- 新しいアーキテクチャ (RISC-V) の影響

📚 **前提知識**
- [Part VI Chapter 1: ファームウェアの多様性](01-firmware-diversity.md)

---

## 主要なトレンド

### 1. オープンソース化の加速

**現状**:
- Google Chromebook: coreboot採用
- System76, Purism: coreboot PC
- Facebook, Microsoft: Open Compute Project

**将来**:
- より多くのOEMがオープンソースファームウェアを採用
- Verified Boot の標準化
- コミュニティ主導の開発モデル

---

## セキュリティ強化

### Confidential Computing

```
CPU
├── Secure Enclave (Intel SGX, AMD SEV)
├── Firmware Attestation
└── Runtime Integrity Verification
```

**主要技術**:
- Intel TDX (Trust Domain Extensions)
- AMD SEV-SNP (Secure Encrypted Virtualization)
- ARM CCA (Confidential Compute Architecture)

### SPDM (Security Protocol and Data Model)

デバイス認証の標準プロトコル:

```c
// デバイス認証
SpdmGetVersion(device);
SpdmGetCapabilities(device);
SpdmNegotiateAlgorithms(device);

// 証明書検証
SpdmGetDigests(device);
SpdmGetCertificate(device);
SpdmChallenge(device);  // 認証
```

---

## RISC-Vの台頭

### オープンソースISA

**利点**:
- ライセンスフリー
- カスタマイズ容易
- エコシステム成長中

**ファームウェアサポート**:
- OpenSBI (RISC-V Supervisor Binary Interface)
- U-Boot RISC-V対応
- EDK II RISC-V移植

### 実装例

```c
// OpenSBI: RISC-V SBI実装
void sbi_hart_start(unsigned long hartid,
                    unsigned long start_addr,
                    unsigned long opaque)
{
  // Hart (Hardware Thread) 起動
  atomic_set(&target_hart->state, HART_STARTED);
  target_hart->scratch->next_addr = start_addr;
  target_hart->scratch->next_arg1 = opaque;
}
```

---

## 標準化の進展

### UEFI 2.10+ の新機能

| 機能 | 説明 |
|------|------|
| **CXL Support** | Compute Express Link デバイス |
| **Confidential Computing** | TEE統合 |
| **Carbon Aware Compute** | 環境配慮型電源管理 |
| **Dynamic Tables** | 動的ACPI生成 |

### ACPI 6.5+ の新機能

- **PPTT** (Processor Properties Topology Table): CPUトポロジ詳細
- **HMAT** (Heterogeneous Memory Attribute Table): 異種メモリ
- **MPAM** (Memory Partitioning and Monitoring): メモリ分離

---

## エッジコンピューティング向け最適化

### 要件

| 項目 | 目標値 |
|------|--------|
| 起動時間 | < 500ms |
| フラッシュサイズ | < 2MB |
| セキュアブート | 必須 |
| OTA更新 | 必須 |

### Slim Bootloader の進化

```python
# SBL設定 (Python)
class BoardConfig:
    STAGE1_SIZE = '0x00010000'  # 64KB
    STAGE2_SIZE = '0x00040000'  # 256KB
    ENABLE_FWU = True           # Firmware Update
    ENABLE_VERIFIED_BOOT = True # Verified Boot
```

---

## クラウドネイティブファームウェア

### Project Mu (Microsoft)

EDK IIフォーク、クラウド最適化:

```
特徴:
- CI/CD統合
- モジュラーアーキテクチャ
- Surface, Xbox採用
```

### 仮想化対応

**UEFI on Cloud**:
- OVMF (Open Virtual Machine Firmware)
- AWS Nitro System
- Google Cloud Shielded VMs

---

## 将来予測 (5-10年)

### シナリオ 1: オープンソース主流化

```
2030年:
- デスクトップPC 30%がcoreboot
- サーバ 50%がオープンソースファームウェア
- 組込み 70%がU-Boot/SBL
```

### シナリオ 2: セキュリティ強制化

```
規制:
- NIST SP 800-193 (Platform Firmware Resiliency) 必須
- EU Cyber Resilience Act 対応
- 政府調達でオープンソース要件
```

### シナリオ 3: アーキテクチャ多様化

```
市場シェア予測 (2030):
- x86: 50% (デスクトップ/サーバ)
- ARM: 40% (モバイル/組込み/一部サーバ)
- RISC-V: 10% (組込み/エッジ)
```

---

## まとめ

### 確実な変化

| 分野 | トレンド |
|------|----------|
| **セキュリティ** | Verified Boot標準化 |
| **オープンソース** | 採用拡大 (特にサーバ/組込み) |
| **標準化** | UEFI 2.x, ACPI 6.x継続進化 |
| **RISC-V** | 組込み分野で成長 |
| **エッジ** | 超軽量ファームウェア需要増 |

### 不確実な要素

- Windows on ARM の成否
- RISC-Vのデスクトップ進出
- 量子コンピュータのファームウェア

---

次章: [Part VI Chapter 10: Part VI まとめ](10-part6-summary.md)
