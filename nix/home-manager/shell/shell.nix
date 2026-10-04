{ pkgs, ... }:

# Shells & shells extensions.
{
  home.packages = with pkgs; [
    bash-completion
    carapace
    fish
    nushell
    oh-my-posh
    powershell
    tmux
  ];

  local = {
    home.file = {
      ".".source = ./configs;
    };
  };

  # Control keys:
  # ctrl-a beginning of the line.
  # ctrl-b one char backwards.
  # ctrl-c interrupt process.
  # ctrl-d delete one char.
  # ctrl-e end of the line.
  # ctrl-f one char forward.
  # Ctrl-G opens lazygit.
  # ctrl-h goto left window.
  # ctrl-i tab (shell reserved).
  # ctrl-j goto lower window.
  # ctrl-k goto upper window.
  # ctrl-l goto right window.
  # ctrl-m enter (shell reserved).
  # ctrl-n next history command.
  # ctrl-o fzf nix-search-tv.
  # ctrl-p previous history command.
  # ctrl-q fzf search text.
  # Ctrl-R searches Atuin history.
  # ctrl-s tmux reserved.
  # ctrl-t fzf search files.
  # ctrl-u delete all to the left.
  # ctrl-v fzf search tldr (previously paste).
  # ctrl-w delete one word to the left.
  # ctrl-x fzf search processes (previously copy fish command).
  # Ctrl-Y opens Yazi.
  # ctrl-z undo.

}
