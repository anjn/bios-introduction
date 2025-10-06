# coreboot と EDK II の比較

🎯 **この章で学ぶこと**
- corebootとEDK IIの技術的な詳細比較
- アーキテクチャの違いとトレードオフ
- 実際の使用場面での選択基準

📚 **前提知識**
- [Part VI Chapter 1: ファームウェアの多様性](01-firmware-diversity.md)
- [Part VI Chapter 2: corebootの設計思想](02-coreboot-philosophy.md)

---

## はじめに

**coreboot と EDK II の比較**は、単なる技術的な仕様の違いではなく、**ファームウェア設計における根本的な哲学の違い**を理解することに他なりません。前章で学んだ coreboot の設計思想（ミニマリズム、ペイロード分離、オープンソース第一主義）と、本書の Part II で詳しく学んだ EDK II のアーキテクチャ（包括的機能提供、プロトコルベースの拡張性、UEFI 仕様準拠）は、それぞれ異なる目標を持ち、異なるトレードオフを行っています。

**設計目標の違い**が、すべての技術的差異の根源です。coreboot の目標は、**ハードウェアを起動可能な状態にするための最小限のコード**を提供し、それ以外のすべての機能をペイロードに委譲することです。これにより、コードサイズを最小化し（64-256 KB）、攻撃面を減らし、起動時間を短縮し（1 秒未満）、セキュリティ監査を容易にします。一方、EDK II の目標は、**UEFI 仕様に準拠したフル機能のファームウェア環境**を提供し、OS ローダ、ドライバ、アプリケーションが豊富なプロトコルとサービスを活用できるようにすることです。これにより、Windows を含む幅広い OS のサポート、Secure Boot や Capsule Update といった標準機能の実装、ベンダーによる拡張とカスタマイズが可能になります。

**ブートフローの違い**は、設計思想を反映しています。coreboot は **4 ステージ**（bootblock → romstage → ramstage → payload）という直線的でシンプルな構造を持ち、各ステージは明確に定義された役割（bootblock: CPU/キャッシュ初期化、romstage: DRAM 初期化、ramstage: デバイス列挙、payload: OS ブート）を持ちます。ステージ間の依存関係は最小限であり、デバッグが容易です。一方、EDK II は **6 フェーズ**（SEC → PEI → DXE → BDS → TSL → RT）という階層的で複雑な構造を持ち、各フェーズで PEIM（PEI Module）や DXE Driver が動的にロードされ、相互に依存し、プロトコルを介して通信します。この柔軟性は、豊富な機能とベンダーカスタマイズを可能にしますが、コードサイズと起動時間の増加というコストを伴います。

**コードサイズとパフォーマンスのトレードオフ**も明確です。coreboot の典型的なサイズは 256 KB から 2.5 MB（ペイロード含む）であり、起動時間は 1 秒未満です。これは、SPI Flash のサイズが限られている組込みシステムや、高速起動が求められる Chromebook に最適です。一方、EDK II の典型的なサイズは 4-8 MB であり、起動時間は 2-3 秒です。これは、豊富な機能（グラフィックス、ネットワーク、USB、ストレージスタック）を提供する代償です。しかし、デスクトップ PC やサーバでは、SPI Flash のサイズは通常 16 MB 以上であり、起動時間も 2-3 秒であれば許容範囲内です。したがって、ターゲットプラットフォームの制約と要件に応じて、適切なファームウェアを選択することが重要です。

**機能サポートの違い**は、用途の違いを反映します。EDK II は UEFI 仕様に準拠しているため、Secure Boot、ACPI テーブル生成、PCI Driver Binding、GUI Setup、ネットワークブート（PXE）、S3 Resume、Capsule Update といった標準機能をネイティブにサポートします。これらの機能は、Windows や Linux を含む幅広い OS が期待する標準インターフェースであり、互換性を重視するシステムでは不可欠です。一方、coreboot は、これらの機能の多くをペイロードに委譲します。例えば、Secure Boot は UEFI Payload（TianoCore）を使用すれば可能であり、ACPI テーブルは簡易版を生成しますが、完全な ACPI 実装はペイロードや OS に任せます。この分離により、coreboot 本体は最小限に保たれますが、Windows のような UEFI 準拠を期待する OS を動かすには、追加のペイロードが必要になります。

