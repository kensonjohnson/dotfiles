export HOMEBREW_CASK_OPTS="--no-quarantine --no-binaries"

function exists() {
  # `command -v` is similar to `which`
  # https://stackoverflow.com/a/677212/1341838
  command -v $1 >/dev/null 2>&1

  # More explicitly written:
  # command -v $1 1>/dev/null 2>/dev/null
}


### TMUX Sessionizer ###
tmux_sessionizer()
{
  session=$(find ~ ~/Developer/repos -type d -mindepth 1 -maxdepth 1 | fzf)

session_name=$(basename $session | tr . _)
tmux_running=$(pgrep tmux)

# If not in tmux, and no tmux session is running, start a new session
if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s $session_name -c $session
    return 0 
fi

# If not in tmux, but a tmux session is running, attach to a session
# with session name if it exists, otherwise start a new session
if [[ -z $TMUX ]] && [[ -n $tmux_running ]]; then
    if tmux has-session -t $session_name 2>/dev/null; then
        tmux attach-session -t $session_name
    else
        tmux new-session -s $session_name -c $session
    fi
    return 0
fi

# If in tmux, but no session with session name is running, start a new session
if ! tmux has-session -t $session_name 2>/dev/null; then
    tmux new-session -d -s $session_name -c $session
fi

tmux switch-client -t $session_name
}
