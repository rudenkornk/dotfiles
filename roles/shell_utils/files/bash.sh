#!/usr/bin/env bash

alias b="bat"
alias l="eza --classify --icons --all"
alias la="eza --classify --icons --all"
alias lg="eza --classify --icons --all --long --header --tree --level 2 --git-ignore"
alias lg3="eza --classify --icons --all --long --header --tree --level 3 --git-ignore"
alias lgs="eza --classify --icons --all --long --header --tree --level 2 --total-size --sort size --git-ignore"
alias ll="eza --classify --icons --all --long --header --tree --level 1"
alias lll="eza --classify --icons --all --long --header \
          --binary --group --smart-group --links --inode \
          --modified --created --accessed --time-style relative --flags --blocksize"
alias llls="eza --classify --icons --all --long --header \
          --binary --group --smart-group --links --inode \
          --modified --created --accessed --time-style relative --flags --blocksize --total-size --sort size"
alias lls="eza --classify --icons --all --long --header \
          --tree --total-size --level 1 --sort size"
alias ls="eza --classify --icons --all"
alias lt="eza --classify --icons --all --long --header --tree --level 2"
alias lt3="eza --classify --icons --all --long --header --tree --level 3"
alias lts="eza --classify --icons --all --long --header --tree --level 2 --total-size --sort size"

function c() {
  if [[ "$argv" == "-" ]] || [[ -z "$argv" ]]; then
    popd && eza --classify --icons --all
  else
    pushd .
    z "$argv" && eza --classify --icons --all
  fi
}

# See https://yazi-rs.github.io/docs/quick-start#shell-wrapper
function yy() {
  local tmp
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    pushd "$cwd" && eza --classify --icons
  fi
  rm -f -- "$tmp"
}

eval "$(zoxide init bash)"

if [[ -f ~/.local/bin/yazi_dir/completions/ya.bash ]]; then
  source ~/.local/bin/yazi_dir/completions/ya.bash
  source ~/.local/bin/yazi_dir/completions/yazi.bash
fi

export PATH="$HOME/.fzf/bin:$PATH"
export PATH="$HOME/.local/xh:$PATH"

eval "$(oh-my-posh init bash)"
