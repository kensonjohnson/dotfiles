echo "Loading zshrc"

#--- Set Variables ----------#

#--- Change ZSH Options ----------#

autoload -Uz compinit && compinit

#--- Customize Aliases ----------#

alias vim="nvim"
alias vi="nvim"
alias ls="ls -GF"
alias la="ls -lAGFh"

#--- Customize Prompts ----------#
# Set Prompt to show current directory in Bright Yellow
PROMPT='%B%F{130}┌─[%2~]
└[%#]%f%b '

# Set Right Prompt to show last command status
RPROMPT='%B%F{130}[%f%b%(?.%F{green}√.%F{red}?%?)%f%B%F{130}]%f%b'
# Set Cursor to Blinking Vertical Bar
echo -e -n "\x1b[\x35 q"

#--- $PATH Modifications ----------#

#--- Functions ----------#
mkcd ()
{
 mkdir -p "$@" && cd "$_"; 
}

#--- Load ZSH Plugins ----------#

source /Users/kenson/.zsh-packages/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

