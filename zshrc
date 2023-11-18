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

# Set repo to personal username
setRepo ()
{
  if (which git > /dev/null 2>&1); then
  git config user.name "Kenson Johnson"
  git config user.email "94240602+kensonjohnson@users.noreply.github.com"
  git config --unset gpg.format
  git config gpg.format ssh
  git config user.signingkey ~/.ssh/id_ed25519.pub
  git config commit.gpgsign true
else
  echo "Git not installed, please install git and try again."
fi
}

#--- Load ZSH Plugins ----------#

source /Users/kenson/.zsh-packages/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

