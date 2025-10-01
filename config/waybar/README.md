# Waybar Configuration

**Note:** This config is designed for Wayland systems, specifically tested with Hyprland on Arch Linux.

## Platform Requirements

- **Display Server:** Wayland
- **Compositor:** Hyprland (or other wlroots-based compositors)
- **Font:** Omarchy icon font (for custom icons)

## Omarchy Integration

The config uses the Omarchy icon font for custom widgets. If you don't have Omarchy installed, you may see missing icons.

## Using Without Omarchy

Replace the Omarchy icon references in `config.jsonc`:
```jsonc
// Current (uses Omarchy font)
"format": "<span font='omarchy'>\ue900</span>",

// Replace with standard unicode or nerd font icons
"format": "󰍹",
```
