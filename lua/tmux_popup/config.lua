local defaults = require("tmux_popup.defaults")
local validate = require("tmux_popup.validate")

local M = {}

local current = vim.deepcopy(defaults)

function M.setup(opts)
  if opts ~= nil and type(opts) ~= "table" then
    error("tmux-popup.nvim setup expects a table or nil", 2)
  end

  local cfg = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  local err = validate.effective(cfg)
  if err then
    error(("tmux-popup.nvim: %s"):format(err), 2)
  end

  current = cfg
  return vim.deepcopy(current)
end

function M.get()
  return vim.deepcopy(current)
end

function M.effective(opts)
  opts = opts or {}
  local cfg = vim.tbl_deep_extend("force", vim.deepcopy(current), opts)

  local err = validate.effective(cfg)
  if err then
    return nil, err
  end

  return cfg
end

function M.defaults()
  return vim.deepcopy(defaults)
end

return M
