-- Terraria 滚轮修复.
-- macOS 把一格滚轮上报成 2 行, 游戏按行数决定滚几格, 于是一格滚两格.
-- 这里把行增量改写成一格一步, 点增量保持原样, 事件继续正常传递.
local eventtap = hs.eventtap
local event = eventtap.event
local props = event.properties
local types = event.types

local synthetic = require("lib.synthetic_event")

local M = {}

M.bundle_id = "org.Terraria"
M.mode = "fix" -- fix: 改写行增量为 +/-1; probe: 只记录不改写
M.log_path = hs.configdir .. "/scroll_probe.log"
M.log_limit = 0 -- 0 表示不写日志, 需要排查时再调大

local log_count = 0

local function is_target()
  local app = hs.application.frontmostApplication()

  return app ~= nil and app:bundleID() == M.bundle_id
end

local function append_log(text)
  local f = io.open(M.log_path, "a")

  if not f then
    return
  end

  f:write(text)
  f:write("\n")
  f:close()
end

local function handle(e)
  if synthetic.is_synthetic(e) then
    return false
  end

  if not is_target() then
    return false
  end

  local line = e:getProperty(props.scrollWheelEventDeltaAxis1) or 0

  if line == 0 then
    return false
  end

  local sign = line > 0 and 1 or -1

  if M.mode == "probe" then
    if log_count < M.log_limit then
      log_count = log_count + 1
      append_log(string.format("%s probe line=%s point=%s fixed=%s",
        os.date("%H:%M:%S"), tostring(line),
        tostring(e:getProperty(props.scrollWheelEventPointDeltaAxis1)),
        tostring(e:getProperty(props.scrollWheelEventFixedPtDeltaAxis1))))
    end

    return false
  end

  local ok = pcall(function()
    e:setProperty(props.scrollWheelEventDeltaAxis1, sign)
    e:setProperty(props.scrollWheelEventFixedPtDeltaAxis1, sign)
  end)

  if log_count < M.log_limit then
    log_count = log_count + 1
    append_log(string.format("%s raw=%s ok=%s now_line=%s now_fixed=%s",
      os.date("%H:%M:%S"), tostring(line), tostring(ok),
      tostring(e:getProperty(props.scrollWheelEventDeltaAxis1)),
      tostring(e:getProperty(props.scrollWheelEventFixedPtDeltaAxis1))))
  end

  return false
end

function M.start()
  if M.tap then
    M.tap:stop()
  end

  if M.log_limit > 0 then
    local f = io.open(M.log_path, "w")

    if f then
      f:write("# start " .. os.date("%H:%M:%S") .. " mode=" .. M.mode .. "\n")
      f:close()
    end
  end

  log_count = 0

  M.tap = eventtap.new({ types.scrollWheel }, handle)
  M.tap:start()

  hs.printf("[terraria-scroll] tap started, mode=%s", M.mode)
end

return M
