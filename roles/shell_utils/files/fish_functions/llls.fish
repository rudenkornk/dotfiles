function llls --wraps eza
    eza \
        --classify \
        --icons \
        --all \
        --header \
        --long \
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
        --total-size \
        --sort size \
        $argv
end
