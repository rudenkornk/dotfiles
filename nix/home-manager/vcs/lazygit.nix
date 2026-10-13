{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs = {
    lazygit = {
      enable = true;
      package = pkgs.unstable.lazygit; # TODO(rudenkornk): Switch to stable after NixOS 26.11.
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };
    fish.interactiveShellInit =
      # fish
      ''
        for mode in default insert
          bind --mode $mode ctrl-g lazygit
        end
      '';

    bash.initExtra =
      # bash
      ''
        bind -x '"\C-g": "lazygit"'
      '';

    zsh.initContent =
      # zsh
      ''
        function _lazygit_widget() { lazygit; zle reset-prompt }
        zle -N _lazygit_widget
        bindkey '^g' _lazygit_widget
      '';

    nushell.extraConfig =
      # nu
      ''
        $env.config.keybindings = ($env.config.keybindings | append {
          name: lazygit
          modifier: control
          keycode: char_g
          mode: [emacs, vi_normal, vi_insert]
          event: { send: ExecuteHostCommand cmd: "lazygit" }
        })
      '';
  };

  # Empty LazyGit settings still declare a disabled file upstream.
  home.file."${config.xdg.configHome}/lazygit/config.yml" = {
    enable = lib.mkForce true;
    source = lib.mkForce config.xdg.configFile."lazygit/config.yml".source;
  };

}
