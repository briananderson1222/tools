# Contributing to This Dotfiles Repository

This document provides guidelines for AI agents (and humans) making changes to this repository.

## Core Principles

1. **Multi-platform Support** - All changes must work across Linux, macOS, and WSL
2. **Multi-distro Support** - Linux changes should support Arch, Ubuntu/Debian, and Fedora
3. **Multi-shell Support** - Shell-specific configs should support bash, zsh, fish, and nushell
4. **Template-based Configs** - Platform/shell-specific configs use templates
5. **Conventional Commits** - All commits follow conventional commit format
6. **Documentation First** - Update README.md before committing changes

## Platform Support Matrix

### Supported Platforms
- **Linux**: Arch, Manjaro, Ubuntu
- **macOS**: Intel and Apple Silicon

**Note:** WSL is supported as it's just Linux - the script detects the underlying distro (Ubuntu, Arch, etc.)

### Platform Detection
The install script automatically detects:
- Operating system (Linux/macOS)
- Linux distribution (via `/etc/os-release`)
- Wayland vs X11 (for Hyprland/Waybar)
- Architecture (x86_64/arm64/aarch64)

### Desktop Environment Support
- **Wayland/Hyprland** with optional Omarchy theme (Arch Linux)
- **Standard desktop environments** (Ubuntu, other distros)
- **macOS** native environment

### Platform-Specific Configs

**Omarchy-specific configs (Arch + Wayland/Hyprland only):**
- `config/hypr/*` - References Omarchy theme system
- `config/waybar/*` - References Omarchy fonts and styling
- Shell dotfiles check for Omarchy and source conditionally

**These configs gracefully degrade on non-Omarchy systems.**

### Writing Platform-Specific Code

```bash
case "$platform" in
    macos)
        # macOS-specific logic
        ;;
    linux|wsl)
        # Linux-specific logic
        case "$distro" in
            arch|manjaro)
                # Arch/Manjaro-specific (pacman/yay)
                ;;
            ubuntu|debian)
                # Ubuntu-specific (apt)
                ;;
            *)
                # Unsupported distro - provide generic fallback
                log_warning "Unsupported distribution: $distro"
                ;;
        esac
        ;;
esac
```

## Shell Support

### Supported Shells
- **bash** - Default on most systems
- **zsh** - Popular alternative shell
- **nushell** - Modern, structured shell

### Shell Detection
The `detect_shell()` function identifies available shells and prompts the user during installation.

### Adding Shell-Specific Configs
1. Create shell config in `dotfiles/` or `config/`
2. Update `sync.sh` to include the new config
3. Update template generators if needed

## Template System

### When to Use Templates
Use templates for configs that vary by:
- Platform (Linux vs macOS)
- Shell (bash vs zsh vs fish vs nushell)
- Distribution (different package managers)
- Environment (Wayland vs X11)

### Template Structure
```
config/
└── tool-name/
    ├── templates/
    │   └── config.template    # Template file with {{VARIABLES}}
    └── examples/
        └── generated-example  # Example of generated output
```

### Template Variables
Common template variables:
- `{{SHELL_PATH}}` - Path to user's shell
- `{{FONT_FAMILY}}` - Font family name
- `{{FONT_SIZE}}` - Platform-specific font size
- `{{THEME_CONFIG}}` - Platform-specific theme config

### Creating a Template Generator
```bash
generate_tool_config() {
    local platform="$1"
    local template_file="$CONFIG_DIR/tool/templates/config.template"
    local output_file="$HOME/.config/tool/config"

    # Platform-specific values
    local value="default"
    case "$platform" in
        macos)
            value="macos-specific"
            ;;
        linux)
            value="linux-specific"
            ;;
    esac

    # Generate config
    mkdir -p "$(dirname "$output_file")"
    sed -e "s|{{VARIABLE}}|$value|g" \
        "$template_file" > "$output_file"
}
```

## Sync Script Usage

### Import vs Export
- **`./sync.sh import`** - Import configs FROM your system TO the repo
- **`./sync.sh export`** - Export configs FROM the repo TO your system

### When to Use Sync Script

**Use `import` when:**
- You've made changes to configs in `~/.config/`
- You want to save your current system state to the repo
- Before committing config changes

**Use `export` when:**
- Setting up a new machine
- Reverting to repo versions
- Testing config changes from the repo

### Sync Script Configuration
Edit `sync.sh` to add new configs:

