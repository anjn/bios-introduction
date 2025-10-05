# 最小の UEFI アプリを作る

🎯 **この章で学ぶこと**
- HelloConsole.efi のビルド方法
- QEMU での UEFI アプリ実行
- シリアル出力でのデバッグ

📚 **前提知識**
- C言語の基礎
- Part 0 の環境構築完了

---

## UEFI アプリケーションとは

UEFI アプリケーションは `.efi` 拡張子を持つ PE32+ 形式の実行ファイルです。UEFI ファームウェアが起動した後、ブートローダが OS を起動する前に実行されます。

### 用途例
- カスタムブートローダ
- 診断ツール
- ファームウェア更新ツール
- UEFI シェル

## Hello World を書く

最小の UEFI アプリケーションを作成しましょう。

### ディレクトリ構成

```
edk2/
  └─ HelloPkg/
      ├─ HelloPkg.dec
      ├─ HelloPkg.dsc
      └─ HelloConsole/
          ├─ HelloConsole.inf
          └─ HelloConsole.c
```

### HelloConsole.c

```c
#include <Uefi.h>
#include <Library/UefiLib.h>
#include <Library/UefiApplicationEntryPoint.h>

/**
  UEFI アプリケーションのエントリポイント

  @param[in] ImageHandle    このアプリケーションのイメージハンドル
  @param[in] SystemTable    UEFI システムテーブルへのポインタ

  @retval EFI_SUCCESS       正常終了
**/
EFI_STATUS
EFIAPI
UefiMain (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  // コンソールに出力
  Print(L"Hello UEFI World!\n");
  Print(L"ImageHandle: %p\n", ImageHandle);
  Print(L"SystemTable: %p\n", SystemTable);

  // シリアルポートにも出力（デバッグ用）
  DEBUG((DEBUG_INFO, "Hello from DEBUG output!\n"));

  return EFI_SUCCESS;
}
```

### HelloConsole.inf

```ini
[Defines]
  INF_VERSION                    = 0x00010005
  BASE_NAME                      = HelloConsole
  FILE_GUID                      = 12345678-1234-1234-1234-123456789abc
  MODULE_TYPE                    = UEFI_APPLICATION
  VERSION_STRING                 = 1.0
  ENTRY_POINT                    = UefiMain

[Sources]
  HelloConsole.c

[Packages]
  MdePkg/MdePkg.dec

[LibraryClasses]
  UefiApplicationEntryPoint
  UefiLib
  DebugLib

[Protocols]

[Guids]
```

### HelloPkg.dec

```ini
[Defines]
  DEC_SPECIFICATION              = 0x00010005
  PACKAGE_NAME                   = HelloPkg
  PACKAGE_GUID                   = abcdef12-1234-5678-abcd-123456789def
  PACKAGE_VERSION                = 1.0
```

### HelloPkg.dsc

```ini
[Defines]
  PLATFORM_NAME                  = HelloPkg
  PLATFORM_GUID                  = fedcba98-4321-8765-dcba-fedcba987654
  PLATFORM_VERSION               = 1.0
  DSC_SPECIFICATION              = 0x00010005
  OUTPUT_DIRECTORY               = Build/HelloPkg
  SUPPORTED_ARCHITECTURES        = X64
  BUILD_TARGETS                  = DEBUG|RELEASE
  SKUID_IDENTIFIER               = DEFAULT

[LibraryClasses]
  UefiApplicationEntryPoint|MdePkg/Library/UefiApplicationEntryPoint/UefiApplicationEntryPoint.inf
  UefiLib|MdePkg/Library/UefiLib/UefiLib.inf
  DebugLib|MdePkg/Library/BaseDebugLibSerialPort/BaseDebugLibSerialPort.inf
  BaseLib|MdePkg/Library/BaseLib/BaseLib.inf
  BaseMemoryLib|MdePkg/Library/BaseMemoryLib/BaseMemoryLib.inf
  PrintLib|MdePkg/Library/BasePrintLib/BasePrintLib.inf
  PcdLib|MdePkg/Library/BasePcdLibNull/BasePcdLibNull.inf
  MemoryAllocationLib|MdePkg/Library/UefiMemoryAllocationLib/UefiMemoryAllocationLib.inf
  DevicePathLib|MdePkg/Library/UefiDevicePathLib/UefiDevicePathLib.inf
  UefiBootServicesTableLib|MdePkg/Library/UefiBootServicesTableLib/UefiBootServicesTableLib.inf
  UefiRuntimeServicesTableLib|MdePkg/Library/UefiRuntimeServicesTableLib/UefiRuntimeServicesTableLib.inf
  SerialPortLib|MdePkg/Library/BaseSerialPortLibNull/BaseSerialPortLibNull.inf

[Components]
  HelloPkg/HelloConsole/HelloConsole.inf
```

## ビルド

### 1. EDK II 環境のセットアップ

```bash
cd ~/edk2
source edksetup.sh
```

### 2. ビルド実行

```bash
build -a X64 -t GCC5 -p HelloPkg/HelloPkg.dsc -b DEBUG
```

成功すると、以下にバイナリが生成されます：
```
Build/HelloPkg/DEBUG_GCC5/X64/HelloConsole.efi
```

## QEMU で実行

### ESP イメージの作成

```bash
# FAT イメージ作成
dd if=/dev/zero of=esp.img bs=1M count=10
mkfs.vfat esp.img

# マウントして .efi をコピー
mkdir -p /tmp/esp
sudo mount -o loop esp.img /tmp/esp
sudo mkdir -p /tmp/esp/EFI/BOOT
sudo cp Build/HelloPkg/DEBUG_GCC5/X64/HelloConsole.efi /tmp/esp/EFI/BOOT/BOOTX64.EFI
sudo umount /tmp/esp
```

### QEMU 起動

```bash
qemu-system-x86_64 \
  -bios /usr/share/ovmf/OVMF.fd \
  -drive file=esp.img,format=raw \
  -serial stdio \
  -nographic
```

## 出力の確認

QEMU が起動すると、以下のような出力が表示されるはずです：

```
Hello UEFI World!
ImageHandle: 0x6C18018
SystemTable: 0x7F7F000
```

シリアル出力には DEBUG メッセージも表示されます：
```
Hello from DEBUG output!
```

## トラブルシューティング

### Q: ビルドエラーが出る
A: `edksetup.sh` を実行したか確認してください。

### Q: QEMU が起動しない
A: OVMF.fd のパスを確認してください（`/usr/share/OVMF/OVMF_CODE.fd` の場合もあります）。

### Q: 何も表示されない
A: `-serial stdio` オプションを追加してシリアル出力を確認してください。

## 💻 演習

1. 出力メッセージをカスタマイズしてみましょう
2. `Print()` で現在時刻を表示してみましょう（ヒント: `gRT->GetTime()`）
3. キー入力を待つコードを追加しましょう（ヒント: `gST->ConIn->ReadKeyStroke()`）

---

次章では、.inf/.dec/.dsc ファイルの詳細を学びます。

📚 **参考資料**
- [EDK II Module Writer's Guide](https://tianocore-docs.github.io/edk2-ModuleWriteGuide/)
