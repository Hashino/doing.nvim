<div align="right">
  <a href="https://www.buymeacoffee.com/Hashino" target="_blank">
    <img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" 
    alt="Buy Me A Coffee" style="height: 24px !important;width: 104px !important;" >
  </a>
</div>

# doing.nvim

<a href="https://dotfyle.com/plugins/Hashino/doing.nvim">
  <img src="https://dotfyle.com/plugins/Hashino/doing.nvim/shield"/>
</a>

A minimal task manager for neovim. Works by keeping a stack of strings stored in
plain text file and offering some ways of displaying those tasks.

This plugin is meant to be very small, simple to use and performant. If you want
a more featureful task manager, check out [todotxt.nvim](https://github.com/arnarg/todotxt.nvim) and [dooing](https://github.com/atiladefreitas/dooing).

this plugin was originally a fork of [nocksock/do.nvim](https://github.com/nocksock/do.nvim)

![doing](https://raw.githubusercontent.com/Hashino/doing.nvim/main/demo.gif)
*the gif was recorded using a [custom heirline component](https://github.com/Hashino/hash.nvim/blob/16d5a2af48b793808ee6d7daac0b8d6698faaa14/lua/hash/plugins/interface/status-bar.lua#L176-L221)*

## Commands

### Adding/Removing Tasks

- `:Do` will prompt user input for `{task}`
- `:Do {task}`
- `:Do "{task}"`
- `:Do add {task}` 

*will all add `{task}` to the end of the tasklist*

- `:Do!` will prompt user input for `{task}`
- `:Do! {task}`
- `:Do! "{task}"`
- `:Do! add {task}` 

*will all add `{task}` to the start of the tasklist*

- `:Done`
- `:Do done`

*will both remove the current task from the list* 

### Other Commands

- `:Do status` shows notification with current task/message
- `:Do edit` edit the tasklist in a floating window
- `:Do toggle` toggle the display (winbar and status)

## Installation

lazy.nvim:
```lua
-- minimal installation
{
  "Hashino/doing.nvim",
  cmd = "Do",
  keys = {
    { "<leader>da", function() require("doing").add() end, {}, },
    { "<leader>dn", function() require("doing").done() end, {}, },
    { "<leader>de", function() require("doing").edit() end, {}, },
  },
}
```

## Configuration

### Default Options

[see the source code for default options](https://github.com/Hashino/doing.nvim/blob/main/lua/doing/config.lua)

### Example Config

```lua
{
  "Hashino/doing.nvim",
  config = function()
    -- default options
    require("doing").setup {
      message_timeout = 2000,
      doing_prefix = "Doing: ",

      -- doesn't display on buffers that match filetype/filename/filepath to
      -- entries. can be either a string array or a function that returns a
      -- string array. filepath can be relative to cwd or absolute
      ignored_buffers = { "NvimTree" },

      -- if should append "+n more" to the status when there's tasks remaining
      show_remaining = true,

      -- if should show messages on the status string
      show_messages = true,

      -- window configs of the floating tasks editor
      -- see :h nvim_open_win() for available options
      edit_win_config = {
        width = 50,
        height = 15,
        border = "rounded",
      },

      -- if plugin should manage the winbar
      winbar = { enabled = true, },

      store = {
        -- name of tasks file
        file_name = ".tasks",
      },
    }
    -- example on how to change the winbar highlight
    vim.api.nvim_set_hl(0, "WinBar", { link = "Search" })

    local doing = require("doing")

    vim.keymap.set("n", "<leader>da", doing.add, { desc = "[D]oing: [A]dd" })
    vim.keymap.set("n", "<leader>de", doing.edit, { desc = "[D]oing: [E]dit" })
    vim.keymap.set("n", "<leader>dn", doing.done, { desc = "[D]oing: Do[n]e" })
    vim.keymap.set("n", "<leader>dt", doing.toggle, { desc = "[D]oing: [T]oggle" })

    vim.keymap.set("n", "<leader>ds", function()
      vim.notify(doing.status(true), vim.log.levels.INFO,
        { title = "Doing:", icon = "", })
    end, { desc = "[D]oing: [S]tatus", })
  end,
}
```

### Integration

In case you'd rather display the tasks with another plugin instead of the
default winbar implementation, you can use the exposed views to do so.

For example with lualine:

```lua
require("lualine").setup {
  winbar = {
    lualine_a = { require("doing").status },
  },
}
```

with heirline:
```lua
{
  provider = function()
    local doing = require("doing")
    return " " .. doing.status() .. " +" .. tostring(doing.tasks_left())
  end,
  update = { "BufEnter", "User", pattern = "TaskModified", },
},
```

### Events

This plugin exposes a custom event, for when a task is added, edited or
completed. You can use it like so:

```lua
vim.api.nvim_create_autocmd({ "User" }, {
   pattern = "TaskModified",
   desc = "This is called when a task is added, edited or completed",
   callback = function()
      vim.notify("A task has been modified")
   end,
})
```

### Recipes

If your winbar is already in use and your status bar is full, you can use
`doing` with just notifications:

```lua
{
  "Hashino/doing.nvim",
  lazy = true,
  init = function()
    local doing = require("doing")

    -- example keymaps
    vim.keymap.set("n", "<leader>da", doing.add, { desc = "[D]oing: [A]dd", })
    vim.keymap.set("n", "<leader>de", doing.edit, { desc = "[D]oing: [E]dit", })
    vim.keymap.set("n", "<leader>dn", doing.done, { desc = "[D]oing: Do[n]e", })

    vim.keymap.set("n", "<leader>ds", function()
      vim.notify(doing.status(true), vim.log.levels.INFO,
        { title = "Doing:", icon = "", })
    end, { desc = "[D]oing: [S]tatus", })

    vim.api.nvim_create_autocmd({ "User", }, {
      pattern = "TaskModified",
      desc = "This is called when a task is added, edited or completed",
      callback = function()
        vim.defer_fn(function()
          local status = doing.status()
          if status ~= "" then
            vim.notify(status, vim.log.levels.INFO,
              { title = "Doing:", icon = "", })
          end
        end, 0)
      end,
    })
  end,
}
```
