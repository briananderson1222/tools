# Source Omarchy defaults if available (Arch + Hyprland only)
[[ -f ~/.local/share/omarchy/default/zsh/.zshrc ]] && source ~/.local/share/omarchy/default/zsh/.zshrc

# Add Rust/Cargo to PATH
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Add Go to PATH
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

# NVM setup (install location varies by distro/install method)
export NVM_DIR="$HOME/.nvm"
[[ -f /usr/share/nvm/init-nvm.sh ]] && source /usr/share/nvm/init-nvm.sh &>/dev/null
[[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"

# UV (Python package manager)
[[ -f "$HOME/.cargo/bin/uv" ]] && export PATH="$HOME/.cargo/bin:$PATH"

# Atuin shell history
[[ -f "$HOME/.atuin/bin/env" ]] && . "$HOME/.atuin/bin/env"
command -v atuin &>/dev/null && eval "$(atuin init zsh)"

# Add your own aliases and functions here
# alias p='python'
