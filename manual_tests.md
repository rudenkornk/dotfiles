# Manual tests

## fzf

```bash
podman exec -it -u $(id -u) dotfiles_ubuntu_22.04 fish
ctrl-t # opens fzf search directory panels with list of files and syntax highlighted file contnent
ctrl-y # opens fzf ripgrep search
ctrl-g # in git repo opens fzf git history
ctrl-o # in git repo opens fzf git status
ctrl-r # opens fzf shell history
ctrl-v # opens fzf variables list
ctrl-x # opens fzf processes list, which updates when pressing ctrl-x again
```

When splitting tmux window in two panes and opening any fzf search in any git repo in one of the panes, changing focus between panes should not insert any weird (like "O" and "I") characters in fzf search bar.

## tmux

When creating new window or pane in tmux, it should open directory of the last visited pane.
