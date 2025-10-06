# Part II まとめ

🎯 **Part II で学んだこと**
- EDK II の設計思想とアーキテクチャ全体像
- モジュール構成とビルドシステムの仕組み
- プロトコルとドライバモデルによる拡張性
- ハードウェア抽象化の実現方法
- 主要サブシステム（グラフィックス、ストレージ、USB）の構造
- ブートマネージャとブートローダの役割

---

## Part II の全体構成

Part II では、**EDK II (EFI Development Kit II)** という UEFI ファームウェア実装の事実上の標準について学びました。EDK II は、TianoCore プロジェクトによって開発されたオープンソースの UEFI ファームウェア実装であり、Intel、AMD、ARM など多くのプラットフォームで使用されています。EDK II は、単なるコードベースではなく、モジュール性、移植性、拡張性、標準準拠という明確な設計思想に基づいた包括的なファームウェアフレームワークです。

Part II の 10 章は、EDK II の全体像を体系的に理解するために構成されています。第1章から第4章では、EDK II の基盤となるアーキテクチャ、ビルドシステム、プロトコル機構、ライブラリシステムを学びました。これらの章は、EDK II の設計哲学と、その哲学を実現するための具体的な仕組みを理解するための土台です。第5章では、ハードウェア抽象化の仕組みを学び、EDK II がどのようにして異なるプラットフォーム間で共通のコードを再利用できるかを理解しました。第6章から第8章では、具体的なサブシステムとして、グラフィックス (GOP)、ストレージスタック、USB スタックを学びました。これらの章は、ハードウェア抽象化の原則が実際のサブシステムでどのように適用されるかを示しています。第9章では、ブートマネージャとブートローダの役割を学び、UEFI ファームウェアがどのようにして OS の起動を管理するかを理解しました。そして、この第10章では、Part II 全体を振り返り、学んだ知識を統合します。

各章は、独立して読めるように設計されていますが、同時に前の章で学んだ知識を前提としています。例えば、第3章のプロトコルとドライバモデルは、第2章のモジュールとビルドシステムの知識を前提とし、第6章の GOP は、第3章のプロトコル機構と第5章のハードウェア抽象化の知識を前提としています。この段階的な構成により、読者は基礎から応用へと着実に知識を積み上げることができます。

Part II を通じて、読者は以下の能力を習得しました。まず、**EDK II のアーキテクチャ全体を理解する能力**です。各コンポーネントの役割と相互作用を把握し、ファームウェアの全体像を見通すことができます。次に、**プロトコルとドライバを理解する能力**です。GUID、Interface、Handle の関係を理解し、Driver Binding Protocol の実装パターンを把握できます。さらに、**ハードウェア抽象化を実践する能力**です。CPU I/O、PCI I/O、PCD、HOB などの仕組みを使い、プラットフォーム固有の詳細を隠蔽する方法を理解できます。最後に、**主要サブシステムの動作原理を理解する能力**です。グラフィックス、ストレージ、USB の各スタックがどのように階層化され、どのように連携するかを把握できます。

**補足図: Part II の章構成**

```mermaid
graph TB
    subgraph "Part II: EDK II の理解"
        CH1[Chapter 1<br/>EDK II アーキテクチャ]
        CH2[Chapter 2<br/>モジュールとビルドシステム]
        CH3[Chapter 3<br/>プロトコルとドライバモデル]
        CH4[Chapter 4<br/>ライブラリアーキテクチャ]
        CH5[Chapter 5<br/>ハードウェア抽象化]
        CH6[Chapter 6<br/>グラフィックス (GOP)]
        CH7[Chapter 7<br/>ストレージスタック]
        CH8[Chapter 8<br/>USB スタック]
        CH9[Chapter 9<br/>ブートマネージャとローダ]
        CH10[Chapter 10<br/>まとめ]
    end

    CH1 --> CH2
    CH2 --> CH3
    CH3 --> CH4
    CH4 --> CH5
    CH5 --> CH6
    CH5 --> CH7
    CH5 --> CH8
    CH8 --> CH9
    CH9 --> CH10

    style CH1 fill:#e1f5ff
    style CH5 fill:#fff4e1
    style CH10 fill:#e1ffe1
```

---

## 各章の振り返り

### Chapter 1: EDK II アーキテクチャ

**学んだこと**:

- EDK II の 4 つの設計原則
  - モジュール性（再利用可能なコンポーネント）
  - 移植性（複数アーキテクチャ対応）
  - 拡張性（プロトコルベース）
  - 標準準拠（UEFI/PI 仕様）

