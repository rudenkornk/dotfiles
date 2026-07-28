# lazygit, wrapped with its config baked in (LG_CONFIG_FILE); home-manager only
# provides the shell integrations and ctrl-g bindings.
{ config, ... }:
let
  flakeCfg = config;
in
{
  flake = {
    wrappers.lazygit =
      {
        config,
        wlib,
        pkgs,
        ...
      }:
      {
        imports = [ wlib.modules.default ];
        package = pkgs.lazygit;
        env.LG_CONFIG_FILE = config.constructFiles.generatedConfig.path;
        constructFiles.generatedConfig = {
          relPath = "lazygit-config.yml";
          # JSON is a subset of YAML, which spares a toYAML generator here.
          content = builtins.toJSON {
            gui = {
              # The number of lines you scroll by when scrolling the main window.
              scrollHeight = 20;
            };
            keybinding = {
              universal = {
                prevPage = "<c-u>";
                nextPage = "<c-d>";
                scrollUpMain-alt2 = "<c-b>";
                scrollDownMain-alt2 = "<c-f>";
              };
              files = {
                findBaseCommitForFixup = ""; # Conflicts with universal `C-f`.
                openStatusFilter = ""; # Conflicts with universal `C-b`.
              };
            };
          };
        };
      };

    wrappers.fish =
      { pkgs, ... }:
      let
        fishlib = import ../shell/_fish/lib.nix;
      in
      {
        plugins = [
          (fishlib.mkSnippet pkgs "56-lazygit" ''
            for mode in default insert
              bind --mode $mode ctrl-g lazygit
            end

            function lg
              set -x LAZYGIT_NEW_DIR_FILE ~/.lazygit/newdir
              command lazygit $argv
              if test -f $LAZYGIT_NEW_DIR_FILE
                cd (cat $LAZYGIT_NEW_DIR_FILE)
                rm -f $LAZYGIT_NEW_DIR_FILE
              end
            end
          '')
        ];
      };

    modules.homeManager.base = { pkgs, ... }: {
      programs = {
        lazygit = {
          enable = true;
          package = flakeCfg.flake.packages.${pkgs.stdenv.hostPlatform.system}.lazygit;
          enableBashIntegration = true;
          enableFishIntegration = false; # Handled by the wrapped fish snippet.
          enableNushellIntegration = true;
          enableZshIntegration = true;
        };
        bash.initExtra =
          # bash
          ''
            bind -x '"\C-g": "lazygit"'
          '';

        zsh.initContent =
          # zsh
          ''
            # ctrl-g is the abort key in zsh (cancel current operation) and should not be overridden.
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
    };
  };
}
