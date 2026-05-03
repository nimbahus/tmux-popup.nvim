local M = {}

function M.shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function M.shell_join(args)
  local parts = {}

  for _, arg in ipairs(args) do
    table.insert(parts, M.shell_quote(arg))
  end

  return table.concat(parts, " ")
end

function M.sanitize_name(name, fallback)
  local sanitized = tostring(name or ""):gsub("[^%w_-]", "_"):gsub("_+", "_"):gsub("^_+", ""):gsub("_+$", "")
  return sanitized ~= "" and sanitized or (fallback or "terminal")
end

function M.tmux_value(value)
  if value == true then
    return "on"
  elseif value == false then
    return "off"
  end

  return tostring(value)
end

function M.command_value(value)
  if type(value) == "function" then
    local ok, result = pcall(value)
    if not ok then
      return nil, result
    end

    value = result
  end

  if value == nil or value == "" then
    return nil
  end

  if type(value) == "table" then
    local command = {}

    for index, part in ipairs(value) do
      if type(part) ~= "string" or part == "" then
        return nil, ("start_command[%d] must be a non-empty string"):format(index)
      end

      table.insert(command, part)
    end

    if #command == 0 then
      return nil
    end

    return command
  end

  if type(value) ~= "string" then
    return nil, "start_command must be a string, list of strings, function or nil"
  end

  return value
end

function M.command_string(value)
  local command, err = M.command_value(value)
  if err or command == nil then
    return command, err
  end

  if type(command) == "table" then
    return M.shell_join(command)
  end

  return command
end

function M.error_message(result, args)
  local stderr = result and result.stderr or ""
  local stdout = result and result.stdout or ""
  local message = vim.trim(stderr ~= "" and stderr or stdout)

  if message ~= "" then
    return message
  end

  return table.concat(args or {}, " ")
end

function M.notify_error(message)
  vim.notify(("tmux-popup.nvim: %s"):format(message), vim.log.levels.ERROR)
end

return M