- EDK II のディレクトリ構造
  - `MdePkg`: UEFI/PI 基本定義
  - `MdeModulePkg`: 汎用モジュール
  - `OvmfPkg`: QEMU 用プラットフォーム
  - プラットフォーム固有パッケージ

**重要なポイント**: EDK II は単なるコードベースではなく、**設計思想**です。モジュール性と抽象化により、異なるプラットフォームでコードを再利用できます。

---

### Chapter 2: モジュールとビルドシステム

**学んだこと**:

- 4 つのメタデータファイル
  - **INF**: モジュール定義
  - **DEC**: パッケージ定義
  - **DSC**: プラットフォーム記述
  - **FDF**: フラッシュレイアウト

- ビルドプロセス
  - `build` コマンド → AutoGen.c 生成 → コンパイル → リンク → FD/FV 生成

- Depex (Dependency Expression)
  - ドライバのロード順序を制御
  - プロトコル依存関係を宣言

**重要なポイント**: メタデータファイルは、**宣言的な設定**を可能にします。コードを変更せずに、ビルド設定だけでモジュールの動作をカスタマイズできます。

---

### Chapter 3: プロトコルとドライバモデル

**学んだこと**:

- プロトコルの3要素
  - **GUID**: プロトコルの一意識別子
  - **Interface**: 関数ポインタの構造体
  - **Handle**: プロトコルが登録されるオブジェクト

- ドライバの種類
  - **Service Driver**: プロトコルのみ提供
  - **Bus Driver**: デバイスを列挙、子ハンドルを作成
  - **Device Driver**: 特定デバイスを制御
  - **Hybrid Driver**: Bus + Device の両方

- Driver Binding Protocol
  - `Supported()`: デバイス対応可否の判定
  - `Start()`: ドライバの初期化
  - `Stop()`: ドライバの停止

**重要なポイント**: プロトコルとドライバモデルにより、**実装の差し替え**が可能です。同じプロトコルに対して、異なる実装を提供できます。

---

### Chapter 4: ライブラリアーキテクチャ

**学んだこと**:

- Library Class と Library Instance の分離
  - **Library Class**: インターフェース定義
  - **Library Instance**: 実装

- 主要なライブラリ
  - **BaseLib**: CPU 操作、文字列処理
  - **DebugLib**: デバッグ出力
  - **MemoryAllocationLib**: メモリ確保
  - **IoLib**: I/O アクセス
  - **UefiBootServicesTableLib**: Boot Services アクセス

- ライブラリマッピングの優先順位
  - モジュール固有 → MODULE_TYPE+ARCH → MODULE_TYPE → ARCH → グローバル

**重要なポイント**: ライブラリアーキテクチャにより、**リンク時の実装選択**が可能です。プラットフォームごとに異なるライブラリインスタンスを使用できます。

---

### Chapter 5: ハードウェア抽象化の仕組み

**学んだこと**:

- I/O 抽象化階層
  - **CPU I/O Protocol**: IN/OUT、MMIO の抽象化
  - **PCI I/O Protocol**: PCI デバイスアクセスの抽象化

- プラットフォーム固有情報の管理
  - **PCD (Platform Configuration Database)**: 設定値の一元管理
  - **HOB (Hand-Off Block)**: ブートフェーズ間のデータ受け渡し

- Device Path Protocol
  - ハードウェアデバイスの階層的識別
  - ブートオプション、ドライバ接続に使用

**重要なポイント**: 抽象化により、**プラットフォームの移植性**が向上します。ハードウェアの詳細を隠蔽し、上位層は共通のインターフェースでアクセスできます。

---

### Chapter 6: グラフィックスサブシステム (GOP)

**学んだこと**:

- GOP (Graphics Output Protocol) の役割
  - レガシー VGA/VESA の問題を解決
  - フレームバッファへの直接アクセス

- GOP の 3 つの主要メソッド
  - **QueryMode**: 利用可能な解像度・色深度を取得
  - **SetMode**: モード切り替え
  - **Blt**: 矩形転送・塗りつぶし

- Blt 操作の種類
  - **VideoFill**: 単色塗りつぶし
  - **VideoToBltBuffer**: 画面からメモリへ
  - **BufferToVideo**: メモリから画面へ
  - **VideoToVideo**: 画面内コピー

