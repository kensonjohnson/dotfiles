#-------------------------------#
#--- Set Variables -------------#
#-------------------------------#

export NULLCMD=bat
export DOTFILES="$HOME/.dotfiles"
export HOMEBREW_BUNDLE_FILE="$DOTFILES/Brewfile"

#-------------------------------#
#--- Change ZSH Options --------#
#-------------------------------#

# Setup Git autocompletion
autoload -Uz compinit && compinit

#-------------------------------#
#--- Customize Aliases ---------#
#-------------------------------#

alias vim="nvim"
alias vi="nvim"
alias ls="eza"
alias la="eza -la --git"
alias cat="bat"
alias rm=trash
alias man=batman
alias pbat=prettybat
alias nrd="npm run dev"
alias c=code
alias c.="code ."

#-------------------------------#
#--- Customize Hotkeys ---------#
#-------------------------------#

bindkey -s ^f "tmux_sessionizer\n"

#-------------------------------#
#--- Customize Prompts ---------#
#-------------------------------#

# Set Prompt to show current directory in Bright Yellow
PROMPT='%B%F{130}┌─[%3~]
└[]%f%b '

# Set Right Prompt to show last command status
RPROMPT='%B%F{130}[%f%b%(?.%F{green}√.%F{red}?%?)%f%B%F{130}]%f%b'

# Set Cursor to Blinking Vertical Bar
echo -e -n "\x1b[\x35 q"

#-------------------------------#
#--- $PATH Modifications -------#
#-------------------------------#

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
export PATH=${PATH}:$(go env GOBIN)

#-------------------------------#
#--- Functions -----------------#
#-------------------------------#

### Make and Change to Direcory ###
mkcd ()
{
 mkdir -p "$@" && cd "$_"; 
}

### Set Terminal Title ###
settitle ()
{
  echo -ne "\033]0;"$*"\007"
}

### Cleanup Git Branches ###
prune()
{
current_branch=$(git symbolic-ref --short HEAD)
if [ $current_branch != "main" ] && [ $current_branch != "master" ]; then
  echo "\x1b[31mYou must be on \x1b[38;2;255;153;51mmaster\x1b[31m or \x1b[38;2;255;153;51mmain\x1b[31m to prune branches\x1b[0m."
  return 1
fi

git fetch origin &>/dev/null
git fetch --prune &>/dev/null

for branch in $(git branch --format="%(refname:short)"); do
  # if branch is merged into current branch
  if [ $branch != "master" ] && [ $branch != "main" ]; then
    # if branch is not in remote
    if ! git branch -r | grep --quiet $branch; then
      # delete local branch
      echo "\x1b[92m$(git branch -d $branch)\x1b[0m"
    fi
  fi
done
return 0
}

#-------------------------------#
#--- Load ZSH Plugins ----------#
#-------------------------------#

# Setup ZSH syntax highlighting 
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Setup fzf for zsh
source <(fzf --zsh)
