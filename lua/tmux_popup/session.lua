local util = require("tmux_popup.util")

local M = {}

local function normalize_dir(cwd)
  cwd = vim.fs.normalize(vim.fn.fnamemodify(cwd, ":p"))

  local stat = vim.uv.fs_stat(cwd)
  if stat and stat.type == "file" then
    cwd = vim.fs.dirname(cwd)
  elseif not stat or stat.type ~= "directory" then
    cwd = vim.fn.getcwd()
  end

  return cwd
end

local function project_dir(cfg)
  local name = vim.api.nvim_buf_get_name(0)
  local start = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd() or vim.fn.getcwd()

  return vim.fs.root(start, cfg.root_markers) or vim.fn.getcwd()
end

function M.resolve_cwd(cfg, cwd)
  if cwd and cwd ~= "" then
    return normalize_dir(cwd)
  end

  if cfg.scope == "cwd" then
    return normalize_dir(vim.fn.getcwd())
  end

  return normalize_dir(project_dir(cfg))
end

function M.for_cwd(cwd, cfg)
  cwd = normalize_dir(cwd)

  local prefix = util.sanitize_name(cfg.session_prefix, "nvim")
  local custom_name = cfg.name and util.sanitize_name(cfg.name) or nil
  local scope = cfg.scope or "project"
  local base = util.sanitize_name(vim.fs.basename(cwd))
  local hash = vim.fn.sha256(cwd):sub(1, 8)

  if scope == "global" then
    local name = custom_name or "terminal"

    return {
      cwd = cwd,
      name = name,
      scope = scope,
      session = ("%s-%s"):format(prefix, name),
    }
  end

  local name_parts = { base }
  if custom_name then
    table.insert(name_parts, custom_name)
  end

  local session_parts = { prefix }
  vim.list_extend(session_parts, name_parts)
  table.insert(session_parts, hash)

  return {
    cwd = cwd,
    name = table.concat(name_parts, "-"),
    scope = scope,
    session = table.concat(session_parts, "-"),
  }
end

function M.title(state, cfg)
  local close = table.concat(cfg.close_keys or {}, "/")

  return (
    cfg.title
      :gsub("{name}", state.name)
      :gsub("{session}", state.session)
      :gsub("{scope}", state.scope or "")
      :gsub("{close}", close)
  )
end

return M
