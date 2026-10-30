{
  config,
  pkgs,
  lib,
  wlib,
  ...
}:
let
  fzf = wlib.evalPackage {
    imports = [ ../../wrappers/fzf.nix ];
    inherit pkgs;
    commands = {
      editor = lib.getExe config.programs.neovim.finalPackage;
      imagePreview = lib.concatStringsSep " " [
        "${lib.getExe pkgs.kitty} +kitten icat --transfer-mode=memory"
        ''--stdin=no --place="$FZF_PREVIEW_COLUMNS"x"$FZF_PREVIEW_LINES""@0x0" --''
      ];
      clipboard = "${lib.getExe' pkgs.wl-clipboard "wl-copy"} --primary --trim-newline";
      privilege = "sudo";
    };
    dependencies = {
      nixSearchTv = config.programs.nix-search-tv.package;
      tealdeer = config.programs.tealdeer.package;
    };
  };
  hooks = fzf.shellIntegrations;
in
{
  home.packages = lib.unique (lib.concatMap (hook: hook.packages) (lib.attrValues hooks));

  programs = {
    tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };

    bash.initExtra = lib.mkMerge [
      (lib.mkOrder 200 hooks.bash.earlyInteractiveInit)
      hooks.bash.interactiveInit
    ];
    fish.interactiveShellInit = lib.mkMerge [
      (lib.mkOrder 200 hooks.fish.earlyInteractiveInit)
      hooks.fish.interactiveInit
    ];
    zsh.initContent = lib.mkMerge [
      (lib.mkOrder 910 hooks.zsh.earlyInteractiveInit)
      hooks.zsh.interactiveInit
    ];
    nushell.extraConfig = hooks.nushell.interactiveInit;
  };
}