**重要なポイント**: GOP により、**標準化されたグラフィックスアクセス**が可能です。ベンダ固有の GPU でも、共通のプロトコルで描画できます。

---

### Chapter 7: ストレージスタックの構造

**学んだこと**:

- ストレージスタックの 4 層
  - **Block I/O**: ブロック単位アクセス
  - **Disk I/O**: バイト単位アクセス
  - **Partition Driver**: GPT/MBR 解析
  - **Simple File System**: ファイル操作

- Block I/O vs Disk I/O
  - Block I/O: LBA 指定、ブロックサイズの倍数
  - Disk I/O: バイトオフセット、任意サイズ（RMW）

- デバイス別スタック
  - **NVMe**: NVMe Pass Thru Protocol
  - **AHCI**: ATA Pass Thru Protocol
  - **USB Mass Storage**: USB I/O Protocol

**重要なポイント**: 階層化により、**異なるストレージデバイスを統一的に扱える**ようになります。上位層は下位層の実装を意識する必要がありません。

---

### Chapter 8: USB スタックの構造

**学んだこと**:

- USB アーキテクチャ
  - Host Controller → Hub → Device の階層
  - 1 ホストに最大 127 デバイス

- Host Controller の種類
  - **xHCI**: USB 3.x の統合コントローラ
  - **EHCI/UHCI/OHCI**: レガシーコントローラ

- USB 転送タイプ
  - **Control**: デバイス制御（保証あり）
  - **Bulk**: 大容量転送（保証あり、速度優先）
  - **Interrupt**: 定期ポーリング（低遅延）
  - **Isochronous**: リアルタイム（保証なし）

- USB デバイスドライバ
  - **HID**: キーボード、マウス
  - **Mass Storage**: ストレージデバイス（BOT + SCSI）

**重要なポイント**: USB Bus Driver が**デバイス列挙を自動化**します。デバイスが接続されると、自動的に Descriptor を取得し、適切なドライバに接続します。

---

### Chapter 9: ブートマネージャとブートローダの役割

**学んだこと**:

- Boot Manager vs Boot Loader
  - **Boot Manager**: UEFI Firmware 内蔵、ブートオプション管理
  - **Boot Loader**: ESP 上の EFI アプリ、カーネルをロード

- Boot#### UEFI 変数
  - **BootOrder**: ブート優先順位
  - **Boot0000, Boot0001, ...**: 各オプションの詳細（EFI_LOAD_OPTION）
  - **BootNext**: 次回起動時のみ使用

- Device Path でブートターゲットを指定
  - パーティション + ファイルパスの組み合わせ
  - 例: `HD(1,GPT,...)/\EFI\ubuntu\grubx64.efi`

- Fallback Boot Path
  - `\EFI\BOOT\BOOTX64.EFI` がデフォルト
  - リムーバブルメディアで使用

**重要なポイント**: Boot Manager は**柔軟なマルチブート環境**を実現します。複数の OS を簡単に切り替えられます。

---

## EDK II の全体像

これまで学んだ要素がどのように組み合わさるかを、全体図で確認しましょう。

```mermaid
graph TB
    subgraph "アプリケーション層"
        APP[UEFI アプリ]
        SHELL[UEFI Shell]
    end

    subgraph "プロトコル層"
        GOP[GOP]
        BIO[Block I/O]
        USB_IO[USB I/O]
        FILE[File Protocol]
    end

    subgraph "ドライバ層"
        GOP_DRV[GOP ドライバ]
        NVME_DRV[NVMe ドライバ]
        USB_DRV[USB HID ドライバ]
        PART[Partition ドライバ]
    end

    subgraph "ハードウェア抽象層"
        PCI_IO[PCI I/O]
        CPU_IO[CPU I/O]
        USB_HC[USB HC Protocol]
    end

    subgraph "ライブラリ層"
        BASELIB[BaseLib]
        IOLIB[IoLib]
        MEMLIB[MemoryAllocationLib]
    end

    subgraph "プラットフォーム層"
        PCD[PCD]
        HOB[HOB]
    end

    APP --> GOP
    APP --> FILE
    SHELL --> FILE
    FILE --> BIO
    GOP --> GOP_DRV
    BIO --> NVME_DRV
    BIO --> PART
    USB_IO --> USB_DRV
    GOP_DRV --> PCI_IO
    NVME_DRV --> PCI_IO
    USB_DRV --> USB_HC
    USB_HC --> PCI_IO
    PCI_IO --> CPU_IO
    GOP_DRV --> IOLIB
    NVME_DRV --> BASELIB
    IOLIB --> PCD
    BASELIB --> PCD

    style GOP fill:#e1f5ff
    style BIO fill:#e1f5ff
    style PCI_IO fill:#fff4e1
    style BASELIB fill:#e1ffe1
    style PCD fill:#f0e1ff
```

