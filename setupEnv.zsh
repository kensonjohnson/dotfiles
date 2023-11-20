#!/bin/zsh
#
# Setup Script for Fresh MacOS Install

# TODO: Check for proper placement of .dotfiles directory
# TODO: Add idempotent wraps for each link
# Symbolic Links
ln -s ~/.dotfiles/zshrc ~/.config/.zshrc
ln -s ~/.dotfiles/zshenv ~/.config/.zshenv
ln -s ~/.dotfiles/nvim ~/.config/nvim
