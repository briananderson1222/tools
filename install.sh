#!/bin/bash

# Dotfiles install/update script
# Works on Linux, macOS, and WSL

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect platform
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
        echo "wsl"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# Check if running Wayland
is_wayland() {
    [[ -n "$WAYLAND_DISPLAY" ]] || [[ "$XDG_SESSION_TYPE" == "wayland" ]]
}

# Copy file/directory with backup
copy_config() {
    local src="$1"
    local dest="$2"

    # Backup existing config
    if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
        log_warning "Backing up existing: $dest -> ${dest}.backup"
        mv "$dest" "${dest}.backup"
    fi

    mkdir -p "$(dirname "$dest")"

    if [[ -d "$src" ]]; then
        cp -r "$src" "$dest"
        log_success "Copied directory: $src -> $dest"
    else
        cp "$src" "$dest"
        log_success "Copied file: $src -> $dest"
    fi
}

# Ensure Rust/Cargo is installed
ensure_cargo() {
    if ! command -v cargo &>/dev/null; then
        log_info "Installing Rust/Cargo..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"

        if ! command -v cargo &>/dev/null; then
            log_error "Failed to install cargo"
            return 1
        fi
        log_success "Cargo installed successfully"
    fi
    return 0
}

# Ensure Go is installed
ensure_go() {
    if ! command -v go &>/dev/null; then
        log_info "Installing Go..."
        local platform="$1"
        local go_version="1.23.1"

        case "$platform" in
            macos)
                local go_arch="darwin-arm64"
                [[ $(uname -m) == "x86_64" ]] && go_arch="darwin-amd64"
                ;;
            linux|wsl)
                local go_arch="linux-amd64"
                [[ $(uname -m) == "aarch64" ]] && go_arch="linux-arm64"
                ;;
        esac

        local go_tar="go${go_version}.${go_arch}.tar.gz"
        curl -sSL "https://go.dev/dl/${go_tar}" -o "/tmp/${go_tar}" || return 1
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "/tmp/${go_tar}"
        rm "/tmp/${go_tar}"

        # Add to PATH if not already there
        if [[ ":$PATH:" != *":/usr/local/go/bin:"* ]]; then
            export PATH="$PATH:/usr/local/go/bin"
            export PATH="$PATH:$HOME/go/bin"
        fi

        if ! command -v go &>/dev/null; then
            log_error "Failed to install Go"
            return 1
        fi
        log_success "Go installed successfully"
    fi

    # Ensure GOPATH bin is in PATH
    if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
        export PATH="$PATH:$HOME/go/bin"
    fi

    return 0
}

# Install package based on platform (for system packages only)
install_package() {
    local package="$1"
    local platform="$2"
    local distro="$3"

    log_info "Installing $package..."

    case "$platform" in
        macos)
            if command -v brew &>/dev/null; then
                brew install "$package" || log_warning "Failed to install $package"
            else
                log_warning "Homebrew not found. Please install manually: $package"
            fi
            ;;
        linux|wsl)
            case "$distro" in
                arch|manjaro)
                    sudo pacman -S --noconfirm "$package" 2>/dev/null || \
                        yay -S --noconfirm "$package" 2>/dev/null || \
                        log_warning "Failed to install $package"
                    ;;
                ubuntu|debian)
                    sudo apt-get update && sudo apt-get install -y "$package" || \
                        log_warning "Failed to install $package"
                    ;;
                fedora|rhel|centos)
                    sudo dnf install -y "$package" || \
                        log_warning "Failed to install $package"
                    ;;
                *)
                    log_warning "Unknown distro. Please install manually: $package"
                    ;;
            esac
            ;;
    esac
}

# Install via cargo
install_cargo_package() {
    local package="$1"
    local binary_name="${2:-$package}"

    if ! command -v "$binary_name" &>/dev/null; then
        log_info "Installing $package via cargo..."
        if ensure_cargo; then
            cargo install "$package" || log_warning "Failed to install $package via cargo"
        fi
    else
        log_info "$binary_name already installed"
    fi
}

# Install via go
install_go_package() {
    local package="$1"
    local binary_name="$2"
    local platform="$3"

    if ! command -v "$binary_name" &>/dev/null; then
        log_info "Installing $package via go..."
        if ensure_go "$platform"; then
            go install "$package"@latest || log_warning "Failed to install $package via go"
        fi
    else
        log_info "$binary_name already installed"
    fi
}