```bash
declare -A CONFIG_DIRS=(
    ["tool-name"]="$HOME/.config/tool-name"
)
```

## Conventional Commits

### Format
```
<type>(<scope>): <description>

<optional body>

<optional footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `docs`: Documentation only changes
- `chore`: Changes to build process or auxiliary tools
- `style`: Code style changes (formatting, missing semi-colons, etc)
- `perf`: Performance improvements
- `test`: Adding or modifying tests

### Examples
```
feat: add dynamic config generation for ghostty

feat(install): add JetBrainsMono Nerd Font installation

fix(sync): handle missing config directories gracefully

docs(readme): update installation instructions

refactor: replace symlinks with copy-based approach
```

### Commit Footer
Always include:
```
🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Making Changes

### Workflow for Config Changes

1. **Test locally first**
   ```bash
   # Make changes to config files
   # Test the changes
   ```

2. **Import to repo**
   ```bash
   ./sync.sh import
   ```

3. **Update documentation**
   - Update README.md if adding new tools
   - Update AGENTS.md if changing patterns
   - Update install.sh comments

4. **Commit with conventional format**
   ```bash
   git add -A
   git commit -m "feat: add new tool configuration

   - Add tool-name config
   - Update sync script
   - Update README

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

5. **Push to main**
   ```bash
   git push origin main
   ```

### Adding New Tools

When adding a new tool:

1. **Determine if template is needed**
   - Does it vary by platform? → Use template
   - Does it vary by shell? → Use template
   - Static config? → No template needed

2. **Add to install script**
   - Add installation logic to `install_tools()`
   - Use platform detection for package manager
   - Prefer cargo/go for universal installation

3. **Add to sync script**
   - Add to `CONFIG_DIRS` or `DOTFILES` in `sync.sh`
   - Add to exclude patterns if needed

4. **Update README**
   - Add to "What's Included" section
   - Add to "Tools Automatically Installed" section
   - Add platform-specific notes if needed

5. **Test on multiple platforms**
   - Test install on Linux
   - Test install on macOS (if available)
   - Test sync import/export

## Font Installation

### Adding New Fonts

Follow the JetBrainsMono pattern:

```bash
install_font_name() {
    local platform="$1"
    local distro="$2"

    case "$platform" in
        macos)
            brew install --cask font-name
            ;;
        linux|wsl)
            # Check if already installed
            if fc-list | grep -qi "Font Name"; then
                return
            fi

            # Try package manager
            case "$distro" in
                arch|manjaro)
                    sudo pacman -S --noconfirm ttf-font-name
                    ;;
            esac

            # Fall back to direct download
            # Download from nerd-fonts or official source
            # Extract to ~/.local/share/fonts
            # Run fc-cache
            ;;
    esac
}
```

## Common Pitfalls

### ❌ Don't
- Hard-code paths (use `$HOME`, `$CONFIG_DIR`, etc.)
- Assume a specific package manager
- Use symlinks (we use copy-based approach)
- Commit without updating README
- Use non-conventional commit messages
- Forget to test on multiple platforms

### ✅ Do
- Use platform detection
- Provide fallbacks for all package managers
- Use `copy_config()` function from install.sh
- Update README and documentation
- Use conventional commits with footers
- Test import/export workflow
- Add examples for generated configs

## Testing Changes

### Pre-commit Checklist
- [ ] Changes work on current platform
- [ ] install.sh runs without errors
- [ ] sync.sh import/export works
- [ ] README.md updated
- [ ] Conventional commit format used
- [ ] Generated configs have examples in repo

### Testing on Multiple Platforms

**GitHub Actions CI:** The repository has automated tests that run on:
- **Arch Linux** (via Docker container) - Primary platform
- **Ubuntu** (latest) - Debian-based testing
- **macOS** (latest) - macOS testing
- Full installation tests with all tools on Arch and Ubuntu
- Script syntax validation
- Markdown link checking

If you can't test locally on all platforms:
1. Push to a branch and let CI run
2. Note in commit message which platforms were tested locally
3. Add clear documentation for platform-specific behavior
4. Follow existing patterns for other platforms

**Running tests:**
- Tests run automatically on push to main
- Tests run on all pull requests
- Can be triggered manually via GitHub Actions UI

## Questions?

When in doubt:
1. Check existing patterns in `install.sh`
2. Look at how similar tools are configured
3. Review recent git commits for examples
4. Follow the principle: "Work everywhere, degrade gracefully"
