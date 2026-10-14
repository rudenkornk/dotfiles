{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs = {
    yazi = {
      enable = true;
      package = pkgs.yazi.overrideAttrs (old: {
        # Yazi ships a `ya` CLI binary that may collide with other popular tools.
        # `pkgs.yazi` is a `runCommand` wrapper, so its `buildCommand` must be extended
        # (`postBuild`/`postInstall` are not run by `runCommand`).
        buildCommand = (old.buildCommand or "") + ''
          rm -f "$out/bin/ya"
        '';
      });
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };
    fish.interactiveShellInit =
      # fish
      ''
        for mode in default insert
          bind --mode $mode ctrl-y yazi
        end
      '';

    bash.initExtra =
      # bash
      ''
        bind -x '"\C-y": "yazi"'
      '';

    zsh.initContent =
      # zsh
      ''
        function _yazi_widget() { yazi; zle reset-prompt }
        zle -N _yazi_widget
        bindkey '^y' _yazi_widget
      '';

    nushell.extraConfig =
      # nu
      ''
        $env.config.keybindings = ($env.config.keybindings | append {
          name: yazi
          modifier: control
          keycode: char_y
          mode: [emacs, vi_normal, vi_insert]
          event: { send: ExecuteHostCommand cmd: "yazi" }
        })
      '';
  };

  home.file = {
    "${config.xdg.configHome}/yazi/keymap.toml" = {
      enable = lib.mkForce true;
      source = lib.mkForce config.xdg.configFile."yazi/keymap.toml".source;
    };
    "${config.xdg.configHome}/yazi/yazi.toml" = {
      enable = lib.mkForce true;
      source = lib.mkForce config.xdg.configFile."yazi/yazi.toml".source;
    };
  };
}
