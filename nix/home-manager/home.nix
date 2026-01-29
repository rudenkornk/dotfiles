{
  user,
  config,
  pkgs,
  ...
}:

{
  home = {
    inherit (user) username;
    homeDirectory = "/home/${user.username}";
    sessionVariables = {
      USERKIND = user.userkind;
    };

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "25.11"; # Did you read the comment?

    file = {
      ".ssh" = {
        source = pkgs.locallib.secrets + /ssh;
        recursive = true;
      };
    };
  };

  xdg.enable = true;

  fonts.fontconfig.enable = true;

  imports = [
    ./dconf/settings.nix
    ./home/shellAliases.nix
    ./programs.nix
    ./services/flameshot.nix
  ];
}
