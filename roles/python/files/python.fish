set current "$(pwd)"
set host $(hostname)

set -a venvs ".makepy/artifacts/venv/$(hostname)/bin/activate.fish"
set -a venvs ".makepy/artifacts/uv-$(hostname)/bin/activate.fish"
set -a venvs ".venv/bin/activate.fish"
set -a venvs "venv/bin/activate.fish"

while string match --quiet "$HOME*" "$current"
  set activate "$current/.makepy/artifacts/venv/$(hostname)/bin/activate.fish"
  for candidate in $venvs
    if test -f $current/$candidate
      source $current/$candidate
      return
    end
  end
  set current (dirname "$current")
end