# Install tools
install_tools() {
    local platform="$1"
    local distro="$2"

    log_info "Installing essential tools..."

    # Install system packages (better from package managers)
    local system_tools=("tmux" "git" "curl" "wget" "build-essential")

    for tool in "${system_tools[@]}"; do
        # Skip build-essential on non-Debian systems
        if [[ "$tool" == "build-essential" && "$distro" != "ubuntu" && "$distro" != "debian" ]]; then
            continue
        fi

        if ! command -v "$tool" &>/dev/null; then
            install_package "$tool" "$platform" "$distro"
        else
            log_info "$tool already installed"
        fi
    done

    # Install neovim (prefer package manager for dependencies)
    if ! command -v nvim &>/dev/null; then
        case "$platform" in
            macos)
                install_package "neovim" "$platform" "$distro"
                ;;
            linux|wsl)
                if [[ "$distro" == "arch" || "$distro" == "manjaro" ]]; then
                    install_package "neovim" "$platform" "$distro"
                else
                    # For Ubuntu/Debian, use AppImage or PPA for latest version
                    log_info "Installing neovim..."
                    install_package "neovim" "$platform" "$distro" || \
                        log_warning "Consider installing from https://github.com/neovim/neovim/releases"
                fi
                ;;
        esac
    fi

    # Install Rust-based tools via cargo (universal across platforms)
    log_info "Installing Rust-based CLI tools..."

    # eza (modern ls)
    install_cargo_package "eza" "eza"

    # bat (better cat)
    install_cargo_package "bat" "bat"

    # fd (better find)
    install_cargo_package "fd-find" "fd"

    # ripgrep (better grep)
    install_cargo_package "ripgrep" "rg"

    # starship (cross-shell prompt) - optional but nice
    if ! command -v starship &>/dev/null; then
        log_info "Installing starship prompt..."
        if ensure_cargo; then
            curl -sS https://starship.rs/install.sh | sh -s -- -y || \
                log_warning "Failed to install starship"
        fi
    fi

    # Install Go-based tools
    log_info "Installing Go-based CLI tools..."

    # fzf (fuzzy finder)
    install_go_package "github.com/junegunn/fzf" "fzf" "$platform"

    # carapace (universal completion)
    install_go_package "github.com/carapace-sh/carapace-bin/cmd/carapace" "carapace" "$platform"

    # sesh (tmux session manager) - if you use it
    if ! command -v sesh &>/dev/null; then
        log_info "Installing sesh (tmux session manager)..."
        if ensure_go "$platform"; then
            go install github.com/joshmedeski/sesh@latest || \
                log_warning "Failed to install sesh"
        fi
    fi

    # Install atuin (shell history) - has its own installer
    if ! command -v atuin &>/dev/null; then
        log_info "Installing atuin..."
        bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh) || \
            log_warning "Failed to install atuin"
    fi

    # Install nushell (modern shell) via cargo
    if ! command -v nu &>/dev/null; then
        read -p "Install nushell? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_cargo_package "nu" "nu"
        fi
    fi

    # Install NVM (Node Version Manager)
    if [[ ! -d "$HOME/.nvm" ]] && ! command -v nvm &>/dev/null; then
        log_info "Installing NVM (Node Version Manager)..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash || \
            log_warning "Failed to install NVM"

        # Source NVM to make it available immediately
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        log_info "NVM already installed"
    fi

    # Install UV (fast Python package manager)
    if ! command -v uv &>/dev/null; then
        log_info "Installing UV (Python package manager)..."
        curl -LsSf https://astral.sh/uv/install.sh | sh || \
            log_warning "Failed to install UV"
    else
        log_info "UV already installed"
    fi

    # Platform-specific tools
    if [[ "$platform" == "linux" ]] && is_wayland; then
        # Install waybar (Wayland bar)
        if ! command -v waybar &>/dev/null; then
            log_info "Installing waybar (Wayland detected)..."
            install_package "waybar" "$platform" "$distro"
        fi
    fi

    log_success "Tool installation complete!"
}

# Install JetBrainsMono Nerd Font
install_nerd_font() {
    local platform="$1"
    local distro="$2"

    log_info "Installing JetBrainsMono Nerd Font..."

    case "$platform" in
        macos)
            if command -v brew &>/dev/null; then
                brew install --cask font-jetbrains-mono-nerd-font || \
                    log_warning "Failed to install JetBrainsMono Nerd Font"
            else
                log_warning "Homebrew not found. Install from: https://www.nerdfonts.com/font-downloads"
            fi
            ;;
        linux|wsl)
            local font_dir="$HOME/.local/share/fonts"
            local font_installed=false

            # Check if font already installed
            if fc-list | grep -qi "JetBrainsMono Nerd Font"; then
                log_info "JetBrainsMono Nerd Font already installed"
                return
            fi

            # Install via package manager if available
            case "$distro" in
                arch|manjaro)
                    sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd 2>/dev/null || \
                        yay -S --noconfirm ttf-jetbrains-mono-nerd 2>/dev/null && font_installed=true
                    ;;
            esac

            # If not installed via package manager, download manually
            if [[ "$font_installed" == false ]]; then
                log_info "Downloading JetBrainsMono Nerd Font..."
                mkdir -p "$font_dir"
                local tmp_dir=$(mktemp -d)

                curl -fLo "$tmp_dir/JetBrainsMono.zip" \
                    https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip || {
                    log_warning "Failed to download font"
                    rm -rf "$tmp_dir"
                    return 1
                }

                unzip -q "$tmp_dir/JetBrainsMono.zip" -d "$font_dir/JetBrainsMono" || {
                    log_warning "Failed to extract font"
                    rm -rf "$tmp_dir"
                    return 1
                }

                rm -rf "$tmp_dir"
                fc-cache -fv "$font_dir" >/dev/null 2>&1
                log_success "JetBrainsMono Nerd Font installed"
            fi
            ;;
    esac
}

