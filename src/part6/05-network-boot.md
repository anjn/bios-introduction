# ネットワークブートの仕組み

🎯 **この章で学ぶこと**
- PXE (Preboot Execution Environment) の基礎
- TFTP/HTTP ブートプロトコル
- UEFI HTTP Bootの実装

📚 **前提知識**
- [Part II: EDK II 実装](../part2/01-hello-world.md)

---

## はじめに

**ネットワークブート**は、ローカルディスクではなく**ネットワーク経由で OS やファームウェアをロードする仕組み**であり、ディスクレスワークステーション、大規模展開、サーバ管理、組込みシステム、クラウドインフラなど、さまざまな用途で活用されています。ネットワークブートの最も一般的な実装は **PXE（Preboot Execution Environment）** であり、Intel が策定した標準プロトコルです。PXE は DHCP でネットワーク設定を取得し、TFTP でブートローダをダウンロードし、実行します。UEFI 環境では、より高速で柔軟な **HTTP Boot** もサポートされており、大きなイメージファイルの転送や HTTPS による暗号化通信が可能です。

**ネットワークブートの利点**は多岐にわたります。まず、**ディスクレス運用**により、クライアント側にストレージが不要になり、ハードウェアコストを削減できます。次に、**集中管理**により、OS イメージをサーバ側で一元管理し、複数のクライアントに同じイメージを配信できるため、ソフトウェア更新やセキュリティパッチの適用が容易になります。さらに、**迅速な展開**により、新しいマシンをネットワークに接続するだけで自動的に OS がインストールされるため、大規模な PC 展開やデータセンターのプロビジョニングが効率化されます。また、**障害復旧**として、ローカルディスクが故障してもネットワークブートで一時的に OS を起動し、復旧作業を実行できます。最後に、**セキュリティ**として、OS イメージがサーバ側で管理されるため、ローカルディスクへの不正な改ざんを防げます。

**PXE（Preboot Execution Environment）** は、1999 年に Intel が策定したネットワークブート標準であり、DHCP、TFTP、そして Option ROM（NIC 上の BIOS 拡張）を組み合わせて実現されます。PXE ブートフローは、まず NIC の Option ROM が実行され、DHCP Request をブロードキャストして IP アドレスと TFTP サーバ情報を取得し、次に TFTP で指定されたブートローダ（pxelinux.0、grubnetx64.efi など）をダウンロードし、最後にダウンロードしたブートローダを実行して OS カーネルをロードします。PXE は広くサポートされており、ほとんどの NIC が PXE ブート機能を搭載していますが、TFTP の転送速度が遅い（通常 1-5 MB/s）という欠点があります。

**UEFI HTTP Boot** は、PXE の後継として UEFI 仕様 2.5 で導入されたネットワークブート方式であり、HTTP/HTTPS プロトコルを使用してブートローダや OS イメージをダウンロードします。HTTP Boot は、TFTP よりも高速（10-100 MB/s）であり、大きなイメージファイル（数 GB）の転送に適しています。また、HTTPS による暗号化通信をサポートしており、ブートイメージの改ざんを防げます。さらに、IPv6 をサポートしており、現代のネットワークインフラに対応します。EDK II の NetworkPkg/HttpBootDxe が UEFI HTTP Boot の参照実装であり、DHCP で IP アドレスとブート URI を取得し、HTTP GET でブートファイルをダウンロードし、EFI Application として実行します。

この章では、PXE ブートの仕組みと DHCP/TFTP プロトコルの詳細、UEFI HTTP Boot の実装と利点、サーバ側の設定例（dnsmasq、Apache、Nginx）、そしてネットワークブートのトラブルシューティングを学びます。ネットワークブートは、現代のインフラ管理において不可欠な技術であり、クラウドコンピューティング、コンテナオーケストレーション、エッジコンピューティングといった新しいパラダイムにおいても重要な役割を果たしています。

## PXE (Preboot Execution Environment)

**PXE**（Preboot Execution Environment）は、ネットワーク経由で OS をブートする標準プロトコルです。

### PXEブートフロー

```
1. DHCP Request → IP取得
2. DHCP Offer → TFTP Server情報取得
3. TFTP Read → ブートローダ取得
4. Execute → OSカーネル起動
```

---

## プロトコル詳細

### DHCP Option

