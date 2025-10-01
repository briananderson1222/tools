# Source Omarchy defaults if available (Arch + Hyprland only)
[[ -f ~/.local/share/omarchy/default/zsh/.zshrc ]] && source ~/.local/share/omarchy/default/zsh/.zshrc

# Add Rust/Cargo to PATH
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Add Go to PATH
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

# NVM setup (optional - install location varies by distro)
[[ -f /usr/share/nvm/init-nvm.sh ]] && source /usr/share/nvm/init-nvm.sh &>/dev/null
[[ -f ~/.nvm/nvm.sh ]] && source ~/.nvm/nvm.sh &>/dev/null

# Atuin shell history
[[ -f "$HOME/.atuin/bin/env" ]] && . "$HOME/.atuin/bin/env"
command -v atuin &>/dev/null && eval "$(atuin init zsh)"

# Add your own aliases and functions here
# alias p='python'
