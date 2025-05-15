function lgs --wraps eza
    eza \
        --classify \
        --icons \
        --all \
        --long \
        --header \
        --tree \
        --level 2 \
        --total-size \
        --sort size \
        --git-ignore \
        $argv
end
