{ pkgs, config, ... }:
{

  programs.television = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    # enableNushellIntegration = true;

    # TODO(rudenkornk): remove this W/A once updated to nixos-26.05.
    # Remove broken vendor completion files with unsubstituted placeholders
    #
    # PROBLEM:
    # ========
    # The nixpkgs television package installs shell completion templates without substituting
    # placeholders. The completion.fish file includes these lines:
    #
    #   for mode in default insert
    #     bind --mode $mode {tv_smart_autocomplete_keybinding} tv_smart_autocomplete
    #     bind --mode $mode {tv_shell_history_keybinding} tv_shell_history
    #   end
    #
    # These placeholders should be replaced with actual keybindings (e.g., \cT, \cR) by
    # running `tv init fish`, which the binary generates dynamically.
    #
    # Fish automatically sources this file from vendor_completions.d when loading `tv`
    # completions, causing these errors:
    #
    #   bind: cannot parse key '{tv_smart_autocomplete_keybinding}'
    #   bind: cannot parse key '{tv_shell_history_keybinding}'
    #
    # The proper init code is already sourced in ~/.config/fish/config.fish, so the broken
    # vendor completion file is unnecessary.
    #
    # This problem is fixed in a series of commits in unstable channel:
    # https://github.com/NixOS/nixpkgs/commit/01b78c47474b10c523eb026795c6af60f2376e4a
    # https://github.com/NixOS/nixpkgs/commit/02ff23113ad96329fab23a3deef266c225d9a7f1
    # https://github.com/NixOS/nixpkgs/commit/82f750dc41a1215b792d4661564107dd573b4de4
    # https://github.com/NixOS/nixpkgs/commit/74a6c30612152d8b186f55f9c8b998f978afd6eb
    package = pkgs.unstable.television;
  };

  home.file = pkgs.locallib.homefiles {
    inherit (config) xdg;
    path = ./television;
  };
}
