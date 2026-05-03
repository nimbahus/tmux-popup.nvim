local util = require("tmux_popup.util")

local M = {}

function M.run(args, opts)
  opts = opts or {}

  local ok, result = pcall(function()
    return vim.system(args, { text = true, env = opts.env }):wait(opts.timeout or 5000)
  end)

  if not ok then
    if opts.check == false then
      return { code = 1, stdout = "", stderr = tostring(result) }
    end

    error(tostring(result), 0)
  end

  if opts.check ~= false and result.code ~= 0 then
    error(util.error_message(result, args), 0)
  end

  return result
end

function M.inner(cfg, args, opts)
  local command = { "env", "-u", "TMUX", cfg.tmux_command, "-L", cfg.socket }
  vim.list_extend(command, args)
  return M.run(command, opts)
end

function M.outer(cfg, args, opts)
  local command = { cfg.tmux_command }
  vim.list_extend(command, args)
  return M.run(command, opts)
end

function M.version(tmux_command)
  local result = M.run({ tmux_command, "-V" }, { check = false })
  if result.code ~= 0 then
    return nil, util.error_message(result, { tmux_command, "-V" })
  end

  local major, minor = result.stdout:match("tmux (%d+)%.(%d+)")
  return {
    raw = vim.trim(result.stdout),
    major = tonumber(major),
    minor = tonumber(minor),
  }
end

function M.has_display_popup(version)
  if not version or not version.major or not version.minor then
    return false
  end

  return version.major > 3 or (version.major == 3 and version.minor >= 2)
end

function M.ensure_outer_close_keys(cfg)
  for _, key in ipairs(cfg.outer_close_keys or {}) do
    M.outer(cfg, { "bind-key", "-n", key, "display-popup", "-C" }, { check = false })
  end
end

function M.ensure_session(state, cfg)
  local exists = M.inner(cfg, { "has-session", "-t", state.session }, { check = false }).code == 0

  if not exists then
    local args = { "new-session", "-d", "-s", state.session, "-c", state.cwd }
    local start_command, err = util.command_string(cfg.start_command)

    if err then
      error(err, 0)
    end

    local created = M.inner(cfg, args, { check = false })
    if created.code ~= 0 and not util.error_message(created, args):match("^duplicate session:") then
      error(util.error_message(created, args), 0)
    end

    if created.code == 0 and start_command then
      M.inner(cfg, { "send-keys", "-t", state.session, "--", start_command, "C-m" })
    end
  end

  if cfg.status ~= nil then
    M.inner(cfg, { "set-option", "-g", "status", util.tmux_value(cfg.status) })
  end
  if cfg.mouse ~= nil then
    M.inner(cfg, { "set-option", "-g", "mouse", util.tmux_value(cfg.mouse) })
  end
  if cfg.prefix then
    M.inner(cfg, { "set-option", "-g", "prefix", cfg.prefix })
  end
  if cfg.default_terminal then
    M.inner(cfg, { "set-option", "-g", "default-terminal", cfg.default_terminal })
  end
  if cfg.terminal_overrides then
    M.inner(cfg, { "set-option", "-as", "terminal-overrides", cfg.terminal_overrides })
  end

  for _, key in ipairs(cfg.close_keys or {}) do
    M.inner(cfg, { "bind-key", "-n", key, "detach-client" })
  end

  for _, key in ipairs(cfg.prefix_close_keys or {}) do
    M.inner(cfg, { "bind-key", key, "detach-client" })
  end
end

function M.display_popup(cfg, state, opts)
  opts = opts or {}

  local attach = util.shell_join({
    "env",
    "-u",
    "TMUX",
    cfg.tmux_command,
    "-L",
    cfg.socket,
    "attach-session",
    "-t",
    state.session,
  })

  local args = {
    cfg.tmux_command,
    "display-popup",
    "-d",
    state.cwd,
    "-w",
    opts.width or cfg.width,
    "-h",
    opts.height or cfg.height,
    "-T",
    opts.title,
  }

  if opts.popup_style then
    vim.list_extend(args, { "-s", opts.popup_style })
  end
  if opts.border_style then
    vim.list_extend(args, { "-S", opts.border_style })
  end

  vim.list_extend(args, { "-E", attach })

  local ok, err = pcall(vim.system, args, { text = true }, function(result)
    if result.code == 0 then
      return
    end

    local message = util.error_message(result, args)
    vim.schedule(function()
      util.notify_error(message ~= "" and message or "failed to open tmux popup")
    end)
  end)

  if not ok then
    return tostring(err)
  end

  return nil
end

function M.kill_session(cfg, state)
  return M.inner(cfg, { "kill-session", "-t", state.session }, { check = false })
end

return M
