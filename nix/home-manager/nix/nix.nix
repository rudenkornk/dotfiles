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
      nixos-facter
    ];

    sessionVariables = {
      NH_SHOW_ACTIVATION_LOGS = "true";
    };
  };

  programs = {
    nh = {
      enable = true;
    };

    nix-search-tv = {
      enable = true;
      package = pkgs.unstable.nix-search-tv; # TODO: remove unstable after nixos-26.11
      settings.indexes = [
        "home-manager"
        "nixos"
        "nixpkgs"
        "noogle"
        "nur"
      ];
    };
  };
}
