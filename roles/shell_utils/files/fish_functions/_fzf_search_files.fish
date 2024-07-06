function _fzf_search_files --description "Search the current directory with ripgrep. Replace the current token with the selected file paths."

    set token (commandline --current-token)
    # expand any variables or leading tilde (~) in the token
    set expanded_token (eval echo -- $token)
    # unescape token because it's already quoted so backslashes will mess up the path
    set unescaped_exp_token (string unescape -- $expanded_token)

    if not set --query fzf_rg_opts
        set rg_opts --line-number --no-heading --color=always --smart-case --follow --hidden
    else
      set rg_opts $fzf_rg_opts
    end

    set fzf_arguments \
      --ansi \
      --bind "change:reload:sleep 0.1; rg $rg_opts {q} || true" \
      --delimiter : \
      --disabled \
      --multi \
      --preview-window='wrap,+{2}+3/3' \
      --preview='_fzf_preview_file {1} {2}' \
      --prompt="Search Files> " \
      --query="$unescaped_exp_token" \
      $fzf_files_opts

    set raw_selected (rg $rg_opts "" 2>/dev/null | _fzf_wrapper $fzf_arguments)
    set re '(^[^:]*):'
    for raw in $raw_selected
      set -a file_paths_selected $(string match --regex "$re" --groups-only "$raw")
    end


    if test $status -eq 0
      commandline --current-token --replace -- (string escape -- $file_paths_selected | string join ' ')
    end

    commandline --function repaint
end
