#--- Set Variables ----------#
export NULLCMD=bat
export DOTFILES="$HOME/.dotfiles"
export HOMEBREW_BUNDLE_FILE="$DOTFILES/Brewfile"

#--- Change ZSH Options ----------#

# Setup Git autocompletion
autoload -Uz compinit && compinit

#--- Customize Aliases ----------#

alias vim="nvim"
alias vi="nvim"
alias ls="eza"
alias la="eza -la -git"
alias cat="bat"
alias rm=trash
alias man=batman
alias pbat=prettybat

#--- Customize Prompts ----------#
# Set Prompt to show current directory in Bright Yellow
PROMPT='%B%F{130}┌─[%3~]
└[]%f%b '

# Set Right Prompt to show last command status
RPROMPT='%B%F{130}[%f%b%(?.%F{green}√.%F{red}?%?)%f%B%F{130}]%f%b'

# Set Cursor to Blinking Vertical Bar
echo -e -n "\x1b[\x35 q"

#--- $PATH Modifications ----------#

#--- Functions ----------#

# Make and change to directory
mkcd ()
{
 mkdir -p "$@" && cd "$_"; 
}

# Set Terminal Title
settitle ()
{
  echo -ne "\033]0;"$*"\007"
}

#--- Load ZSH Plugins ----------#
# Setup ZSH syntax highlighting
source /Users/kenson/.zsh-packages/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

