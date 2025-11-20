local config = require("doing.config")
local utils = require("doing.utils")

local State = {
  tasks = {},
  message = nil,
  view_enabled = true,
}

---loads tasks from the file into the state
function State.load_tasks()
  local found, lines = pcall(vim.fn.readfile, config.options.store.file_name)

  if found then
    State.tasks = utils.remove_empty_lines(lines)
  else
    State.tasks = {}
  end

  State.changed()
end

---syncs tasks file with loaded state
function State.sync()
  if #State.tasks > 0 then
    -- if there are tasks, write them to the file
    vim.fn.writefile(State.tasks, config.options.store.file_name)
  elseif vim.fn.findfile(config.options.store.file_name, ".;") ~= "" then
    -- if file exists and there are no tasks, delete it
    vim.fn.delete(config.options.store.file_name)
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
