# coreboot と EDK II の比較

🎯 **この章で学ぶこと**
- corebootとEDK IIの技術的な詳細比較
- アーキテクチャの違いとトレードオフ
- 実際の使用場面での選択基準

📚 **前提知識**
- [Part VI Chapter 1: ファームウェアの多様性](01-firmware-diversity.md)
- [Part VI Chapter 2: corebootの設計思想](02-coreboot-philosophy.md)

---

## アーキテクチャの比較

### ブートフロー

**coreboot**:
```
bootblock → romstage → ramstage → payload
(CAR)       (DRAM初期化) (デバイス列挙)
```

**EDK II**:
```
SEC → PEI → DXE → BDS → TSL → RT
     (CAR) (DRAM)  (Driver) (Boot) (Runtime)
```

### サイズ比較

| 項目 | coreboot | EDK II |
|------|----------|--------|
| bootblock/SEC | 16-32 KB | 16 KB |
| romstage/PEI | 64-128 KB | 512 KB - 1 MB |
| ramstage/DXE | 128-256 KB | 2-4 MB |
| payload/BDS | 可変 (128KB-2MB) | 500 KB |
| **合計** | **256KB-2.5MB** | **4-8MB** |

---

## 機能比較

| 機能 | coreboot | EDK II |
|------|----------|--------|
| Secure Boot | Payload経由 | ネイティブサポート |
| ACPI生成 | 簡易版 | 完全版 |
| PCI列挙 | Device Tree | Driver Binding |
| GUI Setup | なし (Payload) | 標準装備 |
| ネットワークブート | Payload | 標準装備 |
| S3 Resume | サポート | 完全サポート |
| Capsule Update | 限定的 | 完全サポート |

---

## コード例の比較

### メモリ初期化

**coreboot**:
```c
void mainboard_romstage_entry(void)
{
  FSP_M_CONFIG upd;
  upd.DdrFreqLimit = 2400;
  fsp_memory_init(&upd, &hob);
}
```

**EDK II**:
```c
EFI_STATUS MemoryInit(VOID)
{
  InitSPD();
  InitChannels();
  PerformTraining();
  SetupMemoryMap();
  return EFI_SUCCESS;
}
```

---

## 選択基準

**corebootを選ぶ場合**:
- 起動速度最優先
- Linux専用
- オープンソース必須

**EDK IIを選ぶ場合**:
- Windows必須
- 最新ハードウェア
- 完全な機能セット

---

次章: [Part VI Chapter 4: レガシーBIOSアーキテクチャ](04-legacy-bios-architecture.md)
