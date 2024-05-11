fish_add_path ~/.fzf/bin

# fzf has three ends: how it inputs stuff, how it displays it and how it displays stuff's content.
# FZF_DEFAULT_COMMAND and FZF_CTRL_T_COMMAND is responsible for input, we use fd finder.
# FZF_DEFAULT_OPTS is responsible for displaying stuff and managing it.
# FZF_DEFAULT_OPTS is also can influence how stuff content is displayed with "--preview" option, but it is not recommendend since it does not work in most of scenarios.
# We do not set FZF_DEFAULT_COMMAND here directly. Instead we use fish plugin PatrickF1/fzf.fish, which sets most of options for us.
# So to customize fzf behaviour we use fzf.fish proxy variables such as fzf_fd_opts,


set --export FZF_DEFAULT_OPTS \
  --ansi \
  --bind ctrl-b:half-page-up,ctrl-f:half-page-down,ctrl-u:preview-page-up,ctrl-d:preview-page-down \
  --border \
  --cycle \
  --height=90% \
  --layout=reverse \
  --marker="*" \
  --multi \
  --preview-window=wrap \


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
    --hidden \

set --export fzf_ps_opts \
    -A \
    -o 'pid user %cpu %mem time command' \
    --sort -pcpu

set --export fzf_processes_opts \
    --bind='ctrl-x:reload(ps $fzf_ps_opts)' \
    --header-lines=1 \
    --header='Press CTRL-X to reload\n\n' \


set --export MANPAGER "sh -c 'col -bx | bat -l man -p'"

zoxide init fish | source

source ~/.local/bin/yazi_dir/completions/ya.fish
source ~/.local/bin/yazi_dir/completions/yazi.fish
