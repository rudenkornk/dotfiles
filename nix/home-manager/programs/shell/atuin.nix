{ pkgs, ... }:

{

  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
    flags = [
      "--disable-up-arrow" # Annoying behaviour, especially with invert=true.
    ];
    # TODO(rudenkornk): change to stable in next 26.11 release.
    # Using unstable here for history syntax highlighting.
    package = pkgs.unstable.atuin;
  };
}
