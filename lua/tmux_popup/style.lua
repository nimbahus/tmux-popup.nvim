local M = {}

local function hex(value)
  if not value then
    return nil
  end

  return ("#%06x"):format(value)
end

local function from_hl(group)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if not ok or not hl then
    return nil
  end

  local style = {}
  if hl.fg then
    table.insert(style, "fg=" .. hex(hl.fg))
  end
  if hl.bg then
    table.insert(style, "bg=" .. hex(hl.bg))
  end

  return #style > 0 and table.concat(style, ",") or nil
end

function M.popup_styles(cfg)
  local popup_style = cfg.popup_style
  local border_style = cfg.border_style

  if cfg.theme == "auto" then
    if popup_style == nil then
      popup_style = from_hl("NormalFloat") or from_hl("Normal")
    elseif popup_style == false then
      popup_style = nil
    end

    if border_style == nil then
      border_style = from_hl("FloatBorder")
    elseif border_style == false then
      border_style = nil
    end
  else
    popup_style = popup_style ~= false and popup_style or nil
    border_style = border_style ~= false and border_style or nil
  end

  return popup_style, border_style
end

return M
