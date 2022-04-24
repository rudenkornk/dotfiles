alias tmux='tmux -2 -u'

if [ -z "$SSH_AUTH_SOCK" ] ; then
  eval "$(ssh-agent -s)" &> /dev/null
  ssh-add ~/.ssh/* &> /dev/null
fi


