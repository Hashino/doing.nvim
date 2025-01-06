local win_cfg = require("doing.config").options.edit_win_config
local utils = require("doing.utils")

local Edit = {
  win = nil,
  buf = nil,
}

---@brief open floating window to edit tasks
---@param state table current state of doing.nvim
function Edit.open_edit(state)
  if not Edit.buf then
    Edit.buf = vim.api.nvim_create_buf(false, true)

    -- save tasks when window is closed
    vim.api.nvim_create_autocmd("BufWinLeave", {
      group = state.auGroupID,
      buffer = Edit.buf,
      callback = function()
        local lines = vim.api.nvim_buf_get_lines(Edit.buf, 0, -1, true)

        for i, line in ipairs(lines) do
          if line == "" then
            table.remove(lines, i)
          end
        end

        state.tasks:set(lines)
        utils.task_modified()
      end,
    })
  end

  if not Edit.win then
    Edit.win = vim.api.nvim_open_win(Edit.buf, true, win_cfg)

    vim.api.nvim_set_option_value("number", true, { win = Edit.win, })
    vim.api.nvim_set_option_value("swapfile", false, { buf = Edit.buf, })
    vim.api.nvim_set_option_value("filetype", "doing_tasks", { buf = Edit.buf, })
    vim.api.nvim_set_option_value("bufhidden", "delete", { buf = Edit.buf, })
  end

  vim.api.nvim_buf_set_lines(Edit.buf, 0, state.tasks:count(), false, state.tasks:get())

  ---closes the window, sets the task and calls task_modified
  local function close_edit()
    vim.api.nvim_win_close(Edit.win, true)
    Edit.win = nil
  end

  vim.keymap.set("n", "q", close_edit, { buffer = Edit.buf, })
  vim.keymap.set("n", "<Esc>", close_edit, { buffer = Edit.buf, })
end

return Edit
