-- Hammerspoon の設定入口 (~/.hammerspoon/init.lua)

-- ターミナルから hs コマンドで操作できるようにする (一時停止・再開に使う)
require("hs.ipc")

-- 日本語入力中でもスラッシュコマンドが打てるようにする
SlashSwitcher = require("slash-switcher")
