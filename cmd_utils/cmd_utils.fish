set --export FZF_DEFAULT_OPTS \
  --cycle \
  --layout=reverse \
  --border \
  --height=90% \
  --preview-window=wrap \
  --marker="*" \
  --multi \
  --bind ctrl-u:half-page-up,ctrl-d:half-page-down,ctrl-b:preview-page-up,ctrl-f:preview-page-down
set --export fzf_fd_opts --hidden --exclude=.git
