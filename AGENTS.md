# AGENTS.md - Dotfiles Repository Guide

## Build/Test Commands
- `just --list` - Show available commands
- `just brew-dump` - Update Brewfile with current packages
- No formal test suite - configuration files are validated by their respective tools

## Code Style Guidelines

### Lua (Neovim config)
- 2-space indentation with tabs, use double quotes for strings
- snake_case for variables, descriptive names (e.g., `highlight_augroup`)
- Group related configs in separate files under `lua/plugins/`
- Use `require()` for module imports, return table for plugin specs
- Comment sections with `---` for major blocks, `--` for inline
- Use `vim.keymap.set()` for keymaps with descriptive desc parameter
- Prefer function callbacks over string commands in autocommands

### Shell Scripts (zsh)
- Use `#---` comment blocks for major sections
- Export variables in UPPERCASE, function names in lowercase_underscore
- Prefer `$()` over backticks, use double quotes for variable expansion
- Group aliases by category with descriptive comments

### Configuration Files
- Maintain existing indentation patterns (tabs for Lua, spaces for others)
- Use descriptive comments explaining purpose of complex configurations
- Keep related settings grouped together logically
- Follow tool-specific conventions (kanata kbd syntax, ghostty config format)