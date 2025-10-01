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

# Create symlink with backup
create_symlink() {
    local src="$1"
    local dest="$2"

    if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
        if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
            log_info "Symlink already exists: $dest"
            return 0
        fi
        log_warning "Backing up existing file: $dest -> ${dest}.backup"
        mv "$dest" "${dest}.backup"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    log_success "Created symlink: $dest -> $src"
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

    # Install fish shell (from package manager)
    if ! command -v fish &>/dev/null; then
        install_package "fish" "$platform" "$distro"
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

# Setup configuration files
setup_configs() {
    log_info "Setting up configuration files..."

    # Symlink dotfiles
    if [[ -d "$DOTFILES_DIR" ]]; then
        for file in "$DOTFILES_DIR"/.*; do
            [[ -f "$file" ]] || continue
            local basename="$(basename "$file")"
            [[ "$basename" == "." || "$basename" == ".." ]] && continue
            create_symlink "$file" "$HOME/$basename"
        done
    fi

    # Symlink config directories
    if [[ -d "$CONFIG_DIR" ]]; then
        for dir in "$CONFIG_DIR"/*; do
            [[ -d "$dir" ]] || continue
            local basename="$(basename "$dir")"

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

            create_symlink "$dir" "$HOME/.config/$basename"
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
    fi

    # Setup configurations
    setup_configs

    log_success "Dotfiles installation complete!"
    log_info "Note: You may need to restart your shell or source your rc files"

    # Additional setup instructions
    if ! grep -q "atuin init" "$HOME/.bashrc" 2>/dev/null; then
        log_info "Don't forget to initialize atuin in your shell rc file if needed"
    fi
}

main "$@"
