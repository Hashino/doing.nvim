local r = require

---@class DoSourceFileOptions
local default_options = {
  file_name = 'todos.do'
}

local opts = nil
local file = nil

---@type DoSource
return {
  ---@param opts? DoSourceFileOptions
  load = function(input_opts)
    opts = vim.tbl_extend("force", default_options, input_opts)

    r 'lua.do.sources.file.setup_autocmd' (opts)

    file = r 'do.sources.file.find' (opts.file_name)
    if file == nil then
      file = r 'do.source.file.create' (opts.file_name)
    end

    return r 'do.sources.file.parse' (vim.fn.readfile(file))
  end,

  ---@param state DoState
  save = function(state)
    local tasks = {}
    for _, todo in ipairs(state.todos) do
      table.insert(tasks, todo.task)
    end

    if not file then
      error("No file loaded")
    end

    if not vim.fn.filewritable(file) then
      error(string.format("Cannot write file %s", file))
    end

    vim.fn.writefile(tasks, file)
  end,
}
