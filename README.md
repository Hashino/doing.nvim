# Doing.nvim

A tiny task manager within nvim that helps you stay on track by keeping a stack
of tasks and always showing which task is at the top and how many more you have.

this plugin was originally a fork of [nocksock/do.nvim](https://github.com/nocksock/do.nvim)

![doing](https://raw.githubusercontent.com/Hashino/doing.nvim/main/demo.gif)

## Usage

-  `:Do` add a task to the end of the list
-  `:Do!` add a task to the front of list
-  `:Done` remove the first task from the list
-  `:DoEdit` edit the tasklist in a floating window
-  `:DoToggle` toggle the display

## Installation

lazy.nvim:

```lua
-- minimal installations
return {
  'Hashino/doing.nvim',
  config = true,
}
```

## Configuration

``` lua
-- example configuration
return {
  'hashino/doing.nvim',
  config = function()
    require('doing').setup {
      message_timeout = 2000,

      -- doesn't display on buffers that match filetype/filename to entries
      -- can be either an array or a function that returns an array
      ignored_buffers = { 'NvimTree' }

      winbar = { 
        enabled = true,
      },

      doing_prefix = 'Current Task: ',

      store = {
        -- automatically create a task file when openning directories
        auto_create_file = false, 
        file_name = '.tasks',
      },
    }
    -- example on how to change the winbar highlight
    vim.api.nvim_set_hl(0, 'WinBar', { link = 'Search' })

    local api = require('doing.api')

    vim.keymap.set('n', '<leader>de', api.edit, { desc = '[E]dit what tasks you`re [D]oing' })
    vim.keymap.set('n', '<leader>dn', api.done, { desc = '[D]o[n]e with current task' })
  end,
}
```

### Lualine

In case you'd rather use it with another plugin instead of the default winbar
implementation, you can use the exposed views to do so. 
For example with lualine:

```lua
require('lualine').setup {
  winbar = {
    lualine_a = { require'doing.api'.status },
  },
}
```

### Events

This plugin exposes a custom event, for when a task is added or modified. You can use it like so:

```lua
vim.api.nvim_create_autocmd({ "User" }, {
   group = require("doing.state").auGroupID,
   pattern = "TaskModified",
   desc = "This is called when a task is added or deleted",
   callback = function()
      vim.notify("A task has been modified")
   end,
})
```

