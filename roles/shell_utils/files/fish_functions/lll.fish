function lll --wraps eza
    eza \
        --classify \
        --icons \
        --all \
        --long \
        --header \
        --binary \
        --group \
        --smart-group \
        --links \
        --inode \
        --modified \
        --created \
        --accessed \
        --time-style "relative" \
        --flags \
        --blocksize \
        $argv
end
