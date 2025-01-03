local state = require("doing.state")

local Utils = {}

--- gets called when a task is added, edited, or removed
function Utils.task_modified()
  Utils.update_winbar()
  vim.api.nvim_exec_autocmds("User", {
    pattern = "TaskModified",
    group = state.auGroupID,
  })
end

---redraw winbar depending on if there are tasks
function Utils.update_winbar()
  if state.options.winbar.enabled then
    vim.api.nvim_set_option_value("winbar", require("doing").status(),
      { scope = "local", })
  end
end

---checks whether the current window/buffer should display the plugin
function Utils.should_display()
  -- once a window gets checked once, a variable is set to tell doing
  -- if it should render itself in it
  -- this avoids redoing the cheking on every update
  if vim.b.doing_should_display then
    return vim.b.doing_should_display
  end

  if vim.bo.buftype == "popup"
     or vim.bo.buftype == "prompt"
     or vim.fn.win_gettype() ~= ""
  then
    -- saves result to a buffer variable
    vim.b.doing_should_display = false
    return false
  end

  local ignore = state.options.ignored_buffers
  ignore = type(ignore) == "function" and ignore() or ignore

  local home_path_abs = tostring(os.getenv("HOME"))
  local curr = vim.fn.expand("%:p")

  for _, exclude in ipairs(ignore) do
    -- checks if exclude is a relative filepath and expands it
    if exclude:sub(1, 2) == "./" or exclude:sub(1, 2) == ".\\" then
      exclude = vim.fn.getcwd() .. exclude:sub(2, -1)
      vim.notify(exclude)
    end

    if
       vim.bo.filetype:find(exclude)               -- match filetype
       or exclude == vim.fn.expand("%")            -- match filename
       or exclude:gsub("~", home_path_abs) == curr -- match filepath
    then
      -- saves result to a buffer variable
      vim.b.doing_should_display = false
      return false
    end
  end

  -- saves result to a buffer variable
  vim.b.doing_should_display = true
  return true
end

--- show a message for the duration of `options.message_timeout` or timeout
---@param str string message to show
---@param timeout? number time in ms to show message
function Utils.show_message(str, timeout)
  state.message = str
  Utils.task_modified()

  vim.defer_fn(function()
    state.message = nil
    Utils.task_modified()
  end, timeout or state.options.message_timeout)
end

return Utils
