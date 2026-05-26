if test "$argv" = -
    or test "$argv" = ""
    popd && l
else
    pushd .
    z $argv && l
end
