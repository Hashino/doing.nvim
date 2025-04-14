local utils = require("doing.utils")
local doing = require("doing")

local do_cmds = {
  ["add"] = doing.add,
  ["edit"] = doing.edit,
  ["done"] = doing.done,
  ["toggle"] = doing.toggle,

  ["status"] = function()
    utils.notify(doing.status(true))
  end,
}

-- sets up the `:Do` command
vim.api.nvim_create_user_command("Do", function(args)
  -- split the command and the arguments by the first space
  local cmd = args.args:sub(1, (args.args:find(" ") or (#args.args + 1)) - 1)
  local cmd_args = args.args:sub(#cmd + 2) or ""

  -- checks if first argument is a Do command
  if vim.tbl_contains(vim.tbl_keys(do_cmds), cmd) then
    do_cmds[cmd](cmd_args, args.bang)
  else -- otherwise, treat the the arguments as the task
    do_cmds["add"](args.args, args.bang)
  end
end, {
  nargs = "?",
  bang = true,
  -- sets up completion for the `:Do` command
  complete = function(_, cmd_line)
    local params = vim.split(cmd_line, "%s+", { trimempty = true, })

    if #params == 1 then
      return vim.tbl_keys(do_cmds)
    end
  end,
})

vim.api.nvim_create_user_command("Done", "Do done", {})
