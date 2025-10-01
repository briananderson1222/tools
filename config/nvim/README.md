# Neovim Configuration

LazyVim-based configuration.

## Omarchy Theme Integration

On Arch Linux with Omarchy + Hyprland, the theme is managed by Omarchy:

```bash
# Create symlink to Omarchy theme (Arch + Hyprland only)
ln -sf ~/.config/omarchy/current/theme/neovim.lua \
       ~/.config/nvim/lua/plugins/theme.lua
```

This symlink is gitignored and needs to be recreated on Omarchy systems.

## Non-Omarchy Systems

Edit `lua/plugins/theme.lua` to configure your preferred colorscheme.

Example themes:
- Tokyonight: Already available in LazyVim
- Catppuccin: Add to `lua/plugins/theme.lua`
- Default: Returns empty config to use LazyVim defaults