### 設計原則の再確認

EDK II の設計は、以下の原則に基づいています：

| 原則 | 実現方法 | 利点 |
|------|---------|------|
| **モジュール性** | INF/DEC/DSC によるモジュール定義 | 再利用性向上 |
| **抽象化** | プロトコル、ライブラリクラスの分離 | 実装の差し替え可能 |
| **階層化** | 4 層アーキテクチャ（App → Protocol → Driver → HAL） | 保守性向上 |
| **拡張性** | Driver Binding Protocol | 新規ハードウェアの追加が容易 |
| **移植性** | PCD、HOB、アーキテクチャ別ライブラリ | プラットフォーム間の移植が容易 |

---

## Part II で得たスキル

Part II を通じて、以下のスキルを習得しました：

### 1. アーキテクチャ理解

- UEFI ファームウェアの全体構造を理解
- 各コンポーネントの役割と相互作用を把握

### 2. プロトコル設計の理解

- GUID によるインターフェース識別
- Handle Database による動的な関連付け
- OpenProtocol/CloseProtocol の参照カウント

### 3. ドライバ開発の基礎

- Driver Binding Protocol の実装パターン
- Bus Driver による子ハンドル作成
- デバイス列挙とドライバ接続の流れ

### 4. ハードウェア抽象化の実践

- CPU I/O、PCI I/O による低レベルアクセス
- デバイスパスによるハードウェア識別
- PCD による設定値の管理

### 5. サブシステムの知識

- グラフィックス: GOP による標準化
- ストレージ: Block I/O から File System までの階層
- USB: ホストコントローラから転送タイプまでの理解

### 6. ブート管理の仕組み

- Boot#### 変数の構造
- Boot Manager の動作フロー
- Boot Loader の役割

---

## Part III への橋渡し

Part II では、EDK II の**アーキテクチャと実装方法**を学びました。しかし、実際のプラットフォームでは、さらに深い初期化が必要です。

### Part II でカバーしなかったこと

- **プラットフォーム初期化の詳細**
  - CPU の初期化手順
  - メモリコントローラの設定
  - チップセットの初期化

- **SEC/PEI Phase の詳細**
  - Cache as RAM (CAR)
  - メモリ初期化前の動作
  - PEIM (PEI Module) の実装

- **ACPI テーブルの生成**
  - ハードウェア情報の OS への伝達
  - ACPI テーブルの構造

- **電源管理**
  - S-State、C-State、P-State
  - スリープ/レジューム

これらは、**Part III: プラットフォーム初期化の仕組み**で詳しく学びます。

---

## Part III の概要

**Part III: プラットフォーム初期化の仕組み**では、以下のトピックを扱います：

```mermaid
graph LR
    subgraph "Part III"
        SEC[SEC Phase 詳細]
        PEI[PEI Phase 詳細]
        MRC[メモリ初期化]
        CPU_INIT[CPU 初期化]
        CHIPSET[チップセット初期化]
        ACPI_GEN[ACPI テーブル生成]
        SMM[SMM セットアップ]
        PM[電源管理]
    end

    SEC --> PEI
    PEI --> MRC
    PEI --> CPU_INIT
    PEI --> CHIPSET
    CHIPSET --> ACPI_GEN
    CHIPSET --> SMM
    CHIPSET --> PM

    style SEC fill:#e1f5ff
    style PEI fill:#fff4e1
    style MRC fill:#e1ffe1
    style ACPI_GEN fill:#f0e1ff
```

Part III では、**ハードウェアを直接制御する低レベルの初期化**を理解します。これにより、UEFI ファームウェアがどのようにしてハードウェアを起動可能な状態にするかを学びます。

---

## まとめ

Part II では、**EDK II のアーキテクチャと実装パターン**を包括的に学びました。EDK II は、UEFI ファームウェア実装の事実上の標準であり、モジュール性、移植性、拡張性、標準準拠という明確な設計思想に基づいています。この設計思想は、単なる理想ではなく、具体的な実装メカニズムによって実現されています。Part II を通じて、読者はこれらの実装メカニズムを詳しく学び、実際に UEFI アプリケーションやドライバを開発するための基盤を習得しました。

