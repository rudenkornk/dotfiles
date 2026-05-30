{ pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    autocd = true;
    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
        "match_prev_cmd"
      ];
    };
    history = {
      append = true;
      extended = true;
      size = 100000;
    };
  };
}
