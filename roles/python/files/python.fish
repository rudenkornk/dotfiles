set current "$(pwd)"
set host $(hostname)

while string match --quiet "$HOME*" "$current"
  set activate "$current/.makepy/artifacts/venv/$(hostname)/bin/activate.fish"
  if test -f $activate
    source $activate
    return
  end
  set current (dirname "$current")
end

source $HOME/.venv/bin/activate.fish