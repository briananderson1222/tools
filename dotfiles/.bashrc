# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
source /usr/share/nvm/init-nvm.sh &>/dev/null
#
# Make an alias for invoking commands you use constantly
# alias p='python'

. "$HOME/.atuin/bin/env"

[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
eval "$(atuin init bash)"

. "$HOME/.local/share/../bin/env"

# Claude Code alias with 10-minute bash timeout
alias c='BASH_DEFAULT_TIMEOUT_MS=600000 BASH_MAX_TIMEOUT_MS=600000 claude'
