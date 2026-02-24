if test "$argv" = -
    or test "$argv" = ""
    popd && l
else
    pushd .
    z $argv && l
end
if test -f .venv/bin/activate.fish
    source .venv/bin/activate.fish
end
