local config = require("doing.config")
local utils = require("doing.utils")

local State = {
  file = nil,
  tasks = {},
  message = nil,
  view_enabled = true,
}

---loads tasks from the file into the state
local function load_tasks()
  -- determine the file path for tasks file relative to the current working directory
  State.file = vim.fn.getcwd() .. utils.os_path_separator() .. config.store.file_name

  -- if the file exists, read its contents to state.tasks
  if vim.fn.findfile(State.file, ".;") ~= "" then
    local ok, res = pcall(vim.fn.readfile, State.file)
    if not ok then
      utils.notify("error reading tasks file:\n" .. res, vim.log.levels.ERROR)
    else
      State.tasks = res
      State.changed()
    end
  end
end

-- reloads tasks when directory changes
vim.api.nvim_create_autocmd({ "DirChanged", }, {
  group = utils.augroup,
  callback = load_tasks,
})

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

-- saves tasks before quitting or changing directory
if not config.store.sync_tasks then
  vim.api.nvim_create_autocmd({ "VimLeave", "DirChangedPre", }, {
    group = utils.augroup,
    callback = State.sync,
  })
end

---gets called when a task is added, edited, or removed
function State.changed()
  vim.api.nvim_exec_autocmds("User", { pattern = "TaskModified", })
  return config.store.sync_tasks and State.sync()
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

load_tasks()

return State
