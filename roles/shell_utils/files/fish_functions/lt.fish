function lt --wraps eza
    eza \
        --classify \
        --icons \
        --all \
        --long \
        --header \
        --tree \
        --level 2 \
        $argv
end
