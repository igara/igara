# AGENTS.md

AI コーディングエージェント（Claude Code / その他）がこのリポジトリで作業するためのガイドです。

## このリポジトリについて

`https://github.com/igara/igara` に表示される、五十嵐翔（Syo Igarashi）の **プロフィール（履歴書）リポジトリ** です。
GitHub のプロフィール表示用リポジトリ（ユーザ名と同名のリポジトリ）で、`README.md` がそのままトップページに表示されます。

- 内容は履歴書に加えて、仕事以外の活動も含めた経歴を **年月順** に記載していく方針です。
- 記載言語は **日本語** です。

## リポジトリ構成

| ファイル / ディレクトリ | 役割 |
| --- | --- |
| `README.md` | 本体。プロフィール（経歴）を記述する Markdown。**編集対象はここ。** |
| `README.html` | `README.md` から生成される HTML。**手で編集しない**（生成物）。 |
| `html.ts` | `README.md` → `README.html` 変換スクリプト（`marked` を使用）。 |
| `package.json` | npm スクリプトと依存関係。 |
| `.textlintrc` | 日本語校正（textlint）のルール設定。 |
| `.eslintrc` / `.prettierrc` | `*.ts`（主に `html.ts`）向けの Lint / フォーマット設定。 |
| `.github/workflows/main.yml` | push 時に `npm run lint` を実行する CI。 |
| `Dockerfile` / `Docker.md` | `apple/container` + VS Code Remote-SSH による開発環境構築用。プロフィール内容とは無関係。 |

## よく使うコマンド

```bash
npm install        # 依存関係のインストール
npm run lint       # README.md を textlint で校正（CI と同じチェック）
npm run html       # README.md から README.html を生成
npm run eslint     # *.ts を ESLint でチェック
```

## 作業ルール

- **経歴の追記・修正は `README.md` を編集する。** `README.html` は生成物なので直接編集しない。
- `README.md` の見出し構成を変更した場合は、冒頭の `## 目次` のアンカーリンクも合わせて更新する。
- 経歴は **年月順** を維持する（例: `### 2020/9~2024/2` のような年月見出しの下にぶら下げる）。
- 文章を追加・変更したら、コミット前に `npm run lint` を通す。CI（push 時）でも同じ校正が走るため、ここで落ちると失敗する。
- `README.md` を変更したら、必要に応じて `npm run html` で `README.html` を再生成して差分に含める。

## 文章スタイル（textlint 準拠）

`.textlintrc` で以下のプリセット / ルールが有効になっているため、これらに沿って書く:

- `preset-ja-technical-writing`（技術文書向けの日本語ルール）
  - 漢字の連続は最大 6 文字まで（`max-kanji-continuous-len`）。長い固有名詞は `.textlintrc` の `allow` に追加する。
- `preset-ja-spacing` の `ja-space-between-half-and-full-width`（半角と全角の間に半角スペースを入れる）。
- `spellcheck-tech-word`（技術用語の表記ゆれチェック）。

新しい固有名詞や技術用語で lint が落ちる場合は、`.textlintrc` の `allow` などに追記して調整する。
</content>
