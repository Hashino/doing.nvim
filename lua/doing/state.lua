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
    -- if there are tasks, write them to the file
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

---gets called when a task is added, edited, or removed
function State.task_modified()
  vim.api.nvim_exec_autocmds("User", { pattern = "TaskModified", })
  return config.options.store.sync_tasks and sync()
end

return State
