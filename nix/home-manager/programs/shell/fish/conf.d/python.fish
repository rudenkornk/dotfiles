set current "$(pwd)"

set -a venvs ".venv/bin/activate.fish"
set -a venvs "venv/bin/activate.fish"

while string match --quiet "$HOME*" "$current"
    for candidate in $venvs
        if test -f $current/$candidate
            set --export VIRTUAL_ENV_DISABLE_PROMPT 1
            source $current/$candidate
            return
        end
    end
    set current (dirname "$current")
end
