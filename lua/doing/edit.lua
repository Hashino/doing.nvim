local state = require("doing.state")

local Edit  = {
  win = nil,
  buf = nil,
}

--- open floating window to edit tasks
function Edit.open_edit(opts)
  if not Edit.buf then
    Edit.buf = vim.api.nvim_create_buf(false, true)

    -- save tasks when window is closed
    vim.api.nvim_create_autocmd("BufWinLeave", {
      buffer = Edit.buf,
      callback = function()
        local lines = vim.api.nvim_buf_get_lines(Edit.buf, 0, -1, true)

        for i, line in ipairs(lines) do
          if line == "" then
            table.remove(lines, i)
          end
        end

        state.tasks = lines
        vim.defer_fn(state.task_modified, 0)
      end,
    })
  end

  if not Edit.win then
    Edit.win = vim.api.nvim_open_win(Edit.buf, true, opts.edit_win_config)

    vim.api.nvim_set_option_value("number", true, { win = Edit.win, })
    vim.api.nvim_set_option_value("swapfile", false, { buf = Edit.buf, })
    vim.api.nvim_set_option_value("filetype", "doing_tasks", { buf = Edit.buf, })
    vim.api.nvim_set_option_value("bufhidden", "delete", { buf = Edit.buf, })
  end

  vim.api.nvim_buf_set_lines(Edit.buf, 0, #state.tasks, false, state.tasks)

  ---closes the window, sets the task and calls task_modified
  local function close_edit()
    vim.api.nvim_win_close(Edit.win, true)
    Edit.win = nil
  end

  vim.keymap.set("n", "q", close_edit, { buffer = Edit.buf, })

  if opts.close_on_esc then
    vim.keymap.set("n", "<Esc>", close_edit, { buffer = Edit.buf, })
  end
end

return Edit
