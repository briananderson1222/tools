#!/usr/bin/env bash

# Two-way sync script for dotfiles
# Usage: ./sync.sh [import|export]

set -e

# Check bash version (need 4.0+ for associative arrays)
if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "Error: This script requires bash 4.0 or higher"
    echo "Current version: $BASH_VERSION"
    echo ""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS ships with bash 3.2. Install a newer version:"
        echo "  brew install bash"
        echo ""
        echo "Then run with bash 4+:"
        echo "  # Apple Silicon:"
        echo "  /opt/homebrew/bin/bash sync.sh [import|export]"
        echo "  # Intel Mac:"
        echo "  /usr/local/bin/bash sync.sh [import|export]"
        echo "  # Or add to PATH and use:"
        echo "  bash sync.sh [import|export]"
    fi
    exit 1
fi

# Check for rsync
if ! command -v rsync &>/dev/null; then
    echo "Error: rsync is required but not installed"
    echo ""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS should have rsync pre-installed. Please check your installation."
    elif [[ -f /etc/arch-release ]]; then
        echo "Install with: sudo pacman -S rsync"
    elif command -v apt-get &>/dev/null; then
        echo "Install with: sudo apt-get install rsync"
    else
        echo "Please install rsync using your package manager"
    fi
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configs to sync (source -> destination)
declare -A CONFIG_DIRS=(
    ["nvim"]="$HOME/.config/nvim"
    ["waybar"]="$HOME/.config/waybar"
    ["hypr"]="$HOME/.config/hypr"
    ["atuin"]="$HOME/.config/atuin"
    ["nushell"]="$HOME/.config/nushell"
)

# Dotfiles to sync
declare -A DOTFILES=(
    [".tmux.conf"]="$HOME/.tmux.conf"
    [".bashrc"]="$HOME/.bashrc"
    [".bash_profile"]="$HOME/.bash_profile"
    [".bash-preexec.sh"]="$HOME/.bash-preexec.sh"
    [".zshrc"]="$HOME/.zshrc"
)

# Files to exclude from sync (patterns)
EXCLUDE_PATTERNS=(
    "*.lock"
    "*.log"
    ".DS_Store"
    "lazy-lock.json"
    "plugin/"
    "*.sqlite*"
    "session.txt"
    "README.md"
    "*-receipt.json"
)

# Build rsync exclude args
build_exclude_args() {
    local args=""
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        args="$args --exclude=$pattern"
    done
    echo "$args"
}

# Import configs from system to repo
import_configs() {
    log_info "Importing configs from system to repo..."
    local exclude_args=$(build_exclude_args)

    # Sync config directories
    for config_name in "${!CONFIG_DIRS[@]}"; do
        local src="${CONFIG_DIRS[$config_name]}"
        local dest="$CONFIG_DIR/$config_name"

        if [[ -d "$src" ]]; then
            log_info "Importing $config_name: $src -> $dest"
            mkdir -p "$dest"
            rsync -av --delete $exclude_args "$src/" "$dest/"
            log_success "Imported $config_name"
        else
            log_warning "$src does not exist, skipping"
        fi
    done

    # Sync dotfiles
    for dotfile in "${!DOTFILES[@]}"; do
        local src="${DOTFILES[$dotfile]}"
        local dest="$DOTFILES_DIR/$dotfile"

        if [[ -f "$src" ]]; then
            log_info "Importing $dotfile: $src -> $dest"
            cp "$src" "$dest"
            log_success "Imported $dotfile"
        else
            log_warning "$src does not exist, skipping"
        fi
    done

    # Handle generated configs specially (import from actual config)
    if [[ -f "$HOME/.config/ghostty/config" ]]; then
        log_info "Backing up generated ghostty config"
        mkdir -p "$CONFIG_DIR/ghostty/examples"
        cp "$HOME/.config/ghostty/config" "$CONFIG_DIR/ghostty/examples/generated-config-example"
        log_success "Saved ghostty config as example"
    fi

    log_success "Import complete!"
}

# Export configs from repo to system
export_configs() {
    log_info "Exporting configs from repo to system..."
    local exclude_args=$(build_exclude_args)

    # Sync config directories
    for config_name in "${!CONFIG_DIRS[@]}"; do
        local src="$CONFIG_DIR/$config_name"
        local dest="${CONFIG_DIRS[$config_name]}"

        # Skip template directories
        if [[ "$config_name" == "ghostty" ]]; then
            log_info "Skipping ghostty (use install.sh to generate)"
            continue
        fi

        if [[ -d "$src" ]]; then
            log_info "Exporting $config_name: $src -> $dest"
            mkdir -p "$dest"

            # Backup existing config
            if [[ -d "$dest" ]] && [[ ! -L "$dest" ]]; then
                local backup="$dest.backup.$(date +%Y%m%d_%H%M%S)"
                log_warning "Backing up existing config to $backup"
                cp -r "$dest" "$backup"
            fi

            rsync -av --delete $exclude_args "$src/" "$dest/"
            log_success "Exported $config_name"
        else
            log_warning "$src does not exist in repo, skipping"
        fi
    done

    # Sync dotfiles
    for dotfile in "${!DOTFILES[@]}"; do
        local src="$DOTFILES_DIR/$dotfile"
        local dest="${DOTFILES[$dotfile]}"

        if [[ -f "$src" ]]; then
            # Backup existing file
            if [[ -f "$dest" ]]; then
                local backup="$dest.backup.$(date +%Y%m%d_%H%M%S)"
                log_warning "Backing up existing file to $backup"
                cp "$dest" "$backup"
            fi

            log_info "Exporting $dotfile: $src -> $dest"
            cp "$src" "$dest"
            log_success "Exported $dotfile"
        else
            log_warning "$src does not exist in repo, skipping"
        fi
    done

    log_success "Export complete!"
    log_info "Note: Generated configs (ghostty) require running install.sh"
}

# Show usage
usage() {
    cat << EOF
Usage: $0 [import|export]

Commands:
  import    Import configs from your system into this repo
  export    Export configs from this repo to your system

Examples:
  $0 import     # Save your current system configs to the repo
  $0 export     # Deploy repo configs to your system

Notes:
  - import: Updates the repo with your current system configs
  - export: Deploys repo configs to your system (with backups)
  - Generated configs (ghostty) require running install.sh to regenerate
EOF
}

# Main
main() {
    case "${1:-}" in
        import)
            import_configs
            ;;
        export)
            export_configs
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
