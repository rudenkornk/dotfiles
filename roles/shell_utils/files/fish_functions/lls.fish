function lls --wraps eza
    eza \
        --classify \
        --icons \
        --all \
        --long \
        --header \
        --tree \
        --total-size \
        --level 1 \
        --sort size \
        $argv
end
