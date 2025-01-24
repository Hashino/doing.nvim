local config = require "doing.config"
local utils = require "doing.utils"

local State = {
  message = nil,
  view_enabled = true,
  tasks = {},
}

local tasks_file = ""

local function load_tasks()
  tasks_file = vim.fn.getcwd() .. utils.os_path_separator() .. config.options.store.file_name

  local ok, res = pcall(vim.fn.readfile, tasks_file)
  State.tasks = ok and res or {}
end

load_tasks()

-- reloads tasks when directory changes and on startup
vim.api.nvim_create_autocmd({ "DirChanged", "VimEnter" }, {
  callback = function()
    load_tasks()
    State.task_modified()
  end,
})

local function add_to_gitignore()
  --check if it is already ignored
  local gitignore = io.open(".gitignore", "r")
  local filename = config.options.store.file_name
  local is_ignored = false
  if gitignore then
    while not is_ignored do
      local line = gitignore:read "*line"
      if not line then
        break
      end
      if line == filename then
        is_ignored = true
        gitignore:close()
      end
    end
  end

  --if it is not ignored, ignore it
  if not is_ignored then
    gitignore = io.open(".gitignore", "a")
    if gitignore then
      gitignore:write(filename .. "\n")
      gitignore:close()
    end
  end

  if gitignore then
    gitignore:write(config.options.store.file_name .. "\n")
    gitignore:close()
  end
end

---syncs file tasks with loaded tasks
local function sync()
  if vim.fn.findfile(tasks_file, ".;") ~= "" and #State.tasks == 0 then
    -- if file exists and there are no tasks, delete it
    vim.schedule_wrap(function()
      local ok, err, err_name = (vim.uv or vim.loop).fs_unlink(tasks_file)

      if not ok then
        utils.notify(tostring(err_name) .. ":" .. tostring(err), vim.log.levels.ERROR)
      end
    end)()
  end

  local ok, err = pcall(vim.fn.writefile, State.tasks, tasks_file)

  if #State.tasks > 0 and not ok then
    utils.notify("error writing to tasks file:\n" .. err, vim.log.levels.ERROR)
  end
  if ok then
    add_to_gitignore()
  end
end

if not config.options.store.sync_tasks then
  vim.api.nvim_create_autocmd({ "VimLeave", "DirChangedPre" }, { callback = sync })
end

---@param force? boolean return status even if the plugin is toggled off
---@return string current current plugin task or message
function State.status(force)
  if (State.view_enabled or force) and utils.should_display() then
    local count = #State.tasks or 0
    if State.message then
      return State.message
    elseif count > 0 then
      local tasks_left = ""

      -- append task count number if there is more than 1 task
      if config.options.show_remaining and count > 1 then
        tasks_left = "  +" .. (count - 1) .. " more"
      end

      return config.options.doing_prefix .. State.tasks[1] .. tasks_left
    elseif force then
      return "Not doing any tasks"
    end
  end
  return ""
end

---show a message for the duration of `options.message_timeout` or timeout
---@param str string message to show
---@param timeout? number time in ms to show message
function State.show_message(str, timeout)
  if config.options.show_messages then
    State.message = str
    State.task_modified()

    vim.defer_fn(function()
      State.message = nil
      State.task_modified()
    end, timeout or config.options.message_timeout)
  else
    State.task_modified()
  end
end

---gets called when a task is added, edited, or removed
function State.task_modified()
  vim.api.nvim_exec_autocmds("User", { pattern = "TaskModified" })
  return config.options.store.sync_tasks and sync()
end

function State.add(str, to_front)
  if to_front then
    table.insert(State.tasks, 1, str)
  else
    table.insert(State.tasks, str)
  end
end

function State.done()
  table.remove(State.tasks, 1)
end

return State