| Option | 名前 | 用途 |
|--------|------|------|
| 66 | TFTP Server Name | TFTPサーバのホスト名 |
| 67 | Bootfile Name | ブートファイルパス |
| 43 | Vendor Specific | PXE固有情報 |

### TFTP (Trivial File Transfer Protocol)

```
Client → Server: RRQ (Read Request)
Server → Client: DATA (Block 1)
Client → Server: ACK
Server → Client: DATA (Block 2)
...
```

---

## UEFI HTTP Boot

UEFIではHTTPによるブートもサポートされています。

### HTTP Bootフロー

```
1. DHCP → IP + HTTP Server URL取得
2. HTTP GET /bootx64.efi
3. Execute EFI Application
```

### 実装例

```c
// EDK II: NetworkPkg/HttpBootDxe
EFI_STATUS HttpBootStart(VOID)
{
  // DHCP でIP取得
  HttpBootDhcp();

  // ブートURIを取得
  GetBootFileUrl(&Uri);

  // HTTP GETでダウンロード
  HttpBootLoadFile(Uri, &Buffer);

  // EFI Application実行
  StartImage(Buffer);
}
```

---

## サーバ側設定例

### dnsmasq設定

```conf
# /etc/dnsmasq.conf
dhcp-range=192.168.1.100,192.168.1.200,12h
dhcp-boot=pxelinux.0

# UEFI Boot
dhcp-match=set:efi-x86_64,option:client-arch,7
dhcp-boot=tag:efi-x86_64,bootx64.efi

# TFTP設定
enable-tftp
tftp-root=/srv/tftp
```

---

## まとめ

この章では、**ネットワークブートの仕組み**として、PXE（Preboot Execution Environment）と UEFI HTTP Boot の詳細を学びました。ネットワークブートは、ディスクレス運用、集中管理、迅速な展開、障害復旧、セキュリティといった多くの利点を提供し、現代のインフラ管理において不可欠な技術です。

**PXE（Preboot Execution Environment）** は、1999 年に Intel が策定したネットワークブート標準であり、DHCP と TFTP を組み合わせて実現されます。PXE ブートフローは、まず **DHCP Request** で IP アドレス、サブネットマスク、ゲートウェイ、DNS サーバを取得し、次に **DHCP Offer** で TFTP サーバアドレス（Option 66: TFTP Server Name）とブートファイル名（Option 67: Bootfile Name）を取得します。さらに **TFTP Read** でブートローダ（pxelinux.0、grubnetx64.efi など）をダウンロードし、最後に **Execute** でブートローダを実行して OS カーネルを起動します。PXE は広くサポートされており、ほとんどの NIC（Network Interface Card）が PXE ブート機能を搭載していますが、TFTP の転送速度が遅い（通常 1-5 MB/s）という欠点があります。

**DHCP Option** は、PXE ブートに必要な情報を伝達します。Option 66（TFTP Server Name）は TFTP サーバのホスト名または IP アドレスを指定し、Option 67（Bootfile Name）はブートファイルのパス（例: pxelinux.0、bootx64.efi）を指定します。Option 43（Vendor Specific Information）は PXE 固有の情報（PXE Discovery Control、Boot Server List など）を含みます。これらの Option を適切に設定することで、クライアントは自動的に正しいブートファイルをダウンロードできます。

**TFTP（Trivial File Transfer Protocol）** は、UDP ポート 69 を使用するシンプルなファイル転送プロトコルです。クライアントは **RRQ（Read Request）** でファイルを要求し、サーバは **DATA パケット**（Block 1、Block 2、...）でファイル内容を送信します。クライアントは各 DATA パケットに対して **ACK** を返します。DATA パケットのサイズは通常 512 バイトであり、512 バイト未満の DATA パケットを受信するとファイル転送の終了を意味します。TFTP は非常にシンプルですが、エラー回復機能が限られており、転送速度も遅いため、大きなファイルの転送には適していません。

**UEFI HTTP Boot** は、PXE の後継として UEFI 仕様 2.5 で導入されたネットワークブート方式であり、HTTP/HTTPS プロトコルを使用します。HTTP Boot フローは、まず **DHCP** で IP アドレスとブート URI（HTTP Server URL）を取得し、次に **HTTP GET /bootx64.efi** でブートファイルをダウンロードし、最後に **Execute EFI Application** で EFI アプリケーションを実行します。HTTP Boot は、TFTP よりも高速（10-100 MB/s）であり、大きなイメージファイル（数 GB の Linux カーネルや initramfs）の転送に適しています。また、HTTPS による暗号化通信をサポートしており、ブートイメージの改ざんを防げます。さらに、IPv6 をサポートしており、現代のネットワークインフラに対応します。

