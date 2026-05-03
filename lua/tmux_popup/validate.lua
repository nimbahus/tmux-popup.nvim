local M = {}

local valid_scopes = {
  cwd = true,
  global = true,
  project = true,
}

local function is_array(value)
  if type(value) ~= "table" then
    return false
  end

  local seen = 0
  for key, _ in pairs(value) do
    if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
      return false
    end

    seen = seen + 1
  end

  return seen == #value
end

local function string_array(name, value)
  if value == nil then
    return nil
  end

  if not is_array(value) then
    return ("%s must be a list of strings"):format(name)
  end

  for index, item in ipairs(value) do
    if type(item) ~= "string" or item == "" then
      return ("%s[%d] must be a non-empty string"):format(name, index)
    end
  end

  return nil
end

local function string_or_number(name, value)
  if type(value) == "string" or type(value) == "number" then
    return nil
  end

  return ("%s must be a string or number"):format(name)
end

local function start_command(value)
  if value == nil or type(value) == "string" or type(value) == "function" then
    return nil
  end

  return string_array("start_command", value)
end

function M.effective(cfg)
  local err = string_or_number("width", cfg.width)
    or string_or_number("height", cfg.height)
    or string_array("close_keys", cfg.close_keys)
    or string_array("outer_close_keys", cfg.outer_close_keys)
    or string_array("prefix_close_keys", cfg.prefix_close_keys)
    or string_array("root_markers", cfg.root_markers)
    or start_command(cfg.start_command)

  if err then
    return err
  end

  if cfg.command ~= nil and cfg.command ~= false and type(cfg.command) ~= "string" then
    return "command must be a string, false or nil"
  end

  if type(cfg.command) == "string" and cfg.command ~= "" and not cfg.command:match("^%u[%w]*$") then
    return "command must be a valid Neovim user command name, like TerminalPopup"
  end

  if cfg.keymap ~= nil and type(cfg.keymap) ~= "string" then
    return "keymap must be a string or nil"
  end

  if cfg.name ~= nil and (type(cfg.name) ~= "string" or cfg.name == "") then
    return "name must be a non-empty string or nil"
  end

  if not valid_scopes[cfg.scope] then
    return "scope must be one of: project, cwd, global"
  end

  if type(cfg.socket) ~= "string" or cfg.socket == "" then
    return "socket must be a non-empty string"
  end

  if type(cfg.session_prefix) ~= "string" or cfg.session_prefix == "" then
    return "session_prefix must be a non-empty string"
  end

  if type(cfg.tmux_command) ~= "string" or cfg.tmux_command == "" then
    return "tmux_command must be a non-empty string"
  end

  if type(cfg.title) ~= "string" or cfg.title == "" then
    return "title must be a non-empty string"
  end

  if cfg.popup_style ~= nil and cfg.popup_style ~= false and type(cfg.popup_style) ~= "string" then
    return "popup_style must be a string, false or nil"
  end

  if cfg.border_style ~= nil and cfg.border_style ~= false and type(cfg.border_style) ~= "string" then
    return "border_style must be a string, false or nil"
  end

  return nil
end

return M
