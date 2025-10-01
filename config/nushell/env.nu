# env.nu
#
# Installed by:
# version = "0.107.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

# Setup PATH
$env.PATH = ($env.PATH | split row (char esep) | prepend [
    ($env.HOME | path join ".local" "bin")
    ($env.HOME | path join ".atuin" "bin")
    ($env.HOME | path join ".cargo" "bin")
    ($env.HOME | path join "go" "bin")
])

# Add Omarchy bin if it exists (Arch + Hyprland only)
let omarchy_bin = ($env.HOME | path join ".local" "share" "omarchy" "bin")
if ($omarchy_bin | path exists) {
    $env.PATH = ($env.PATH | split row (char esep) | prepend $omarchy_bin)
}

# NVM setup
$env.NVM_DIR = ($env.HOME | path join ".nvm")
