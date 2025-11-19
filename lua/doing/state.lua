local config = require("doing.config")
local utils = require("doing.utils")

local State = {
  file = nil,
  tasks = {},
  message = nil,
  view_enabled = true,
}

---loads tasks from the file into the state
function State.load_tasks()
  -- determine the file path for tasks file relative to the current working directory
  State.file = vim.fn.getcwd() .. utils.os_path_separator() .. config.options.store.file_name

  -- if the file exists, read its contents to state.tasks
  if vim.fn.findfile(State.file, ".;") ~= "" then
    local ok, res = pcall(vim.fn.readfile, State.file)
    if not ok then
      utils.notify("error reading tasks file:\n" .. res, vim.log.levels.ERROR)
    else
      -- prevents loading empty tasks
      State.tasks = utils.remove_empty_lines(res)
      State.changed()
    end
  end
end

---syncs file tasks with loaded tasks
function State.sync()
  if vim.fn.findfile(State.file, ".;") ~= "" and #State.tasks == 0 then
    -- if file exists and there are no tasks, delete it
    local ok, err = vim.uv.fs_unlink(State.file)

    if not ok then
      utils.notify("error deleting tasks file:\n" .. err, vim.log.levels.ERROR)
    end
  elseif #State.tasks > 0 then
    -- if there are tasks, write them to the file
    local ok, err = pcall(vim.fn.writefile, State.tasks, State.file)

    if not ok then
      utils.notify("error writing to tasks file:\n" .. err, vim.log.levels.ERROR)
    end
  end
end

function State.add(task, to_front)
  -- prevents empty tasks from being added
  if task ~= "" then
    if to_front then
      table.insert(State.tasks, 1, task)
    else
      table.insert(State.tasks, task)
    end

    State.changed()
  end
end

function State.done()
  table.remove(State.tasks, 1)
end

---gets called when a task is added, edited, or removed
function State.changed()
  vim.api.nvim_exec_autocmds("User", { pattern = "TaskModified", })
  return config.options.store.sync_tasks and State.sync()
end

return State
