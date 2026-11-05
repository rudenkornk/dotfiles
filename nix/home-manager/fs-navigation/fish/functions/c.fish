set -l old_pwd $PWD
if test "$argv" = -
    or test "$argv" = ""
    popd; or return
    set -g -p __c_forward $old_pwd
else if test "$argv" = +
    if not set -q __c_forward[1]
        printf 'c: forward directory history is empty\n' >&2
        return 1
    end
    cd -- $__c_forward[1]; or return
    set -g -p dirstack $old_pwd
    set -e __c_forward[1]
else
    z $argv; or return
    set -g -p dirstack $old_pwd
    set -g __c_forward
end
l
