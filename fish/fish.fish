
set local_bin "$HOME/.local/bin"

if printf "3.2.0\n$FISH_VERSION" | sort --version-sort --check &> /dev/null
  fish_add_path $local_bin
else
  contains "$local_bin" $fish_user_paths; or set -Ua fish_user_paths "$local_bin"
end

if status is-interactive
and not set -q SSH_AUTH_SOCK
  eval "ssh-agent -s" &> /dev/null
  ssh-add ~/.ssh/*id_rsa &> /dev/null
end

