if string match --quiet --regex '/(arcadia|cloudia)' "$PWD"
    arc $argv
else
    git $argv
end
