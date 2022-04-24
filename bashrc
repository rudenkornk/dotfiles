
stty erase '^?'
stty -ixon

alias tmux='tmux -2 -u'

if [ -z "$SSH_AUTH_SOCK" ] ; then
  eval "$(ssh-agent -s)" &> /dev/null
  ssh-add ~/.ssh/* &> /dev/null
fi

if : \
  && command -v tmux &> /dev/null \
  && [ -n "$PS1" ] \
  && [[ ! "$TERM" =~ screen ]] \
  && [[ ! "$TERM" =~ tmux ]] \
  && [ -z "$TMUX" ] \
  ; then
  # Only run tmux if either no servers or none is attached
  ! $(tmux ls &> /dev/null) && exec tmux
  tmux ls | grep --quiet --invert-match "(attached)" && exec tmux a
fi

