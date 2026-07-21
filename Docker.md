# Container machine (apple/container) + VS Code Remote-SSH

`.devcontainer/devcontainer.json` の代替として、[apple/container](https://github.com/apple/container) の
`container machine` 上に Linux 開発環境を立て、VS Code の **Remote-SSH** で接続する構成です。

VS Code の Dev Containers 拡張は Docker 互換ランタイムを前提とするため apple/container からは
起動できません。本構成はその回避策として、Apple 公式サンプル
[`examples/container-machine-vscode`](https://github.com/apple/container/tree/main/examples/container-machine-vscode)
に倣って構築します。

## 前提

- macOS 26 以降 / Apple Silicon
- [apple/container](https://github.com/apple/container/releases) をインストール済み
- VS Code + `Remote - SSH` 拡張
- `container system start` 済み

## セットアップ手順（初回のみ）

以下は macOS ホスト側で実行します。

### 1. マシンイメージをビルド

```bash
cd /Users/syo_igarashi/github/igara
container build -t igara-machine:latest -f Dockerfile .
```

### 2. `.machine` ドメインを DNS に登録（初回のみ・全マシン共通）

```bash
sudo container system dns create machine
```

### 3. container machine を作成（`--home-mount rw` で macOS ホームをマウント）

```bash
container machine create \
  --set-default \
  --name igara \
  --home-mount rw \
  igara-machine:latest
```

> `--home-mount rw` はデフォルト値ですが、意図を明示するため指定しています。
> これにより macOS の `/Users/<host-user>` が VM 内の同じパスにマウントされます。

### 4. SSH 用パスワードを設定

`$(whoami)` は macOS のユーザ名（＝マシン内でも同名のユーザとして自動作成される）です。

```bash
container machine run -it sudo passwd $(whoami)
```

### 5. `~/.ssh/config` にエントリを追加

```bash
cat >> ~/.ssh/config <<'EOT'

Host igara.machine
  HostName igara.machine
  ForwardAgent yes
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
EOT
```

### 6. 疎通確認

```bash
ping -c 1 igara.machine
ssh igara.machine   # 一度ログインしておくと VS Code 側が安定
```
