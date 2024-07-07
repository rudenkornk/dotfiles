# See https://yazi-rs.github.io/docs/quick-start#shell-wrapper
function yy --wraps yazi
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        pushd "$cwd" && eza --classify --icons --all
    end
    rm -f -- "$tmp"
end
