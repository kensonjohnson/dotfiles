# AGENTS.md - Dotfiles Repository Guide

## Build/Test Commands
- `just --list` - Show available commands
- `just brew-dump` - Update Brewfile with current packages
- No formal test suite - configuration files are validated by their respective tools

## Code Style Guidelines

### Lua (Neovim config)
- 2-space indentation, expand tabs
- Use double quotes for strings
- Descriptive variable names with snake_case
- Group related configurations in separate files under `lua/`
- Use `require()` for module imports
- Comment sections with `---` for major blocks

### Shell Scripts (zsh)
- Use `#---` comment blocks for sections
- Export variables in UPPERCASE
- Function names in lowercase with underscores
- Prefer `$()` over backticks for command substitution

### Configuration Files
- Maintain existing indentation patterns
- Use descriptive comments explaining purpose
- Keep related settings grouped together
- Follow tool-specific conventions (e.g., kanata kbd syntax)

## File Organization
- Neovim: `nvim/lua/` for modular configuration
- Shell: `zshrc` for interactive shell config, `zshenv` for environment
- Tools: Separate directories per tool (ghostty/, kanata/, ssh/)