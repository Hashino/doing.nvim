local Config = {}

---@class DoingOptions config for [Hashino/doing.nvim]
---@field doing_prefix string prefix to show before the task
---@field ignored_buffers string[]|fun():string[] elements are checked against buffer filetype/filename/filepath
---@field show_remaining boolean show "+n more" when there are more than 1 tasks
---@field show_messages boolean show messages in status string
---@field message_timeout integer how many millisecons messages will stay on status
---@field winbar.enabled boolean if plugin should manage the winbar
---@field store.file_name string name of the task file
---@field store.sync_tasks boolean keeps the file tasks always in sync with the loaded tasks
---@field close_on_esc boolean if should close the edit window with <Esc>
---@field edit_win_config vim.api.keyset.win_config window configs of the floating editor

---@class DoingOptions
Config.default_opts = {
  doing_prefix = "Doing: ",

  -- doesn't display on buffers that match filetype/filename/filepath to
  -- entries. can be either a string array or a function that returns a
  -- string array. filepath can be relative to cwd or absolute
  ignored_buffers = { "NvimTree" },

  -- if should append "+n more" to the status when there's tasks remaining
  show_remaining = true,

  -- if should show messages on the status string
  -- if true, the status will show a message for the duration
  -- of message_timeout in the status string
  show_messages = true,
  message_timeout = 2000,

  winbar = {
    enabled = true, -- if plugin should manage the winbar
  },

  store = {
    file_name = ".tasks", -- name of tasks file
    sync_tasks = false, -- keeps the file tasks always in sync with the tasks
  },

  close_on_esc = true,

  -- window configs of the floating tasks editor
  -- see :h nvim_open_win() for available options
  edit_win_config = {
    width = 50,
    height = 15,

    relative = "editor",
    col = (vim.o.columns / 2) - (50 / 2),
    row = (vim.o.lines / 2) - (15 / 2),

    style = "minimal",
    border = "rounded",

    noautocmd = true,
  },
}

Config.options = Config.default_opts

return Config
