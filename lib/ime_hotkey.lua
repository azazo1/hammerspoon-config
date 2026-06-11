local timer = hs.timer
local settings = require("settings")
local synthetic_event = require("lib.synthetic_event")

local M = {}

-- 这里不直接切系统输入源.
-- 只负责发出你原来给 Karabiner 用的那组快捷键.
function M.switch_to_english()
  local shortcut = settings.ime_hotkey.english

  synthetic_event.new_key_event(shortcut.modifiers, shortcut.key, true):post()
  synthetic_event.new_key_event(shortcut.modifiers, shortcut.key, false):post()
end

function M.switch_to_english_after(delay_seconds)
  timer.doAfter(delay_seconds, function()
    M.switch_to_english()
  end)
end

return M