この章では、coreboot と EDK II のアーキテクチャ、コードサイズ、ブートフロー、機能サポート、実装例を体系的に比較し、それぞれの長所と短所を明確にします。また、実際の使用場面での選択基準を提示し、特定の要件（起動速度、コードサイズ、OS サポート、セキュリティ、カスタマイズ性）に対してどちらのファームウェアが適しているかを判断できるようにします。最後に、両者のハイブリッドアプローチ（coreboot + UEFI Payload）についても触れ、それぞれの利点を組み合わせる可能性を探ります。

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

## まとめ

この章では、**coreboot と EDK II の技術的な比較**を通じて、それぞれのファームウェアの長所、短所、適用場面を明確にしました。両者の違いは、単なる実装の詳細ではなく、**ファームウェアの役割と責務についての根本的な哲学の違い**を反映しています。

**アーキテクチャとブートフローの比較**として、coreboot は **4 ステージ**（bootblock → romstage → ramstage → payload）という直線的でシンプルな構造を持ち、各ステージは明確に定義された役割を持ちます。bootblock は CPU とキャッシュを初期化し、romstage は DRAM を初期化し、ramstage はデバイスを列挙し、payload が OS をブートします。ステージ間の依存関係は最小限であり、デバッグが容易です。一方、EDK II は **6 フェーズ**（SEC → PEI → DXE → BDS → TSL → RT）という階層的で複雑な構造を持ちます。SEC は CPU を初期化し、PEI は DRAM を初期化してメモリを使用可能にし、DXE は豊富なドライバをロードしてプロトコルを公開し、BDS はブートデバイスを選択し、TSL は OS ローダを起動し、RT は OS 実行中もランタイムサービスを提供し続けます。この柔軟性は、豊富な機能とベンダーカスタマイズを可能にしますが、コードサイズと複雑性の増加を伴います。

**コードサイズの比較**では、coreboot が圧倒的に小さいことが明確です。coreboot の bootblock は 16-32 KB、romstage は 64-128 KB、ramstage は 128-256 KB であり、本体だけで 256 KB 程度です。ペイロード（SeaBIOS 128 KB、GRUB2 256 KB、UEFI Payload 1.5 MB）を含めても、合計サイズは 256 KB から 2.5 MB の範囲です。一方、EDK II の SEC は 16 KB と小さいですが、PEI は 512 KB から 1 MB、DXE は 2-4 MB、BDS は 500 KB であり、合計サイズは 4-8 MB に達します。これは、EDK II が豊富なドライバとサービス（グラフィックス、ネットワーク、USB、ストレージ、ファイルシステム、シェル、Setup UI）を標準装備しているためです。SPI Flash のサイズが限られているシステム（4-8 MB）では coreboot が有利であり、十分な容量があるシステム（16 MB 以上）では EDK II の豊富な機能が活用できます。

**機能サポートの比較**では、EDK II が包括的なサポートを提供するのに対し、coreboot は最小限の実装にとどまります。**Secure Boot** については、EDK II はネイティブにサポートし、UEFI 変数（PK、KEK、db、dbx）を使用して署名検証を実行します。coreboot は本体ではサポートしませんが、UEFI Payload（TianoCore）を使用すれば Secure Boot が可能です。**ACPI テーブル生成**については、EDK II は FADT、MADT、HPET、MCFG、SSDT など完全な ACPI テーブルを生成しますが、coreboot は簡易版を生成し、詳細はペイロードや OS に任せます。**PCI デバイス列挙**については、EDK II は Driver Binding Protocol を使用した動的なドライバロードを実装し、複雑ですが柔軟性が高いです。coreboot は Device Tree（devicetree.cb）を使用した宣言的な記述でシンプルですが、動的なドライバロードはサポートしません。**GUI Setup** については、EDK II は HII（Human Interface Infrastructure）を使用した GUI Setup を標準装備しますが、coreboot は Setup UI を持たず、ペイロードに委譲します。**ネットワークブート**については、EDK II は PXE（Preboot eXecution Environment）を標準サポートしますが、coreboot はペイロード（iPXE、GRUB2）に委譲します。**S3 Resume** については、両者ともサポートしますが、EDK II は Boot Script Table を使用した完全な実装を提供し、coreboot はより簡易な実装です。**Capsule Update** については、EDK II は UEFI Capsule Update を完全サポートしますが、coreboot は限定的なサポートにとどまります。

