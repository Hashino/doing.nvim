local config = require("doing.config")
local utils = require("doing.utils")

local State = {
  message = nil,
  view_enabled = true,
  tasks = {},
}

local tasks_file = ""

-- reloads tasks when directory changes and on startup
vim.api.nvim_create_autocmd({ "DirChanged", "VimEnter", }, {
  callback = function()
    tasks_file = vim.fn.getcwd()
       .. utils.os_path_separator()
       .. config.options.store.file_name

    local ok, res = pcall(vim.fn.readfile, tasks_file)
    State.tasks = ok and res or {}

    State.task_modified()
  end,
})

---syncs file tasks with loaded tasks
local function sync()
  if vim.fn.findfile(tasks_file, ".;") ~= "" and #State.tasks == 0 then
    -- if file exists and there are no tasks, delete it
    vim.schedule_wrap(function()
      local ok, err, err_name = (vim.uv or vim.loop).fs_unlink(tasks_file)

      if not ok then
        utils.notify("error deleting tasks file: " .. tostring(err_name) .. "\n" .. err,
          vim.log.levels.ERROR)
      end
    end)()
  elseif #State.tasks > 0 then
    -- if tasks exist, write them to the file
    local ok, err, err_name = pcall(vim.fn.writefile, State.tasks, tasks_file)

    if not ok then
      utils.notify("error writing to tasks file:" .. tostring(err_name) .. "\n" .. err,
        vim.log.levels.ERROR)
    end
  end
end

if not config.options.store.sync_tasks then
  vim.api.nvim_create_autocmd({ "VimLeave", "DirChangedPre", }, { callback = sync, })
end

---@param force? boolean return status even if the plugin is toggled off
---@return string current current plugin task or message
function State.status(force)
  if (State.view_enabled or force) and utils.should_display() then
    if State.message then
      return State.message
    elseif #State.tasks > 0 then
      local status = config.options.doing_prefix .. State.tasks[1]

      -- append task count number if there is more than 1 task
      if config.options.show_remaining and #State.tasks > 1 then
        status = status .. "  +" .. (#State.tasks - 1) .. " more"
      end

      return status
    elseif force then
      return "Not doing any tasks"
    end
  end
  return ""
end

function State.add(task, to_front)
  if to_front then
    table.insert(State.tasks, 1, task)
  else
    table.insert(State.tasks, task)
  end
end

function State.done()
  table.remove(State.tasks, 1)
end

---show a message for the duration of `options.message_timeout` or timeout
---@param message string message to show
---@param timeout? number time in ms to show message
function State.show_message(message, timeout)
  if config.options.show_messages then
    State.message = message
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
  vim.api.nvim_exec_autocmds("User", { pattern = "TaskModified", })
  return config.options.store.sync_tasks and sync()
end

return State
