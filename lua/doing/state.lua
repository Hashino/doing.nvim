local State = {}

State.default_opts = {
  message_timeout = 2000,
  doing_prefix = "Doing: ",


  ignored_buffers = { "NvimTree" },

  winbar = {
    enabled = true,
  },

  store = {
    auto_create_file = false,
    file_name = ".tasks"
  }
}

State.view_enabled = true
State.tasks = nil
State.message = nil
State.auGroupID = nil
State.options = State.default_opts

---initialize task store
State.init = function(options)

  local default_state = {
    options = options,
    file = nil,
    tasks = {}
  }

  local instance = setmetatable(default_state, { __index = State })

  local state = require("doing.state")
  vim.api.nvim_create_autocmd("DirChanged", {
    group = state.auGroupID,
    callback = function()
      state.tasks = State.init(state.options.store)
    end,
  })

  return instance:set(instance:import_file() or {})
end

function State:create_file()
  local name = State.options.store.file_name
  local cwd = vim.loop.cwd()
  local file = io.open(cwd .. "/" .. name, "w")
  assert(file, "couldn't create " .. name .. " in current cwd: " .. cwd)
  file:write("")
  file:close()
  return name
end

function State:find_file(force)
  local options = State.options
  local file = vim.fn.findfile(vim.loop.cwd() .. "/" .. options.store.file_name, ".;")

  if file == "" and force then
    file = self:create_file()
  end

  if file == "" then
    return nil
  end

  local is_readable = vim.fn.filereadable(file) == 1
  assert(is_readable, string.format("file not %s readable", file))

  return file
end

function State:import_file()
  self.file = self:find_file()
  return self.file and vim.fn.readfile(self.file) or nil
end

function State:sync(force)
  if not self.file and (State.options.store.auto_create_file or force) then
    self.file = self:create_file()
    assert(self.file, "file not set despite saving")
  elseif not self.file then
    return self
  end

  if vim.fn.filewritable(self.file) then
    vim.fn.writefile(self.tasks, self.file)
  else
    error(string.format("Cannot write file %s", self.file))
  end

  return self
end

function State:current()
  return self.tasks[1]
end

function State:get()
  return self.tasks
end

function State:set(tasks)
  self.tasks = tasks
  return self:sync()
end

function State:count()
  return #self:get()
end

function State:add(str, to_front)
  if to_front then
    table.insert(self.tasks, 1, str)
  else
    table.insert(self.tasks, str)
  end

  return self:sync()
end

function State:shift()
  return table.remove(self.tasks, 1), self:sync()
end

function State:has_items()
  return self:count() > 0
end

return State
