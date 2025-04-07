set quiet := true

# Display help
[private]
help:
  just --list --unsorted

# Replace dumpfile with current program list in brew
[confirm("This will overwrite the current Brewfile. Are you sure?")]
brew-dump:
  brew bundle dump --force
