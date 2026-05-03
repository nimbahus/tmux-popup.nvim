local M = {}
local tmux = require("tmux_popup.tmux")

local function start(message)
  return vim.health.start(message)
end

local function ok(message)
  return vim.health.ok(message)
end

local function warn(message)
  return vim.health.warn(message)
end

local function error(message)
  return vim.health.error(message)
end

local function info(message)
  return vim.health.info(message)
end

function M.check()
  start("tmux-popup.nvim")

  local loaded, plugin = pcall(require, "tmux_popup")
  if not loaded then
    error("tmux_popup module could not be loaded")
    return
  end

  local cfg = plugin.config()

  if vim.fn.executable(cfg.tmux_command) == 1 then
    ok(("tmux executable found: %s"):format(cfg.tmux_command))
  else
    error(("tmux executable not found: %s"):format(cfg.tmux_command))
    return
  end

  local version, version_error = tmux.version(cfg.tmux_command)
  if version and tmux.has_display_popup(version) then
    ok(("tmux supports display-popup: %s"):format(version.raw))
  elseif version then
    error(("tmux 3.2+ is required, found: %s"):format(version.raw))
  else
    error(("Could not detect tmux version: %s"):format(version_error or "unknown error"))
  end

  if vim.env.TMUX and vim.env.TMUX ~= "" then
    ok("Neovim is running inside tmux")
  else
    warn("Neovim is not running inside tmux")
  end

  if cfg.theme == "auto" then
    info("theme = auto; popup styles are derived from Neovim highlight groups")
  end

  if cfg.outer_close_keys and #cfg.outer_close_keys > 0 then
    warn("outer_close_keys create global tmux keybindings in the outer tmux session")
  end
end

return M