**メタデータファイル**による宣言的設定は、EDK II の重要な特徴です。INF ファイルはモジュールの構成要素と依存関係を定義し、DEC ファイルはパッケージ全体の GUID とプロトコル定義を提供し、DSC ファイルはプラットフォーム全体のビルド設定を記述し、FDF ファイルはファームウェアイメージのレイアウトを定義します。これらのメタデータファイルにより、開発者はコードを変更せずに、設定だけでモジュールの動作をカスタマイズできます。この宣言的なアプローチは、プラットフォーム間の移植性を大幅に向上させます。

**プロトコルとドライバモデル**は、EDK II の拡張性の中核です。プロトコルは、GUID によって一意に識別されるインターフェースであり、Handle に関連付けられます。Driver Binding Protocol により、ドライバは自動的に適切なデバイスに接続されます。Service Driver、Bus Driver、Device Driver、Hybrid Driver という異なる種類のドライバは、それぞれ特定の役割を持ち、協調して動作します。このプラグイン機構により、新しいハードウェアのサポートを既存のファームウェアに容易に追加できます。

**ライブラリアーキテクチャ**は、コードの再利用性を最大化します。Library Class と Library Instance の分離により、同じインターフェースに対して異なる実装を提供できます。例えば、DebugLib は、開発時には詳細なログを出力する実装を使い、製品版では出力を無効化する実装を使うことができます。ライブラリマッピングの優先順位により、プラットフォームごと、モジュールごとに適切なライブラリインスタンスを選択できます。この柔軟性により、EDK II は多様な要求に対応できます。

**ハードウェア抽象化**は、プラットフォームの移植性を実現します。CPU I/O Protocol と PCI I/O Protocol は、低レベルのハードウェアアクセスを抽象化し、上位層のドライバはこれらのプロトコルを通じてハードウェアにアクセスします。PCD (Platform Configuration Database) は、設定値を一元管理し、ビルド時または実行時に値を取得できます。HOB (Hand-Off Block) は、ブートフェーズ間でデータを受け渡し、初期化情報を後続のフェーズに伝達します。Device Path Protocol は、ハードウェアデバイスを階層的に識別し、ブートオプションやドライバ接続に使用されます。これらの抽象化メカニズムにより、EDK II は異なるプラットフォーム間で共通のコードを再利用できます。

**主要サブシステム**として、グラフィックス (GOP)、ストレージスタック、USB スタックを学びました。GOP は、レガシー VGA/VESA の問題を解決し、標準化されたグラフィックスアクセスを提供します。QueryMode、SetMode、Blt という三つのメソッドにより、解像度の設定と描画を実行できます。ストレージスタックは、Block I/O、Disk I/O、Partition Driver、Simple File System という四層の階層構造を持ち、異なるストレージデバイスを統一的に扱えます。USB スタックは、Host Controller → Hub → Device という階層構造を持ち、USB Bus Driver が自動的にデバイスを列挙し、適切なドライバに接続します。これらのサブシステムは、ハードウェア抽象化の原則を実際に適用した具体例です。

**ブート管理**の仕組みは、UEFI の重要な機能です。Boot Manager は UEFI ファームウェアに内蔵されており、Boot#### UEFI 変数を読み込み、ブートオプションを管理します。BootOrder 変数は優先順位を定義し、個々の Boot#### 変数は EFI_LOAD_OPTION 構造体を含み、デバイスパスとオプションデータを保持します。Boot Loader は ESP 上の UEFI アプリケーションであり、Boot Manager によってロードされ、カーネルをメモリにロードして起動します。Fallback Boot Path により、リムーバブルメディアは特別な設定なしでブート可能です。この柔軟な仕組みにより、マルチブート環境を簡単に構築できます。

Part II で得た**アーキテクチャの理解**は、Part III での**実装の理解**を支える基盤となります。Part III では、これらの知識を基に、プラットフォーム初期化の実装を学びます。SEC/PEI Phase での低レベル初期化、メモリコントローラやチップセットの設定、ACPI テーブルの生成など、UEFI ファームウェアの中核部分に踏み込みます。Part II で学んだ抽象化レイヤの下で、実際にハードウェアを初期化する低レベルのコードがどのように動作するかを理解することで、UEFI ファームウェアの全体像が完成します。

---

**次は [Part III: プラットフォーム初期化の仕組み](../part3/01-sec-phase-detail.md) へ進みましょう！**
