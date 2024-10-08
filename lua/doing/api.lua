local Api = {}

local state = require("doing.state").state
local store = require("doing.store")
local core  = require('doing.core')
local utils = require("doing.utils")

---Create a winbar string for the current task
---@return string
function Api.status()
  state.tasks = store.init(state.options.store)
  local right = ""

  -- using pcall so that it won't spam error messages
  local ok, left = pcall(function()
    local count = state.tasks:count()
    local res = ""
    local current = state.tasks:current()

    if state.message then
      return state.message
    end

    if count == 0 then
      return ""
    end

    res = state.options.doing_prefix .. current

    -- append task count number if there is more than 1 task
    if count > 1 then
      right = '+' .. (count - 1) .. " more"
    end

    return res
  end)

  if not ok then
    return "ERR: " .. left
  end

  return ' ' .. left .. '  ' .. right .. ' '
end

---add a task to the list
---@param str string task to add
---@param to_front boolean whether to add task to front of list
function Api.add(str, to_front)
    state.tasks:add(str, to_front)
    core.redraw_winbar()
    utils.exec_task_modified_autocmd()
end

---edit the tasks in a floating window
function Api.edit()
  core.edit()
end

---finish the first task
function Api.done()
  core.done()
end

return Api
