# slash-switcher

日本語入力のままでも、スラッシュコマンドを打てるようにする Hammerspoon モジュールです。

## 解決する困りごと

macOS の日本語入力で `/` を押すと、`・` (中黒) が入ります。
そのため Claude Code や Codex でスラッシュコマンドを使うたびに、入力の切り替えが必要でした。

1. 英数キーを押して、英字入力に切り替える。
2. `/review` などのコマンドを打つ。
3. かなキーを押して日本語入力に戻し、続きの指示を日本語で書く。

切り替えを忘れると `・review` と入ってしまい、消して打ち直すことになります。
日本語で指示を書く人ほど、この往復が一日に何十回も起きます。

## 入れた後の打ち方

日本語入力のまま `/` から打ち始めるだけです。
英数キーとかなキーは押しません。

```text
これまで:  [英数]  /review  [かな]  このPRの変更点を見て
これから:          /review  [スペース]  このPRの変更点を見て
```

1. `/` を押すと、英字入力に切り替わってから `/` が入ります。
2. そのまま英字でコマンド名を打ちます。
3. スペース・Tab・Enter のどれかを押すと、日本語入力に戻ります。

`/clear` のように続きを書かないコマンドは、Enter で実行した時点で日本語入力に戻ります。

## 細かい動き

- 動くのは、設定で指定したアプリの中だけです。ほかのアプリでは `/` は今までどおりです。
- 最初から英字入力のときは、何もしません。
- 日本語入力に戻すのは、このモジュールが英字に切り替えたときだけです。
- マウスでクリックしたときも、日本語入力に戻ります。
- `Shift+/` で打つ `?` や、Command などと一緒に押した `/` には反応しません。

## English

On macOS with the Japanese input method, pressing `/` types `・` instead of a slash,
so every slash command in Claude Code or Codex needs a manual switch to English and back.
This [Hammerspoon](https://www.hammerspoon.org/) module switches to English when you press `/`,
types the slash, and switches back to Japanese on Space, Tab, Return, or a mouse click.

## 必要なもの

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)。アクセシビリティの許可が必要です
- 日本語入力は macOS 標準の「日本語 - ローマ字入力」を想定しています

## ファイル構成

| ファイル | 役割 |
|---|---|
| `init.lua` | Hammerspoon の設定入口。そのまま `~/.hammerspoon/init.lua` として使える |
| `slash-switcher.lua` | 本体。`/` の横取りと入力ソースの切り替えを行う |

## インストール

### Hammerspoon の設定がまだ無い場合

リポジトリをそのまま `~/.hammerspoon` として置きます。

```sh
git clone https://github.com/DeePeriver/slash-switcher.git ~/.hammerspoon
```

Hammerspoon を起動するか、メニューから「Reload Config」を選びます。

### すでに `~/.hammerspoon/init.lua` がある場合

本体だけをリンクし、既存の `init.lua` に読み込みの行を足します。

```sh
git clone https://github.com/DeePeriver/slash-switcher.git
ln -s "$PWD/slash-switcher/slash-switcher.lua" ~/.hammerspoon/slash-switcher.lua
```

足す行は、このリポジトリの `init.lua` と同じです。

```lua
require("hs.ipc")
SlashSwitcher = require("slash-switcher")
```

## 設定

`slash-switcher.lua` 冒頭の値を書き換えます。

| 項目 | 内容 |
|---|---|
| `M.targetApps` | `/` を横取りするアプリのバンドルID。初期値は Orca (AIコーディング用のエディタ)、Ghostty (ターミナル)、Claude デスクトップ、ターミナル.app |
| `M.revertOn` | 日本語に戻す操作。初期値はスペース・Tab・Enter・クリックで有効、Esc で無効 |
| `M.japaneseSource` | 戻り先の日本語入力ソースID |
| `M.englishSources` | 英字側の入力ソースID。上から順に試す |
| `M.settleDelay` | 切り替えから `/` 送出までの待ち時間(秒)。取りこぼす時は増やす |

アプリのバンドルIDは次で調べられます。

```sh
osascript -e 'id of app "iTerm"'
```

## 一時停止と再開

ターミナルから操作できます。`init.lua` の `require("hs.ipc")` がこの操作を有効にしています。

```sh
hs -c "SlashSwitcher:disable()"
hs -c "SlashSwitcher:enable()"
hs -c "SlashSwitcher:status()"
```

## License

[MIT](LICENSE)
