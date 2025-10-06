# Translation Guide / 翻訳ガイド

This document explains how to translate the BIOS Introduction book into English.

本書を英語に翻訳する方法を説明します。

## Overview / 概要

- **Source Language**: Japanese (日本語)
- **Target Language**: English
- **Method**: mdbook-i18n-helpers (Gettext-based)
- **Directory Structure**:
  ```
  bios-introduction/
  ├── src/           # Japanese (source)
  ├── po/            # Translation files
  │   ├── messages.pot   # Template
  │   └── en.po          # English translations
  └── translations/
      └── en/        # Generated English version
  ```

## Setup / セットアップ

### Install Tools / ツールのインストール

```bash
# Install mdbook-i18n-helpers
cargo install mdbook-i18n-helpers

# Install gettext tools (for editing .po files)
# Ubuntu/Debian:
sudo apt install gettext

# macOS:
brew install gettext
```

## Translation Workflow / 翻訳ワークフロー

### 1. Extract Translatable Strings / 翻訳可能な文字列を抽出

```bash
# Extract all translatable strings from Japanese source
MDBOOK_OUTPUT='{"xgettext": {"pot-file": "po/messages.pot"}}' \
  mdbook build -d po
```

This creates `po/messages.pot` containing all Japanese text that needs translation.

### 2. Initialize English Translation / 英語翻訳ファイルを初期化

First time only:

```bash
# Create en.po from template
msginit -i po/messages.pot -l en -o po/en.po
```

To update existing translation:

```bash
# Merge new strings into existing en.po
msgmerge --update po/en.po po/messages.pot
```

### 3. Translate / 翻訳作業

#### Option A: Manual Translation / 手動翻訳

Use a PO editor:
- **Poedit**: https://poedit.net/ (GUI, recommended)
- **Emacs**: po-mode
- **Vim**: po.vim plugin
- **VS Code**: Gettext extension

Open `po/en.po` and translate:
```po
#: src/part0/01-goals-and-roadmap.md:5
msgid "この章で学ぶこと"
msgstr "What You'll Learn"
```

#### Option B: AI-Assisted Translation / AI支援翻訳

Use Claude or GPT-4 to translate sections:

```bash
# Example: Translate Part 0
cat src/part0/*.md | claude "Translate this technical documentation
from Japanese to English. Preserve markdown formatting and technical
terms. Output only the translated text."
```

Then manually update `po/en.po` with the translations.

### 4. Build Translated Book / 翻訳版をビルド

```bash
# Build both Japanese and English versions
MDBOOK_BOOK__LANGUAGE=en mdbook build -d book/en

# Or use the build script
./scripts/build-all-languages.sh
```

### 5. Preview / プレビュー

```bash
# Serve locally
mdbook serve

# Access:
# Japanese: http://localhost:3000/
# English:  http://localhost:3000/en/
```

## Translation Guidelines / 翻訳ガイドライン

### Technical Terms / 技術用語

**Keep in English** (英語のまま):
- BIOS, UEFI, ACPI, PCI, USB, CPU, RAM, ROM
- EDK II, TianoCore, coreboot
- Firmware, bootloader, kernel

**Translate** (翻訳する):
- ブートプロセス → Boot process
- ファームウェア → Firmware (keep both)
- 初期化 → Initialization
- デバッグ → Debugging

### Code Comments / コードコメント

Translate inline comments:

```c
// ブートデバイスを初期化 → // Initialize boot device
```

### Column Sections / コラムセクション

Translate the icon labels:
- 🕰️ 歴史的エピソード → Historical Episode
- 💼 実務での事例 → Real-World Case Study
- 🔬 技術的深堀り → Technical Deep Dive
- 🔒 セキュリティ事例 → Security Case Study
- 🛠️ 開発ツールTips → Development Tool Tips
- 👥 コミュニティの話 → Community Story
- 📜 規格の裏話 → Standards Behind the Scenes
- 🏢 ベンダー固有の話 → Vendor-Specific Topic

### Markdown Formatting / マークダウンフォーマット

Preserve:
- Headers (`#`, `##`, `###`)
- Code blocks (` ```c `, ` ```bash `)
- Links (`[text](url)`)
- Tables (`| col1 | col2 |`)
- Mermaid diagrams

## Quality Checklist / 品質チェックリスト

Before committing translations:

- [ ] All `msgid` have `msgstr` (no empty translations)
- [ ] Technical terms are consistent
- [ ] Code blocks are not translated
- [ ] Links work correctly
- [ ] Build succeeds: `mdbook build`
- [ ] Preview looks correct

## Directory Structure After Translation / 翻訳後のディレクトリ構造

```
bios-introduction/
├── book/
│   ├── index.html          # Japanese
│   ├── part0/              # Japanese chapters
│   └── en/
│       ├── index.html      # English
│       └── part0/          # English chapters
├── po/
│   ├── messages.pot        # Template (auto-generated)
│   └── en.po               # English translations (manual)
└── src/                    # Japanese source (original)
```

## Automation / 自動化

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup mdBook
        uses: peaceiris/actions-mdbook@v1
        with:
          mdbook-version: 'latest'

      - name: Install mdbook-i18n-helpers
        run: cargo install mdbook-i18n-helpers

      - name: Build Japanese
        run: mdbook build

      - name: Build English
        run: MDBOOK_BOOK__LANGUAGE=en mdbook build -d book/en

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./book
```

## Continuous Translation / 継続的翻訳

When Japanese source is updated:

1. Extract new strings:
   ```bash
   MDBOOK_OUTPUT='{"xgettext": {"pot-file": "po/messages.pot"}}' \
     mdbook build -d po
   ```

2. Update English PO file:
   ```bash
   msgmerge --update po/en.po po/messages.pot
   ```

3. Translate new/updated strings in `po/en.po`

4. Build and test:
   ```bash
   mdbook build
   ```

5. Commit and push:
   ```bash
   git add po/en.po
   git commit -m "Update English translation"
   git push
   ```

## Resources / リソース

- mdbook-i18n-helpers: https://github.com/google/mdbook-i18n-helpers
- Gettext manual: https://www.gnu.org/software/gettext/manual/
- Example (Comprehensive Rust): https://google.github.io/comprehensive-rust/

## Contact / 問い合わせ

For translation questions, open an issue on GitHub.

翻訳に関する質問は、GitHubでIssueを開いてください。
