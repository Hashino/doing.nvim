local config = require("doing.config")

local Utils = {}

Utils.augroup = vim.api.nvim_create_augroup("Doing", { clear = true, })

---checks whether the current window/buffer should display the plugin
function Utils.should_display()
  -- once a window gets checked once, a variable is set to tell doing
  -- if it should render itself in it
  -- this avoids redoing the checking on every update
  if vim.b.doing_should_display ~= nil then
    return vim.b.doing_should_display
  end

  -- checks if current buffer is a normal buffer
  if vim.bo.buftype == "popup" or vim.bo.buftype == "prompt" or vim.fn.win_gettype() ~= "" then
    vim.b.doing_should_display = false
    return false
  else
    ---@diagnostic disable-next-line: param-type-mismatch
    for _, exclude in ipairs(config.options.ignored_buffers) do
      if
         vim.bo.filetype:find(exclude)      -- match filetype
         or exclude == vim.fn.expand("%")   -- match filename
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

function Utils.remove_empty_lines(lines)
  local cleaned = {}

  for _, line in ipairs(lines) do
    if line ~= "" then
      table.insert(cleaned, line)
    end
  end

  return cleaned
end

return Utils
