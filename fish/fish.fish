set local_bin "$HOME/.local/bin"

if printf "3.2.0\n$FISH_VERSION" | sort --version-sort --check &> /dev/null
  fish_add_path $local_bin
else
  contains "$local_bin" $fish_user_paths; or set -Ua fish_user_paths "$local_bin"
end

# Credits: https://gist.github.com/gerbsen/5fd8aa0fde87ac7a2cae
setenv SSH_ENV $HOME/.ssh/environment
function start_agent
  echo "Initializing new SSH agent ..."
  ssh-agent -c | sed 's/^echo/#echo/' > $SSH_ENV
  echo "succeeded"
  chmod 600 $SSH_ENV
  . $SSH_ENV > /dev/null
  ssh-add "~/.ssh/*_id_rsa"
end
function test_identities
  ssh-add -l | grep "The agent has no identities" > /dev/null
  if [ $status -eq 0 ]
    ssh-add "~/.ssh/*_id_rsa"
    if [ $status -eq 2 ]
      start_agent
    end
  end
end
if [ -n "$SSH_AGENT_PID" ]
  ps -ef | grep $SSH_AGENT_PID | grep ssh-agent > /dev/null
  if [ $status -eq 0 ]
    test_identities
  end
else
  if [ -f $SSH_ENV ]
    . $SSH_ENV > /dev/null
  end
  ps -ef | grep $SSH_AGENT_PID | grep -v grep | grep ssh-agent > /dev/null
  if [ $status -eq 0 ]
    test_identities
  else
    start_agent
  end
end

