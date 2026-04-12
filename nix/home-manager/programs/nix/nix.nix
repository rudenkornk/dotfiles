{ pkgs, ... }:

# Nix-related tools.
{
  home = {
    packages = with pkgs; [
      cachix
      dconf2nix
      home-manager
      nix-diff
      nix-index
      nix-melt
      nix-output-monitor
      nix-top
      nix-tree
    ];

    sessionVariables = {
      NH_SHOW_ACTIVATION_LOGS = 1;
    };
  };

  programs = {
    nh = {
      enable = true;
    };

    nix-search-tv = {
      enable = true;
      enableTelevisionIntegration = true;
    };
  };
}
