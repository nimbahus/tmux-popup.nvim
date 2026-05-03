local config = require("tmux_popup.config")
local session = require("tmux_popup.session")
local style = require("tmux_popup.style")
local tmux = require("tmux_popup.tmux")
local util = require("tmux_popup.util")

local M = {}

function M.open(opts)
  if type(opts) == "string" then
    opts = { name = opts }
  end

  opts = opts or {}
  if type(opts) ~= "table" then
    util.notify_error("open() expects a table, string or nil")
    return
  end

  local cfg, err = config.effective(opts)
  if not cfg then
    util.notify_error(err)
    return
  end

  if vim.fn.executable(cfg.tmux_command) ~= 1 then
    util.notify_error(("missing executable: %s"):format(cfg.tmux_command))
    return
  end

  if not vim.env.TMUX or vim.env.TMUX == "" then
    util.notify_error("not inside tmux")
    return
  end

  local state = session.for_cwd(session.resolve_cwd(cfg, opts.cwd or cfg.cwd), cfg)
  local ok, prepare_err = pcall(function()
    tmux.ensure_outer_close_keys(cfg)
    tmux.ensure_session(state, cfg)
  end)

  if not ok then
    util.notify_error(("failed to prepare popup: %s"):format(prepare_err))
    return
  end

  local popup_style, border_style = style.popup_styles(cfg)
  local display_err = tmux.display_popup(cfg, state, {
    border_style = border_style,
    height = opts.height,
    popup_style = popup_style,
    title = opts.title or session.title(state, cfg),
    width = opts.width,
  })

  if display_err then
    util.notify_error(display_err)
  end
end

function M.kill(opts)
  if type(opts) == "string" then
    opts = { name = opts }
  end

  opts = opts or {}
  if type(opts) ~= "table" then
    util.notify_error("kill() expects a table, string or nil")
    return
  end

  local cfg, err = config.effective(opts)
  if not cfg then
    util.notify_error(err)
    return
  end

  if vim.fn.executable(cfg.tmux_command) ~= 1 then
    return
  end

  local state = session.for_cwd(session.resolve_cwd(cfg, opts.cwd or cfg.cwd), cfg)
  tmux.kill_session(cfg, state)
end

function M.config()
  return config.get()
end

function M.setup(opts)
  local cfg = config.setup(opts)

  if cfg.command and cfg.command ~= "" then
    vim.api.nvim_create_user_command(cfg.command, function(command_opts)
      M.open({ cwd = command_opts.args ~= "" and vim.fn.expand(command_opts.args) or nil })
    end, {
      complete = "dir",
      desc = "Open persistent tmux popup terminal",
      force = true,
      nargs = "?",
    })

    vim.api.nvim_create_user_command(cfg.command .. "Kill", function(command_opts)
      M.kill({ cwd = command_opts.args ~= "" and vim.fn.expand(command_opts.args) or nil })
    end, {
      complete = "dir",
      desc = "Kill persistent tmux popup terminal",
      force = true,
      nargs = "?",
    })
  end

  if cfg.keymap then
    vim.keymap.set("n", cfg.keymap, function()
      M.open()
    end, { silent = true, desc = "Terminal popup" })
  end
end

return M
