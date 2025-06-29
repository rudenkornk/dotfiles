# Credits: https://gist.github.com/gerbsen/5fd8aa0fde87ac7a2cae
touch ~/.ssh/environment
setenv SSH_ENV ~/.ssh/environment
function start_agent
  echo "Initializing new SSH agent ..."
  ssh-agent -c | sed 's/^echo/#echo/' > $SSH_ENV
  echo "succeeded"
  chmod 600 $SSH_ENV
  . $SSH_ENV > /dev/null
  set -l keys ~/.ssh/*.sops
  for key in $keys
    sops --decrypt $key | ssh-add -
  end
end
function test_identities
  ssh-add -l | grep "The agent has no identities" > /dev/null
  if [ $status -eq 0 ]
    set -l keys ~/.ssh/*.sops
    for key in $keys
      sops --decrypt $key | ssh-add -
    end
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
  ps -ef | grep $SSH_AGENT_PID 2>/dev/null | grep -v grep | grep ssh-agent > /dev/null
  if [ $status -eq 0 ]
    test_identities
  else
    start_agent
  end
end

