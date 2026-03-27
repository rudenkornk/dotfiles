{ pkgs, ... }:

# Shells & shells extensions.
{
  home.packages = with pkgs; [
    atuin
    bash-completion
    carapace
    fish
    nushell
    oh-my-posh
    powershell
    tmux
  ];

  # Control keys:
  # ctrl-a beginning of the line.
  # ctrl-b one char backwards.
  # ctrl-c interrupt process.
  # ctrl-d delete one char.
  # ctrl-e end of the line.
  # ctrl-f one char forward.
  # ctrl-g fzf git log.
  # ctrl-h goto left window.
  # ctrl-i tab (shell reserved).
  # ctrl-j goto lower window.
  # ctrl-k goto upper window.
  # ctrl-l goto right window.
  # ctrl-m enter (shell reserved).
  # ctrl-n next history command.
  # ctrl-o fzf git status.
  # ctrl-p previous history command.
  # ctrl-q fzf search files with ripgrep.
  # ctrl-r fzf command history.
  # ctrl-s tmux reserved.
  # ctrl-t fzf search files.
  # ctrl-u delete all to the left.
  # ctrl-v fzf search variables (previously paste).
  # ctrl-w delete one word to the left.
  # ctrl-x fzf search processes (previously copy fish command).
  # ctrl-y fzf yazi.
  # ctrl-z undo.

  home.sessionVariables = {
    FZF_DEFAULT_OPTS =
      ""
      + "--ansi "
      + "--bind ctrl-u:half-page-up,ctrl-d:half-page-down,ctrl-b:preview-page-up,ctrl-f:preview-page-down "
      + "--border "
      + "--cycle "
      + "--height=90% "
      + "--layout=reverse "
      + "--marker='*' "
      + "--multi "
      + "--preview-window=wrap ";
  };
}
