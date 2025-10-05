# ネットワークブートの仕組み

🎯 **この章で学ぶこと**
- PXE (Preboot Execution Environment) の基礎
- TFTP/HTTP ブートプロトコル
- UEFI HTTP Bootの実装

📚 **前提知識**
- [Part II: EDK II 実装](../part2/01-hello-world.md)

---

## PXE (Preboot Execution Environment)

ネットワーク経由でOSをブートする標準プロトコルです。

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

| プロトコル | 用途 | 利点 |
|-----------|------|------|
| PXE/TFTP | レガシー | シンプル、広くサポート |
| HTTP Boot | UEFI | 高速、大きいファイル対応 |
| iSCSI Boot | SAN | ディスクレスワークステーション |

---

次章: [Part VI Chapter 6: プラットフォーム別の特性](06-platform-characteristics.md)
