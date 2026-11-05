if test "$argv" = -
    or test "$argv" = ""
    popd && l
else
    set -l old_pwd $PWD
    z $argv; or return
    set -g -p dirstack $old_pwd
    l
end
