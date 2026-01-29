_: {
  home.shellAliases = {
    nix-search-tv = ''command nix-search-tv print | fzf --prompt="Search NixOS> " --preview 'command nix-search-tv preview {}' --scheme history'';
  };

  programs.nix-search-tv = {
    enable = true;
  };
}
