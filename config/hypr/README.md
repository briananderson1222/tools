# Hyprland Configuration

**Note:** These configs are designed for Arch Linux with the Omarchy theme system.

## Omarchy Integration

The configs source Omarchy defaults and themes:
- Hyprland config sources `~/.local/share/omarchy/default/hypr/*`
- Theme integration via `~/.config/omarchy/current/theme/`

## Using Without Omarchy

If you're not using Omarchy:
1. Remove or comment out Omarchy `source` lines in `hyprland.conf`
2. Provide your own theme configurations
3. Update bindings in `bindings.conf` to remove Omarchy-specific commands

## Platform Requirements

- **OS:** Arch Linux, Manjaro (or other Arch-based)
- **Display Server:** Wayland
- **Compositor:** Hyprland
- **Theme System:** Omarchy (optional but recommended)
