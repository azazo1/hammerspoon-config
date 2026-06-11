require("hs.ipc")

local fs = hs.fs
local loaded_modules = {}

-- init.lua 只负责启动和装配.
-- 后续新增功能时, 直接往 features 目录里新增 .lua 文件即可.
local function feature_module_names()
  local names = {}
  local feature_dir = hs.configdir .. "/features"

  for entry in fs.dir(feature_dir) do
    if entry:match("%.lua$") then
      local module_name = entry:gsub("%.lua$", "")
      table.insert(names, "features." .. module_name)
    end
  end

  table.sort(names)
  return names
end

for _, module_name in ipairs(feature_module_names()) do
  local module = require(module_name)

  if type(module.start) == "function" then
    module.start()
    table.insert(loaded_modules, module_name)
  end
end

hs.printf("[init] loaded modules: %s", table.concat(loaded_modules, ", "))
