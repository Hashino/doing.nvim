local config = require("doing.config")
local state  = require("doing.state")
local edit   = require("doing.edit")
local utils  = require("doing.utils")

local Doing  = {}

--- setup doing.nvim
---@param opts? DoingOptions
function Doing.setup(opts)
  config.options = vim.tbl_deep_extend("force", config.default_opts, opts or {})

  -- doesn't touch the winbar if disabled so other plugins can manage
  -- it without interference
  if config.options.winbar.enabled then
    local function update_winbar()
      vim.defer_fn(function()
        vim.api.nvim_set_option_value("winbar", state.status(), { scope = "local", })
      end, 0)
    end

    vim.api.nvim_create_autocmd({ "BufEnter", }, {
      callback = update_winbar,
    })

    vim.api.nvim_create_autocmd({ "User", }, {
      pattern = "TaskModified",
      callback = update_winbar,
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
      if input then
        state.add(input, to_front)
        state.task_modified()
      end
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

function Doing.random()
  if #state.tasks > 0 then
    local task = state.tasks[math.random(#state.tasks)]

    if not config.options.show_messages then
      utils.notify("Do: " .. task)
    else
      state.show_message("Do: " .. task, 10000)
    end
  else
    state.show_message("No tasks to do")
  end
end

return Doing