**コード例の比較**では、実装の違いが明確になります。**メモリ初期化**において、coreboot は Intel FSP（Firmware Support Package）を使用し、最小限の設定（DdrFreqLimit など）を行って fsp_memory_init を呼び出すだけです。コードはわずか数行で、実際のメモリ初期化は FSP に委譲されます。一方、EDK II は MemoryInit 関数で、InitSPD（SPD データ読み取り）、InitChannels（メモリチャネル初期化）、PerformTraining（メモリトレーニング）、SetupMemoryMap（メモリマップ設定）といった詳細な処理を自前で実装します。コードは数百行に及びます。この違いは、coreboot が外部コンポーネント（FSP、AGESA）を積極的に活用して本体を最小化するのに対し、EDK II は多くの機能を内部実装する傾向があることを示しています。

**選択基準**として、**coreboot を選ぶべき場合**は、まず**起動速度最優先**（1 秒未満の起動が必要）です。Chromebook、組込みシステム、POS（Point of Sale）端末など、高速起動が求められる用途に最適です。次に**コードサイズ制約**（SPI Flash が 4-8 MB など小容量）です。組込みシステムや IoT デバイスでは、ファームウェアサイズを最小化することでコストを削減できます。さらに**Linux 専用**（Windows サポート不要）です。Linux カーネルは UEFI を必須としないため、coreboot + SeaBIOS または GRUB2 で十分です。最後に**オープンソース必須**（セキュリティ監査、カスタマイズ）です。セキュリティを重視するシステムでは、すべてのコードが公開されている coreboot が適しています。一方、**EDK II を選ぶべき場合**は、まず**Windows 必須**（Windows 10/11 は UEFI Secure Boot 必須）です。Windows をサポートする必要があるシステムでは、EDK II が標準です。次に**最新ハードウェア対応**（ベンダーが UEFI ドライバを提供）です。最新の CPU、チップセット、GPU、NIC などは、ベンダーが UEFI ドライバを提供するため、EDK II で簡単に統合できます。さらに**完全な機能セット**（グラフィックス、ネットワーク、USB、ストレージ、Setup UI）です。エンドユーザー向けの PC では、豊富な機能と GUI Setup が期待されます。最後に**ベンダーサポート重視**（商用サポート、保証）です。エンタープライズ環境では、ベンダーからの技術サポートと保証が重要です。

**ハイブリッドアプローチ**（coreboot + UEFI Payload）は、両者の利点を組み合わせる可能性を提供します。coreboot 本体は最小限のハードウェア初期化のみを行い（高速、小サイズ、監査容易）、UEFI Payload（TianoCore）が UEFI 互換環境を提供します（Secure Boot、Windows サポート、豊富なドライバ）。この構成により、coreboot の高速起動とセキュリティ、EDK II の互換性と機能性を同時に享受できます。Google Chromebook の一部モデルでは、Developer Mode で UEFI Payload を使用して Windows をインストールできるようになっており、このハイブリッドアプローチの実用性が証明されています。

**技術的トレードオフの本質**は、**汎用性対専用性**の選択です。EDK II は汎用性を重視し、さまざまな OS、ハードウェア、用途に対応できる包括的なソリューションを提供します。これは、エコシステムの互換性と長期的な保守性を重視するアプローチです。一方、coreboot は専用性を重視し、特定の用途（Linux 専用、高速起動、組込みシステム）に最適化された最小限のソリューションを提供します。これは、パフォーマンス、セキュリティ、透明性を重視するアプローチです。どちらが優れているかではなく、**プロジェクトの要件と制約に応じて適切な選択を行う**ことが重要です。

以下の参考表は、coreboot と EDK II の主要な違いを要約したものです。

**参考表: coreboot と EDK II の比較要約**

| 項目 | coreboot | EDK II |
|------|----------|--------|
| **設計哲学** | ミニマリズム | 包括的機能提供 |
| **コードサイズ** | 256KB-2.5MB | 4-8MB |
| **起動時間** | < 1秒 | 2-3秒 |
| **ブートフロー** | 4ステージ | 6フェーズ |
| **Secure Boot** | Payload経由 | ネイティブ |
| **Windows対応** | UEFI Payload必要 | 完全対応 |
| **オープンソース** | GPL v2 | BSD |
| **主な用途** | Chromebook、組込み | PC、サーバ |

---

次章: [Part VI Chapter 4: レガシーBIOSアーキテクチャ](04-legacy-bios-architecture.md)
