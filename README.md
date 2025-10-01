# Dotfiles

Personal configuration files and setup scripts for Unix-based systems (Linux, macOS, WSL).

## Quick Start

Clone this repository and run the install script:

```bash
git clone https://github.com/briananderson1222/tools.git ~/dev/briananderson1222/tools
cd ~/dev/briananderson1222/tools
./install.sh
```

**Prerequisites:** Only `curl`, `bash`, and `git` are required. The script will install Rust/Cargo and Go automatically if needed.

## What's Included

### Configurations

- **Neovim** - Text editor configuration (LazyVim-based)
- **Tmux** - Terminal multiplexer configuration
- **Waybar** - Status bar for Wayland compositors (Linux Wayland only)
- **Hyprland** - Wayland compositor configuration (Linux Wayland only)
- **Kitty** - Terminal emulator configuration
- **Fish** - Fish shell configuration
- **Bash/Zsh** - Shell configurations with atuin integration
- **Atuin** - Shell history sync configuration

### Tools Automatically Installed

The install script uses a universal installation approach via Cargo and Go, ensuring consistent installations across all platforms.

#### System Packages (via package managers)
- **git** - Version control
- **tmux** - Terminal multiplexer
- **neovim** - Modern Vim-based editor
- **fish** - Friendly interactive shell
- **curl/wget** - Download tools
- **waybar** - Status bar (Linux Wayland only)

#### Rust/Cargo Tools (universal installation)
*The script installs Rust/Cargo automatically if not present*

- **eza** - Modern replacement for `ls`
- **bat** - Better `cat` with syntax highlighting
- **fd** - Modern replacement for `find`
- **ripgrep** (rg) - Faster `grep` alternative
- **starship** - Cross-shell prompt
- **nushell** (nu) - Modern shell (optional, will prompt)

#### Go Tools (universal installation)
*The script installs Go automatically if not present*

- **fzf** - Fuzzy finder for command line
- **carapace** - Universal completion generator
- **sesh** - Tmux session manager

#### Special Installers
- **atuin** - Shell history sync (uses official installer)

## Platform Support

The install script automatically detects your platform and architecture:

### Supported Platforms
- **Linux** (Arch, Ubuntu, Debian, Fedora, Manjaro)
- **macOS** (Intel and Apple Silicon)
- **WSL** (Windows Subsystem for Linux)

### Automatic Platform Detection
- System packages use appropriate package manager (pacman, apt, dnf, brew)
- Rust/Cargo installed via rustup (works everywhere)
- Go installed from official binaries (auto-detects architecture)
- Wayland-specific configs (Waybar, Hyprland) only on Wayland systems

## Installation Process

When you run `./install.sh`, it will:

1. **Detect your platform** (Linux/macOS/WSL) and distribution
2. **Prompt to install tools** (optional)
3. **Install Rust/Cargo** if not present (automatic)
4. **Install Go** if not present (automatic)
5. **Install all CLI tools** via cargo/go (universal)
6. **Install system packages** via your package manager
7. **Create symlinks** for all config files
8. **Backup existing files** with `.backup` extension

## Manual Usage

### Installing Tools Only

```bash
./install.sh
# Answer 'y' when prompted to install tools
```

### Updating Existing Installation

```bash
cd ~/dev/briananderson1222/tools
git pull
./install.sh
```

The script is idempotent - it safely re-runs and updates everything.

### Syncing Your Changes Back to Repo

When you update your configurations locally, sync them back:

```bash
cd ~/dev/briananderson1222/tools

# Copy updated configs (these are symlinked, so may already be up to date)
cp -r ~/.config/nvim config/
cp -r ~/.config/waybar config/
cp -r ~/.config/hypr config/
cp -r ~/.config/kitty config/
cp -r ~/.config/atuin config/
cp -r ~/.config/fish config/
cp ~/.tmux.conf dotfiles/
cp ~/.bashrc dotfiles/
cp ~/.bash_profile dotfiles/

# Commit and push
git add .
git commit -m "Update configs"
git push
```

**Note:** Since the install script creates symlinks, many config changes are automatically reflected in this repo. You only need to copy files if you've recreated them rather than edited them in place.

## Repository Structure

```
.
├── install.sh          # Main installation script with platform detection
├── README.md           # This file
├── .gitignore         # Excludes sensitive data and generated files
├── config/            # XDG config files (~/.config/)
│   ├── nvim/         # Neovim configuration (LazyVim)
│   ├── waybar/       # Waybar status bar config
│   ├── hypr/         # Hyprland compositor config
│   ├── kitty/        # Kitty terminal config
│   ├── atuin/        # Atuin shell history config
│   └── fish/         # Fish shell config
└── dotfiles/          # Home directory dotfiles
    ├── .tmux.conf    # Tmux configuration
    ├── .bashrc       # Bash configuration
    ├── .bash_profile # Bash profile
    ├── .bash-preexec.sh # Atuin integration for bash
    └── .zshrc        # Zsh configuration
```

## Environment Setup

After installation, ensure these are in your shell profile:

### For Bash (~/.bashrc)
```bash
# Rust/Cargo
source "$HOME/.cargo/env"

# Go binaries
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

# Atuin
source "$HOME/.atuin/bin/env"
eval "$(atuin init bash)"
```

### For Zsh (~/.zshrc)
```zsh
# Rust/Cargo
source "$HOME/.cargo/env"

# Go binaries
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

# Atuin
eval "$(atuin init zsh)"
```

### For Fish (~/.config/fish/config.fish)
```fish
# Rust/Cargo
source "$HOME/.cargo/env.fish"

# Go binaries
fish_add_path /usr/local/go/bin
fish_add_path $HOME/go/bin

# Atuin
atuin init fish | source
```

Most of these are already included in the dotfiles provided.

## Troubleshooting

### "cargo: command not found" after install
```bash
source "$HOME/.cargo/env"
```

### "go: command not found" after install
```bash
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
```

### Neovim plugins not loading
Open neovim and run:
```vim
:Lazy sync
```

### Permission denied on install
Ensure the script is executable:
```bash
chmod +x install.sh
```

### Symlink conflicts
The script automatically backs up existing files with `.backup` extension. Check these files if you need to restore anything.

## Notes

- **Symlinks**: The script creates symlinks, so editing configs in `~/.config/` automatically updates this repo
- **Backups**: Existing files are backed up with `.backup` extension before being replaced
- **Idempotent**: Safe to run multiple times - it won't reinstall existing tools
- **No sudo for most tools**: Cargo/Go tools install to user directory, no root needed
- **Restart shell**: After installation, restart your shell or source your rc file for changes to take effect

## Customization

Feel free to edit `install.sh` to:
- Add/remove tools from the installation list
- Change which configs are symlinked
- Add custom post-installation steps
- Modify platform-specific behavior

## License

Personal dotfiles - use as you wish!