**HTTP Boot の実装例**として、EDK II の NetworkPkg/HttpBootDxe が参照実装です。HttpBootStart 関数は、まず HttpBootDhcp で DHCP を実行して IP アドレスとブート URI を取得し、次に GetBootFileUrl でブート URI を解析し、さらに HttpBootLoadFile で HTTP GET を実行してファイルをダウンロードし、最後に StartImage でダウンロードした EFI Application を実行します。この実装は、EFI_HTTP_PROTOCOL と EFI_DNS_PROTOCOL を使用して HTTP 通信を実現します。

**サーバ側設定例**として、dnsmasq が DHCP と TFTP の統合サーバとして広く使われます。/etc/dnsmasq.conf で dhcp-range（DHCP で配布する IP アドレス範囲）、dhcp-boot（ブートファイル名）、enable-tftp（TFTP サーバ有効化）、tftp-root（TFTP ルートディレクトリ）を設定します。UEFI Boot をサポートする場合は、dhcp-match で client-arch（クライアントアーキテクチャ）を判定し、dhcp-boot で適切なブートファイル（bootx64.efi for x86_64 UEFI）を指定します。HTTP Boot をサポートする場合は、Apache や Nginx を HTTP サーバとして設定し、DocumentRoot にブートファイルを配置します。

**ネットワークブートの用途**として、まず**ディスクレスワークステーション**では、ローカルストレージを持たないクライアントがネットワーク経由で OS を起動します。次に**大規模展開**では、数百台の PC に OS を一斉にインストールする際に、ネットワークブートで自動インストールを実行します（Red Hat Kickstart、Debian Preseed、Windows WDS など）。さらに**ライブOS**では、Live CD/USB の代わりにネットワークブートで一時的な OS 環境を提供します。また **iSCSI Boot** では、ネットワーク上の SAN（Storage Area Network）からディスクイメージをマウントして OS を起動します。最後に**コンテナ/クラウド**では、Kubernetes の PixieCore や OpenStack の Ironic がネットワークブートを活用してベアメタルサーバをプロビジョニングします。

**トラブルシューティング**として、よくある問題は **DHCP Offer が届かない**（DHCP サーバが応答しない、VLAN 設定の問題、IP Helper/DHCP Relay の設定ミス）、**TFTP タイムアウト**（ファイアウォールで UDP 69 がブロックされている、TFTP ルートディレクトリのパーミッション不足）、**ブートファイルが見つからない**（ファイル名の大文字小文字の違い、パスの設定ミス）、**HTTP Boot 失敗**（HTTP サーバが起動していない、HTTPS 証明書の検証エラー、DNS 解決の失敗）などがあります。Wireshark や tcpdump でパケットキャプチャを行い、DHCP、TFTP、HTTP のトランザクションを詳しく調査することで、問題を特定できます。

**ネットワークブートの将来**として、UEFI HTTP Boot が標準となり、PXE/TFTP は徐々に減少していくと予想されます。また、Secure Boot と組み合わせることで、ネットワークブートでもブートイメージの署名検証が可能になり、セキュリティが向上します。さらに、5G やエッジコンピューティングの発展により、ネットワークブートの用途が拡大し、リモートワーク、産業用 IoT、自動車などの新しい領域でも活用されるでしょう。

以下の参考表は、主要なネットワークブートプロトコルの比較です。

**参考表: ネットワークブートプロトコルの比較**

| プロトコル | 用途 | 利点 | 欠点 |
|-----------|------|------|------|
| PXE/TFTP | レガシー、広く普及 | シンプル、広くサポート | 転送速度が遅い |
| HTTP Boot | UEFI、現代的 | 高速、大きいファイル対応、HTTPS暗号化 | UEFI必須 |
| iSCSI Boot | SAN、エンタープライズ | ディスクレスワークステーション、集中管理 | 複雑な設定 |

---

次章: [Part VI Chapter 6: プラットフォーム別の特性](06-platform-characteristics.md)