# Detect user's preferred shell
detect_shell() {
    local shells=()

    # Check for available shells
    command -v bash &>/dev/null && shells+=("bash")
    command -v zsh &>/dev/null && shells+=("zsh")
    command -v nu &>/dev/null && shells+=("nu")

    # Return current shell if available
    local current_shell=$(basename "$SHELL")
    for shell in "${shells[@]}"; do
        if [[ "$shell" == "$current_shell" ]]; then
            echo "$current_shell"
            return
        fi
    done

    # Otherwise return first available
    echo "${shells[0]:-bash}"
}

# Get shell path
get_shell_path() {
    local shell="$1"
    command -v "$shell" 2>/dev/null || echo "/bin/$shell"
}

# Generate ghostty config
generate_ghostty_config() {
    local shell="$1"
    local platform="$2"

    local template_file="$CONFIG_DIR/ghostty/templates/config.template"
    local output_file="$HOME/.config/ghostty/config"

    if [[ ! -f "$template_file" ]]; then
        log_warning "Ghostty template not found, skipping"
        return
    fi

    log_info "Generating ghostty config for shell: $shell"

    # Get shell path
    local shell_path=$(get_shell_path "$shell")

    # Platform-specific defaults
    local font_size="9"
    local theme_config='config-file = ?"~/.config/omarchy/current/theme/ghostty.conf"'

    case "$platform" in
        macos)
            font_size="13"
            theme_config="# No theme config for macOS"
            ;;
    esac

    # Generate config from template
    mkdir -p "$(dirname "$output_file")"
    sed -e "s|{{SHELL_PATH}}|$shell_path|g" \
        -e "s|{{FONT_SIZE}}|$font_size|g" \
        -e "s|{{THEME_CONFIG}}|$theme_config|g" \
        "$template_file" > "$output_file"

    log_success "Generated ghostty config: $output_file"
}

# Setup configuration files
setup_configs() {
    local platform="$1"

    log_info "Setting up configuration files..."

    # Detect preferred shell
    local preferred_shell=$(detect_shell)
    log_info "Detected shell: $preferred_shell"

    read -p "Use $preferred_shell as default shell? (y/n, or specify: bash/zsh/nu) " -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$REPLY" =~ ^(bash|zsh|nu)$ ]]; then
            preferred_shell="$REPLY"
        fi
    fi

    # Generate dynamic configs
    generate_ghostty_config "$preferred_shell" "$platform"

    # Copy dotfiles
    if [[ -d "$DOTFILES_DIR" ]]; then
        for file in "$DOTFILES_DIR"/.*; do
            [[ -f "$file" ]] || continue
            local basename="$(basename "$file")"
            [[ "$basename" == "." || "$basename" == ".." ]] && continue
            copy_config "$file" "$HOME/$basename"
        done
    fi

    # Copy config directories
    if [[ -d "$CONFIG_DIR" ]]; then
        for dir in "$CONFIG_DIR"/*; do
            [[ -d "$dir" ]] || continue
            local basename="$(basename "$dir")"

            # Skip templates directory
            if [[ "$basename" == "templates" ]]; then
                continue
            fi

            # Skip ghostty since we generate it
            if [[ "$basename" == "ghostty" ]]; then
                continue
            fi

            # Skip waybar on non-Wayland systems
            if [[ "$basename" == "waybar" ]] && ! is_wayland; then
                log_info "Skipping waybar (not on Wayland)"
                continue
            fi

            # Skip hypr on non-Wayland systems
            if [[ "$basename" == "hypr" ]] && ! is_wayland; then
                log_info "Skipping hyprland config (not on Wayland)"
                continue
            fi

            copy_config "$dir" "$HOME/.config/$basename"
        done
    fi
}

# Main installation
main() {
    log_info "Starting dotfiles installation..."

    local platform=$(detect_platform)
    local distro=$(detect_distro)

    log_info "Platform: $platform"
    [[ "$platform" == "linux" || "$platform" == "wsl" ]] && log_info "Distribution: $distro"

    # Ask user if they want to install tools
    read -p "Install/update tools? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_tools "$platform" "$distro"
        install_nerd_font "$platform" "$distro"
    fi

    # Setup configurations
    setup_configs "$platform"

    log_success "Dotfiles installation complete!"
    log_info "Note: You may need to restart your shell or source your rc files"

    # Additional setup instructions
    if ! grep -q "atuin init" "$HOME/.bashrc" 2>/dev/null; then
        log_info "Don't forget to initialize atuin in your shell rc file if needed"
    fi
}

main "$@"
