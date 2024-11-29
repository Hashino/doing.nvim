local Core = {}

local view = require("doing.view")
local edit = require("doing.edit")
local state = require("doing.state")
local utils = require("doing.utils")

---Setup doing.nvim
---@param opts Options
function Core.setup(opts)
  state.options = vim.tbl_deep_extend("force", state.default_opts, opts or {})
  state.tasks = state.init(state.options.store)

  Core.setup_winbar()

  return Core
end

---add a task to the list
function Core.add(task, to_front)
  state.tasks:sync(true)
  if task == nil then
    vim.ui.input({ prompt = 'Enter the new task: ' }, function(input)
      state.tasks:add(input, to_front)
      Core.redraw_winbar()
      utils.exec_task_modified_autocmd()
    end)
  else
    state.tasks:add(task, to_front)
    if state.options.winbar.enabled then
      Core.redraw_winbar()
    end
  end
end

--- Edit the tasks in a floating window
function Core.edit()
  edit.toggle_edit(state.tasks:get(), function(new_todos)
    state.tasks:set(new_todos)
    utils.exec_task_modified_autocmd()
  end)
  state.tasks:sync(true)
  Core.redraw_winbar()
end

--- Finish the current task
function Core.done()
  if not state.tasks:has_items() then
    Core.show_message(" There was nothing left to do ")
    return
  end

  state.tasks:shift()

  if state.tasks:count() == 0 then
    Core.show_message(" All tasks done ")
  else
    Core.show_message(state.tasks:count() .. " left.")
  end

  utils.exec_task_modified_autocmd()
end

--- toggle the visibility of the plugin
function Core.toggle_display()
  state.view_enabled = not state.view_enabled

  if state.options.winbar.enabled then
    -- disable winbar completely when not visible
    vim.wo.winbar = vim.wo.winbar == "" and view.stl or ""
    Core.redraw_winbar()
  end
end

---configure displaying current to do item in winbar
function Core.setup_winbar()
  if not state.options.winbar.enabled then
    return
  end

  _G.DoingStatusline = view.status

  vim.g.winbar = view.stl
  vim.api.nvim_set_option_value("winbar", view.stl, {})

  state.auGroupID = vim.api.nvim_create_augroup("doing_nvim", { clear = true })

  -- winbar should not be displayed in windows the cursor is not in
  vim.api.nvim_create_autocmd({ "WinEnter", "WinLeave", "BufEnter", "BufLeave" }, {
    group = state.auGroupID,
    callback = function()
      Core.redraw_winbar()
    end,
  })
end

function Core.hide_winbar()
  vim.wo.winbar = ""

  vim.cmd([[ set winbar= ]])
  vim.cmd([[ redrawstatus ]])
end

--- Redraw winbar depending on if there are tasks. Redraw if there are pending tasks, other wise set to ""
function Core.redraw_winbar()
  if utils.should_display_task() and
      state.options.winbar.enabled
  then
    if state.tasks:has_items() or state.message then
      vim.wo.winbar = view.stl
    else
      Core.hide_winbar()
    end
  else
    Core.hide_winbar()
  end
end

---Show a message for the duration of `options.message_timeout`
---@param str string Text to display
function Core.show_message(str)
  state.message = str

  vim.defer_fn(function()
    state.message = nil
    Core.redraw_winbar()
  end, state.default_opts.message_timeout)

  Core.redraw_winbar()
end

return Core
