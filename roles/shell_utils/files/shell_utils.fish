fish_add_path ~/.fzf/bin

# Control keys:
# C-a beginning of the line
# C-b one char backwards
# C-c interrupt process
# C-d delete one char
# C-e end of the line
# C-f one char forward
# C-g fzf git log
# C-h goto left window
# C-i show suggestions
# C-j goto lower window
# C-k goto upper window
# C-l goto right window
# C-m enter
# C-n next history command
# C-o fzf git status
# C-p previous history command
# C-q fzf search files with ripgrep
# C-r fzf command history
# C-s tmux reserved
# C-t fzf search files
# C-u delete all to the left
# C-v fzf search variables
# C-w delete one word to the left
# C-x fzf search processes (previously copy fish command)
# C-y fzf yazi
# C-z undo

# fzf has three ends: how it inputs stuff, how it displays it and how it displays stuff's content.
# FZF_DEFAULT_COMMAND and FZF_CTRL_T_COMMAND is responsible for input, we use fd finder.
# FZF_DEFAULT_OPTS is responsible for displaying stuff and managing it.
# FZF_DEFAULT_OPTS is also can influence how stuff content is displayed with "--preview" option, but it is not recommendend since it does not work in most of scenarios.
# We do not set FZF_DEFAULT_COMMAND here directly. Instead we use fish plugin PatrickF1/fzf.fish, which sets most of options for us.
# So to customize fzf behaviour we use fzf.fish proxy variables such as fzf_fd_opts,


set --export FZF_DEFAULT_OPTS \
    --ansi \
    --bind ctrl-u:half-page-up,ctrl-d:half-page-down,ctrl-b:preview-page-up,ctrl-f:preview-page-down \
    --border \
    --cycle \
    --height=90% \
    --layout=reverse \
    --marker="*" \
    --multi \
    --preview-window=wrap

# Do not set here "--color": it will interfere with fzf.fish
set --export fzf_fd_opts \
    --exclude .ansible \
    --exclude .cache \
    --exclude .cargo \
    --exclude .dbus \
    --exclude .fzf \
    --exclude .git \
    --exclude .gnupg \
    --exclude .gradle \
    --exclude .mypy_cache \
    --exclude .npm \
    --exclude .rustup \
    --exclude __pycache__ \
    --exclude site-packages \
    --follow \
    --no-ignore \
    --hidden
set --export fzf_ps_opts \
    -A \
    -o 'pid user %cpu %mem time command' \
    --sort -pcpu

set --export fzf_processes_opts \
    --bind='ctrl-x:reload(ps $fzf_ps_opts)' \
    --header-lines=1 \
    --header='Press CTRL-X to reload\n\n'

fzf_configure_bindings --directory=\ct --git_log=\co --git_status= --history=\cr --processes=\cx --variables=\cv --files=\cq

for mode in default insert
    bind --mode $mode \cg __fish_disable_focus lazygit
    bind --mode $mode \cy __fish_disable_focus yazi
end

set --export MANROFFOPT -c
set --export MANPAGER "sh -c 'col -bx | bat -l man -p'"

zoxide init fish | source

if test -f ~/.local/bin/yazi_dir/completions/ya.fish
  source ~/.local/bin/yazi_dir/completions/ya.fish
  source ~/.local/bin/yazi_dir/completions/yazi.fish
end

oh-my-posh init fish --config ~/.config/oh-my-posh/theme.json | source
