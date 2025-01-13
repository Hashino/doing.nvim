local config = require("doing.config")
local state  = require("doing.state")
local edit   = require("doing.edit")

local Doing  = {}

--- setup doing.nvim
---@param opts? DoingOptions
function Doing.setup(opts)
  config.options = vim.tbl_deep_extend("force", config.default_opts, opts or {})

  -- doesn't touch the winbar if disabled so other plugins can manage
  -- it without interference
  if config.options.winbar.enabled then
    vim.api.nvim_create_autocmd({ "BufEnter", }, {
      callback = function()
        vim.api.nvim_set_option_value("winbar", state.status(),
          { scope = "local", })
      end,
    })
  end
end

--- add a task to the list
---@param task? string task to add
---@param to_front? boolean whether to add task to front of list
function Doing.add(task, to_front)
  if task ~= nil and task ~= "" then
    -- remove quotes if present
    if task:sub(1, 1) == '"' and task:sub(-1, -1) == '"' then
      task = task:sub(2, -2)
    end

    state.add(task, to_front)
    state.task_modified()
  else
    vim.ui.input({ prompt = "Enter the new task: ", }, function(input)
      state.add(input, to_front)
      state.task_modified()
    end)
  end
end

---edit the tasks in a floating window
function Doing.edit()
  edit.open_edit()
end

---finish the current task
function Doing.done()
  if #state.tasks > 0 then
    state.done()

    if #state.tasks == 0 then
      state.show_message("All tasks done ")
    elseif not config.options.show_remaining then
      state.show_message(#state.tasks .. " tasks left.")
    else
      state.task_modified()
    end
  else
    state.show_message("Not doing any task")
  end
end

---@param force? boolean return status even if the plugin is toggled off
---@return string current current plugin task or message
function Doing.status(force)
  return state.status(force)
end

---toggle the visibility of the plugin
function Doing.toggle()
  state.view_enabled = not state.view_enabled
  state.task_modified()
end

---@return integer number of tasks left
function Doing.tasks_left()
  return #state.tasks or 0
end

return Doing
