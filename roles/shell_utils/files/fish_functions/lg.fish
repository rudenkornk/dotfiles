function lg --wraps eza
    eza \
        --classify \
        --icons \
        --all \
        --long \
        --header \
        --tree \
        --level 2 \
        --git-ignore \
        $argv
end
