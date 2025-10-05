# レガシー BIOS アーキテクチャ

🎯 **この章で学ぶこと**
- レガシーBIOSの基本アーキテクチャ
- INT 10h, INT 13h等のBIOS割り込みサービス
- MBRブートとパーティションテーブル
- UEFIとの互換性層(CSM)

📚 **前提知識**
- [Part I: x86_64 ブート基礎](../part1/01-reset-vector.md)

---

## レガシーBIOSとは

1980年代から続く、x86 PCの伝統的なファームウェアシステムです。

### 基本構造

```
ROM BIOS (128KB - 2MB)
├── POST (Power-On Self Test)
├── BIOS INT サービス (INT 10h, 13h, 15h...)
├── Setup Utility
└── Boot Loader (MBR読み込み)
```

---

## BIOS割り込みサービス

### 主要な割り込み

| INT | 機能 | 用途 |
|-----|------|------|
| **INT 10h** | ビデオサービス | 画面表示、テキストモード |
| **INT 13h** | ディスクサービス | ディスク読み書き |
| **INT 15h** | システムサービス | メモリサイズ取得、APM |
| **INT 16h** | キーボードサービス | キー入力 |
| **INT 1Ah** | 時刻サービス | RTC読み取り |

### INT 13h の例

```asm
; ディスクから512バイト読み込み
mov ah, 02h         ; Read sectors
mov al, 01h         ; 1 sector
mov ch, 00h         ; Cylinder 0
mov cl, 01h         ; Sector 1
mov dh, 00h         ; Head 0
mov dl, 80h         ; Drive 0 (HDD)
mov bx, 7C00h       ; Buffer address
int 13h             ; BIOS call
jc  error           ; Carry flag = error
```

---

## MBRブート

### MBR (Master Boot Record) 構造

```
Offset  Size  Description
0x000   446   ブートコード
0x1BE   16    パーティションエントリ 1
0x1CE   16    パーティションエントリ 2
0x1DE   16    パーティションエントリ 3
0x1EE   16    パーティションエントリ 4
0x1FE   2     ブート署名 (0x55AA)
```

### ブートフロー

```
BIOS → MBR読み込み (0x7C00) → MBRコード実行 → OSローダ
```

---

## CSM (Compatibility Support Module)

UEFIファームウェアでレガシーBIOSをエミュレートします。

### CSMの役割

```
UEFI Firmware
  └── CSM Module
      ├── INT Handler エミュレーション
      ├── MBR Boot サポート
      └── Option ROM 実行
```

---

## レガシーBIOSの限界

| 項目 | レガシーBIOS | UEFI |
|------|-------------|------|
| ディスクサイズ | 2TB上限 (MBR) | 9.4ZB (GPT) |
| パーティション数 | 4個 | 128個 |
| ブートモード | 16ビットリアルモード | 32/64ビット |
| Secure Boot | なし | あり |
| ネットワークブート | 限定的 | 標準 |

---

次章: [Part VI Chapter 5: ネットワークブートの仕組み](05-network-boot.md)
