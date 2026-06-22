local eventtap = hs.eventtap
local event = eventtap.event

local M = {}

M.synthetic_tag = 0x4354524C
M.properties = event.properties

function M.is_synthetic(e)
  return e:getProperty(M.properties.eventSourceUserData) == M.synthetic_tag
end

function M.mark_event(e)
  e:setProperty(M.properties.eventSourceUserData, M.synthetic_tag)
  return e
end

function M.new_key_event(modifiers, key, is_down)
  return M.mark_event(event.newKeyEvent(modifiers, key, is_down))
end

function M.new_keycode_event(keycode, is_down)
  return M.mark_event(event.newKeyEvent(keycode, is_down))
end

return M
