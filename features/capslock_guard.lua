local eventtap = hs.eventtap
local event = eventtap.event
local timer = hs.timer
local keycodes = hs.keycodes.map
local capslock = hs.hid.capslock

local M = {}

local types = event.types
local capslock_key = keycodes.capslock or 57

local reset_timer = nil
local reset_delay_seconds = 0.01

local function capslock_is_on(flags)
  if flags and flags.capslock then
    return true
  end

  return capslock.get()
end

local function cancel_reset_timer()
  if reset_timer then
    reset_timer:stop()
    reset_timer = nil
  end
end

local function set_capslock_off()
  if capslock.get() then
    capslock.set(false)
  end
end

local function schedule_capslock_reset()
  cancel_reset_timer()
  set_capslock_off()

  reset_timer = timer.doAfter(reset_delay_seconds, function()
    reset_timer = nil
    set_capslock_off()
  end)
end

local function handle_event(e)
  if e:getType() ~= types.flagsChanged then
    return false
  end

  if e:getKeyCode() ~= capslock_key then
    return false
  end

  if capslock_is_on(e:getFlags()) then
    schedule_capslock_reset()
    return false
  end

  return false
end

function M.start()
  if M.keyboard_tap then
    M.keyboard_tap:stop()
  end

  M.keyboard_tap = eventtap.new({ types.flagsChanged }, handle_event)
  M.keyboard_tap:start()
  schedule_capslock_reset()
end

return M
