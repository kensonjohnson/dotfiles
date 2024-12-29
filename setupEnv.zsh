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
