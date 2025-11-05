local config = require("doing.config")
local state  = require("doing.state")
local utils  = require("doing.utils")

local Doing  = {}

--- setup doing.nvim
---@param opts? doing.Config
function Doing.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  if type(config.ignored_buffers) == "function" then
    config.ignored_buffers = config.ignored_buffers()
  end

  -- doesn't touch the winbar if disabled so other plugins can manage
  -- it without interference
  if config.winbar.enabled then
    local function update_winbar()
      vim.api.nvim_set_option_value("winbar", Doing.status(), { scope = "local", })
    end

    vim.api.nvim_create_autocmd({ "BufEnter", }, {
      group = utils.augroup,
      callback = update_winbar,
    })

    vim.api.nvim_create_autocmd({ "User", }, {
      group = utils.augroup,
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
    state.changed()
  else
    vim.ui.input({ prompt = "Enter the new task: ", }, function(input)
      if input and input ~= "" then
        state.add(input, to_front)
        state.changed()
      end
    end)
  end
end

---finish the current task
function Doing.done()
  if #state.tasks > 0 then
    state.done()

    if #state.tasks == 0 then
      Doing.show_message("All tasks done ")
    elseif not config.show_remaining then
      Doing.show_message(#state.tasks .. " tasks left.")
    else
      state.changed()
    end
  else
    Doing.show_message("Not doing any task")
  end
end

---@param force? boolean return status even if the plugin is toggled off
---@return string current current plugin task or message
function Doing.status(force)
  if (state.view_enabled and utils.should_display()) or force then
    if state.message then
      return state.message
    elseif #state.tasks > 0 then
      local status = config.doing_prefix .. state.tasks[1]

      -- append task count number if there is more than 1 task
      if config.show_remaining and #state.tasks > 1 then
        status = status .. "  +" .. (#state.tasks - 1) .. " more"
      end

      return status
    elseif force then
      return "Not doing any tasks"
    end
  end
  return ""
end

local editor = {
  win = nil,
  buf = vim.api.nvim_create_buf(false, true),
}

-- sets tasks when window is closed
vim.api.nvim_create_autocmd("BufWinLeave", {
  group = utils.augroup,
  buffer = editor.buf,
  callback = function()
    state.tasks = vim.api.nvim_buf_get_lines(editor.buf, 0, -1, true)
    state.changed()
  end,
})

---edit the tasks in a floating window
function Doing.edit()
  if not editor.win then
    editor.win = vim.api.nvim_open_win(editor.buf, true, config.edit_win_config)

    vim.api.nvim_set_option_value("number", true, { win = editor.win, })
    vim.api.nvim_set_option_value("swapfile", false, { buf = editor.buf, })
    vim.api.nvim_set_option_value("bufhidden", "delete", { buf = editor.buf, })

    vim.api.nvim_buf_set_lines(editor.buf, 0, #state.tasks, false, state.tasks)

    vim.keymap.set("n", "q", function()
      editor.win = vim.api.nvim_win_close(editor.win, true)
    end, { buffer = editor.buf, })
  end
end

---toggle the visibility of the plugin
function Doing.toggle()
  state.view_enabled = not state.view_enabled
  state.changed()
end

---show a message for the duration of `options.message_timeout` or timeout
---@param message string message to show
---@param timeout? number time in ms to show message
function Doing.show_message(message, timeout)
  if config.show_messages then
    state.message = message
    state.changed()

    vim.defer_fn(function()
      state.message = nil
      state.changed()
    end, timeout or config.message_timeout or 100)
  else
    state.changed()
  end
end

---@return integer number of tasks left
function Doing.tasks_left()
  return #state.tasks or 0
end

function Doing.sync()
  state.sync()
end

return Doing
