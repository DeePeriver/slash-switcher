--- slash-switcher.lua
--- 日本語入力中に「/」を押したら、自動で英字入力に切り替えてから「/」を打つ。
--- スペース / Tab / クリック のいずれかで日本語入力に戻す。
---
--- 使い方:  init.lua に  SlashSwitcher = require("slash-switcher")  を追加
--- 一時停止:  hs -c "SlashSwitcher:disable()"   再開: hs -c "SlashSwitcher:enable()"

local M = {}

---------------------------------------------------------------------------
-- 設定
---------------------------------------------------------------------------

-- 「/」を横取りする対象アプリ(バンドルID)。ここに無いアプリでは何もしない。
M.targetApps = {
  ["com.stablyai.orca"]            = true,  -- Orca IDE
  ["com.mitchellh.ghostty"]        = true,  -- Ghostty
  ["com.anthropic.claudefordesktop"] = true, -- Claude デスクトップ
  ["com.apple.Terminal"]           = true,  -- ターミナル.app
}

-- 日本語に戻すトリガー
M.revertOn = {
  space  = true,
  tab    = true,
  click  = true,
  ["return"] = true,   -- 引数なしのコマンド(/clear 等)は Enter が唯一の復帰点になる
  escape     = false,  -- Esc でも戻したくなったら true にする
}

-- 入力ソースID
M.japaneseSource = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese"
-- 英字側は上から順に試して、実際に切り替わったものを使う
M.englishSources = {
  "com.apple.keylayout.British",
  "com.apple.keylayout.ABC",
  "com.apple.inputmethod.Kotoeri.RomajiTyping.Roman",
}

-- 入力ソース切り替えは非同期なので、切り替え直後に「/」を送ると取りこぼす。
-- 送出までの待ち時間(秒)。5回に1回化けるようなら少し増やす。
M.settleDelay = 0.04

---------------------------------------------------------------------------
-- 内部状態
---------------------------------------------------------------------------

local armed     = false  -- 自分が英字に切り替えた直後か(自分が切り替えた時だけ戻す)
local injecting = false  -- 自分が送出した「/」を自分で拾わないためのガード
local enabled   = true

local keycodes = hs.keycodes.map
local SLASH  = keycodes["/"]
local SPACE  = keycodes["space"]
local TAB    = keycodes["tab"]
local RETURN = keycodes["return"]
local ESCAPE = keycodes["escape"]
local PADENTER = keycodes["padenter"]

---------------------------------------------------------------------------
-- 入力ソース
---------------------------------------------------------------------------

local function isJapaneseMode()
  local id = hs.keycodes.currentSourceID()
  if not id then return false end
  -- ことえりは日本語モードと英数モードでIDが分かれるので確実に判定できる
  return id:find("Kotoeri", 1, true) ~= nil and id:find("Roman", 1, true) == nil
end

local function switchToEnglish()
  for _, id in ipairs(M.englishSources) do
    if hs.keycodes.currentSourceID(id) then return true end
  end
  return false
end

local function switchToJapanese()
  return hs.keycodes.currentSourceID(M.japaneseSource)
end

local function revert()
  if not armed then return end
  armed = false
  switchToJapanese()
end

---------------------------------------------------------------------------
-- キー監視
---------------------------------------------------------------------------

local function isTargetApp()
  local app = hs.application.frontmostApplication()
  if not app then return false end
  return M.targetApps[app:bundleID()] == true
end

local function hasOnlyPlainModifiers(event)
  local f = event:getFlags()
  return not (f.cmd or f.ctrl or f.alt or f.shift or f.fn)
end

local keyTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  if not enabled or injecting then return false end

  local code = event:getKeyCode()

  -- 1. 武装中なら、戻すトリガーかどうかを先に見る
  if armed then
    local shouldRevert =
      (M.revertOn.space  and code == SPACE)  or
      (M.revertOn.tab    and code == TAB)    or
      (M.revertOn["return"] and (code == RETURN or code == PADENTER)) or
      (M.revertOn.escape and code == ESCAPE)
    if shouldRevert then
      -- キー自体はそのまま通し、アプリが受け取ってから戻す
      hs.timer.doAfter(0.01, revert)
      return false
    end
  end

  -- 2. 「/」の横取り
  if code ~= SLASH then return false end
  if not hasOnlyPlainModifiers(event) then return false end  -- shift+/ は「?」なので対象外
  if not isTargetApp() then return false end
  if not isJapaneseMode() then return false end              -- 既に英字なら何もしない

  if not switchToEnglish() then return false end             -- 切り替え失敗時は握りつぶさない

  hs.timer.doAfter(M.settleDelay, function()
    injecting = true
    hs.eventtap.keyStrokes("/")
    injecting = false
    armed = true
  end)

  return true  -- 元の「/」は握りつぶす(これが「・」になる犯人)
end)

local mouseTap = hs.eventtap.new(
  { hs.eventtap.event.types.leftMouseDown, hs.eventtap.event.types.rightMouseDown },
  function()
    if enabled and armed and M.revertOn.click then revert() end
    return false
  end
)

---------------------------------------------------------------------------
-- 制御
---------------------------------------------------------------------------

function M:enable()
  enabled = true
  keyTap:start()
  mouseTap:start()
  return self
end

function M:disable()
  enabled = false
  armed = false
  keyTap:stop()
  mouseTap:stop()
  return self
end

function M:status()
  return string.format("enabled=%s armed=%s source=%s",
    tostring(enabled), tostring(armed), tostring(hs.keycodes.currentSourceID()))
end

M:enable()

return M
