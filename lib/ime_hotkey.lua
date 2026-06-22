local timer = hs.timer
local keycodes = hs.keycodes.map
local settings = require("settings")
local synthetic_event = require("lib.synthetic_event")

local M = {}

local modifier_tap_seconds = 0.01

local modifier_keys = {
  rightshift = true,
}

local function has_modifiers(modifiers)
  return modifiers and next(modifiers) ~= nil
end

local function send_modifier_key(key)
  local keycode = assert(keycodes[key], "missing keycode: " .. key)

  synthetic_event.new_keycode_event(keycode, true):post()
  timer.doAfter(modifier_tap_seconds, function()
    synthetic_event.new_keycode_event(keycode, false):post()
  end)
end

local function send_shortcut(shortcut)
  if not has_modifiers(shortcut.modifiers) and modifier_keys[shortcut.key] then
    send_modifier_key(shortcut.key)
    return
  end

  synthetic_event.new_key_event(shortcut.modifiers, shortcut.key, true):post()
  synthetic_event.new_key_event(shortcut.modifiers, shortcut.key, false):post()
end

-- Send upstream hotkeys instead of changing macOS input sources directly.
function M.switch_to_english()
  send_shortcut(settings.ime_hotkey.english)
end

function M.switch_to_english_after(delay_seconds)
  timer.doAfter(delay_seconds, function()
    M.switch_to_english()
  end)
end

return M
