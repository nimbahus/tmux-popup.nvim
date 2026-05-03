# tmux-popup.nvim

Persistent tmux popup terminals for Neovim.

`tmux-popup.nvim` opens a real tmux `display-popup` from Neovim. Closing the
popup only detaches the tmux client, so the shell keeps running and is reused
the next time you open it.

- no tmux plugin required
- no Neovim terminal buffer to manage
- uses your normal `.tmux.conf`
- configured from Lua

## Requirements

- Neovim 0.10+
- tmux 3.2+

## Install

```lua
vim.pack.add({
  { src = "https://github.com/nimbahus/tmux-popup.nvim" },
})
```

```lua
require("tmux_popup").setup({
  keymap = "<leader>tt",
})
```

## Use

```vim
:TerminalPopup
:TerminalPopupKill
```

Both commands accept an optional directory:

```vim
:TerminalPopup ~/projects/app
:TerminalPopupKill ~/projects/app
```

Default close keys:

- `Ctrl-g`
- `F12`
- `prefix + d`
- `prefix + q`

If close keys do not reach the popup in your nested tmux setup:

```lua
require("tmux_popup").setup({
  keymap = "<leader>tt",
  outer_close_keys = { "C-g" },
})
```

## Lua API

```lua
require("tmux_popup").open()
require("tmux_popup").kill()
```

Create your own keymaps by passing options to `open()`:

```lua
vim.keymap.set("n", "<leader>tg", function()
  require("tmux_popup").open({
    name = "git",
    start_command = "lazygit",
  })
end)
```

`name` creates a separate persistent session. `start_command` is sent to the
session's shell only when that session is first created. When the command exits,
the shell stays open.

## Options

```lua
require("tmux_popup").setup({
  keymap = "<leader>tt",
  width = "90%",
  height = "85%",
  scope = "project", -- "project", "cwd" or "global"
  theme = "auto",
  popup_style = nil,
  border_style = nil,
})
```

`theme = "auto"` derives popup colors from Neovim highlight groups. Override
tmux styles directly when needed:

```lua
require("tmux_popup").setup({
  popup_style = "fg=#ffffff,bg=#16181a",
  border_style = "fg=#5ea1ff,bg=#16181a",
})
```

## Health

```vim
:checkhealth tmux_popup
```

## License

MIT
