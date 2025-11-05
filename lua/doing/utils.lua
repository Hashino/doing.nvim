local config = require("doing.config")

local Utils = {}

Utils.augroup = vim.api.nvim_create_augroup("Doing", { clear = true, })

---checks whether the current window/buffer should display the plugin
function Utils.should_display()
  -- once a window gets checked once, a variable is set to tell doing
  -- if it should render itself in it
  -- this avoids redoing the checking on every update
  if vim.b.doing_should_display then
    return vim.b.doing_should_display
  end

  -- checks if current buffer is a normal buffer
  if vim.bo.buftype == "popup" or vim.bo.buftype == "prompt" or vim.fn.win_gettype() ~= "" then
    vim.b.doing_should_display = false
    return false
  else
    local path_sep = Utils.os_path_separator()

    ---@diagnostic disable-next-line: param-type-mismatch
    for _, exclude in ipairs(config.ignored_buffers) do
      -- checks if exclude is a relative filepath and expands it
      if exclude:sub(1, 2) == "." .. path_sep then
        exclude = vim.fn.getcwd() .. exclude:sub(2, -1)
      end

      exclude = exclude:gsub("~", tostring(os.getenv("HOME"))) -- expand ~ to home directory

      if
         vim.bo.filetype:find(exclude)     -- match filetype
         or exclude == vim.fn.expand("%")  -- match filename
         or exclude == vim.fn.expand("%:p") -- match filepath
      then
        vim.b.doing_should_display = false
        return false
      end
    end

    vim.b.doing_should_display = true
    return true
  end
end

function Utils.os_path_separator()
  return vim.uv.os_uname().sysname:find("Windows") and "\\" or "/"
end

--- calls vim.notify with a styled title and icon
---@param msg string the message to show
---@param log_level? integer One of the values from |vim.log.levels|.
function Utils.notify(msg, log_level)
  vim.notify(msg, log_level or vim.log.levels.OFF, { title = "doing.nvim", icon = "", })
end

return Utils
