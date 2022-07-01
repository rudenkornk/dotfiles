set local_bin "$HOME/.local/bin"

if printf "3.2.0\n$FISH_VERSION" | sort --version-sort --check &> /dev/null
  fish_add_path $local_bin
else
  contains "$local_bin" $fish_user_paths; or set -Ua fish_user_paths "$local_bin"
end

if not set -q SSH_AUTH_SOCK && [ -d ~/.ssh ] && [ (find ~/.ssh -name "*id_rsa" | wc -l) -gt 0 ]
  eval (ssh-agent -c) &> /dev/null
  ssh-add ~/.ssh/*id_rsa &> /dev/null
end

if uname --all | grep --quiet WSL
  set --erase DISPLAY
end

