#!/bin/zsh
#
# Setup Script for Fresh MacOS Install

# TODO: Check for proper placement of .dotfiles directory
# TODO: Add idempotent wraps for each link
# Symbolic Links
ln -s ~/.dotfiles/zshrc ~/.zshrc
ln -s ~/.dotfiles/zshenv ~/.zshenv
# TODO: Add check for .ssh directory, mkdir if not present
ln -s ~/.dotfiles/ssh/config ~/.ssh/config
ln -s ~/.dotfiles/nvim ~/.config/nvim
ln -s ~/.dotfiles/ghostty ~/.config/ghostty
ln -s ~/.dotfiles/kanata ~/.config/kanata

# Kanata specific configuration
sudo ln -s ~/.config/kanata/com.example.kanata.plist /Library/LaunchDaemons/com.example.kanata.plist
sudo ln -s ~/.config/kanata/com.example.karabiner-vhiddaemon.plist /Library/LaunchDaemons/com.example.karabiner-vhiddaemon.plist
sudo ln -s ~/.config/kanata/com.example.karabiner-vhidmanager.plist /Library/LaunchDaemons/com.example.karabiner-vhidmanager.plist

# Setup ownership for kanata files
sudo chown root:wheel /Users/kenson/.config/kanata/kanata.kbd
sudo chown root:wheel /Library/LaunchDaemons/com.example.kanata.plist
sudo chown root:wheel /Library/LaunchDaemons/com.example.karabiner-vhiddaemon.plist
sudo chown root:wheel /Library/LaunchDaemons/com.example.karabiner-vhidmanager.plist
sudo chmod 644 /Users/kenson/.config/kanata/kanata.kbd
sudo chmod 644 /Library/LaunchDaemons/com.example.kanata.plist
sudo chmod 644 /Library/LaunchDaemons/com.example.karabiner-vhiddaemon.plist
sudo chmod 644 /Library/LaunchDaemons/com.example.karabiner-vhidmanager.plist

# launch configurations
sudo launchctl bootstrap system /Library/LaunchDaemons/com.example.kanata.plist
sudo launchctl enable system/com.example.kanata.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.example.karabiner-vhiddaemon.plist
sudo launchctl enable system/com.example.karabiner-vhiddaemon.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.example.karabiner-vhidmanager.plist
sudo launchctl enable system/com.example.karabiner-vhidmanager.plist
sudo launchctl start com.example.kanata
sudo launchctl start com.example.karabiner-vhiddaemon
sudo launchctl start com.example.karabiner-vhidmanager

