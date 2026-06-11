local eventtap = hs.eventtap
local event = eventtap.event
local timer = hs.timer
local keycodes = hs.keycodes.map

local settings = require("settings")
local ime_hotkey = require("lib.ime_hotkey")
local synthetic_event = require("lib.synthetic_event")

local M = {}

local types = event.types
local props = synthetic_event.properties
local raw_masks = event.rawFlagMasks or {}

local left_ctrl = keycodes.ctrl
local right_ctrl = keycodes.rightctrl
local open_bracket = keycodes["["]

local tap_state = {
  prefix_armed = false,
  prefix_timer = nil,
  ctrl_tap_candidate = false,
  ctrl_used_with_other_input = false,
  swallow_open_bracket_up = false,
}

local function raw_has(raw_flags, name)
  local mask = raw_masks[name] or 0
  return mask ~= 0 and (raw_flags & mask) ~= 0
end

local function ctrl_key_is_down(keycode, raw_flags, flags)
  if keycode == left_ctrl then
    return raw_has(raw_flags, "deviceLeftControl") or flags.ctrl
  end

  if keycode == right_ctrl then
    return raw_has(raw_flags, "deviceRightControl") or flags.ctrl
  end

  return false
end

local function new_ctrl_bracket_event(is_down)
  return synthetic_event.new_key_event({ "ctrl" }, "[", is_down)
end

local function clear_prefix()
  tap_state.prefix_armed = false

  if tap_state.prefix_timer then
    tap_state.prefix_timer:stop()
    tap_state.prefix_timer = nil
  end
end

local function switch_to_english_after_trigger()
  ime_hotkey.switch_to_english_after(settings.ctrl_prefix_bracket.switch_delay_seconds)
end

local function arm_prefix()
  clear_prefix()
  tap_state.prefix_armed = true

  tap_state.prefix_timer = timer.doAfter(settings.ctrl_prefix_bracket.timeout_seconds, function()
    tap_state.prefix_armed = false
    tap_state.prefix_timer = nil
  end)
end

-- 规则语义:
-- 1. 独立点按 Ctrl.
-- 2. 松开后 timeout_seconds 内按下 [.
-- 3. 自动发送 Ctrl+[.
-- 4. 然后再发出 Karabiner 那套切英文快捷键.
local function handle_event(e)
  if synthetic_event.is_synthetic(e) then
    return false
  end

  local event_type = e:getType()
  local keycode = e:getKeyCode()
  local flags = e:getFlags()
  local raw_flags = e:rawFlags()

  if event_type == types.flagsChanged then
    if keycode == left_ctrl or keycode == right_ctrl then
      if ctrl_key_is_down(keycode, raw_flags, flags) then
        tap_state.ctrl_tap_candidate = true
        tap_state.ctrl_used_with_other_input = false
        clear_prefix()
      else
        if tap_state.ctrl_tap_candidate and not tap_state.ctrl_used_with_other_input then
          arm_prefix()
        end

        tap_state.ctrl_tap_candidate = false
        tap_state.ctrl_used_with_other_input = false
      end

      return false
    end

    if tap_state.ctrl_tap_candidate then
      tap_state.ctrl_used_with_other_input = true
    end

    if tap_state.prefix_armed then
      clear_prefix()
    end

    return false
  end

  if event_type == types.keyDown then
    if tap_state.ctrl_tap_candidate then
      tap_state.ctrl_used_with_other_input = true
    end

    if tap_state.prefix_armed
      and keycode == open_bracket
      and not flags.cmd
      and not flags.alt
      and not flags.shift
      and not flags.ctrl
      and not flags.fn
    then
      clear_prefix()
      tap_state.swallow_open_bracket_up = true
      switch_to_english_after_trigger()
      return true, {
        new_ctrl_bracket_event(true),
        new_ctrl_bracket_event(false),
      }
    end

    if tap_state.prefix_armed then
      clear_prefix()
    end

    return false
  end

  if event_type == types.keyUp and tap_state.swallow_open_bracket_up and keycode == open_bracket then
    tap_state.swallow_open_bracket_up = false
    return true
  end

  return false
end

function M.start()
  if M.keyboard_tap then
    M.keyboard_tap:stop()
  end

  M.keyboard_tap = eventtap.new({ types.flagsChanged, types.keyDown, types.keyUp }, handle_event)
  M.keyboard_tap:start()
end

return M
