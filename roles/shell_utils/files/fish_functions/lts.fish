function lts --wraps eza
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
        $argv
end
