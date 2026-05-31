{ user, ... }:

{
  home = {
    inherit (user) username;
    homeDirectory = "/home/${user.username}";
    sessionVariables = {
      USERKIND = user.userkind;
      # https://github.com/ryanoasis/nerd-fonts/wiki/FAQ-and-Troubleshooting#less-settings
      LESSCHARSET = "utf-8";
      LESSUTFCHARDEF =
        ""
        + "23fb-23fe:w,"
        + "2665:w,"
        + "2b58:w,"
        + "e000-e00a:w,"
        + "e0a0-e0a3:p,"
        + "e0b0-e0bf:p,"
        + "e0c0-e0c8:w,"
        + "e0ca:w,"
        + "e0cc-e0d7:w,"
        + "e200-e2a9:w,"
        + "e300-e3e3:w,"
        + "e5fa-e6b5:w,"
        + "e700-e7c5:w,"
        + "ea60-ec1e:w,"
        + "ed00-efce:w,"
        + "f000-f2ff:w,"
        + "f300-f375:w,"
        + "f400-f533:w,"
        + "f0001-f1af0:w";
      QT_SCALE_FACTOR = "1.5";
    };

    file = {
      ".face".source = user.profile_image;
    };

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "26.05"; # Did you read the comment?
  };

  xdg.enable = true;

  fonts.fontconfig.enable = true;

  # We cannot use `pkgs.locallib.get_modules2` in `imports`, because it will result in
  # infinite recursion error.
  imports = import ../nixpkgs/overlays/locallib/get_modules2.nix null ./programs;
}
