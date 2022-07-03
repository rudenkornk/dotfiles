set --export FZF_DEFAULT_OPTS \
  --cycle \
  --layout=reverse \
  --border \
  --height=90% \
  --preview-window=wrap \
  --marker="*" \
  --multi \
  --bind ctrl-b:page-up,ctrl-f:page-down,ctrl-u:half-page-up,ctrl-d:half-page-down,ctrl-k:preview-page-up,ctrl-j:preview-page-down
set --export fzf_fd_opts --hidden --exclude=.git
