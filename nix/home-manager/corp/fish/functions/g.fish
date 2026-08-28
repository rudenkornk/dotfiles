if string match --quiet '*/arcadia*' "$PWD"
    arc $argv
else
    git $argv
end
