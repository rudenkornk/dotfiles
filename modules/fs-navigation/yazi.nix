# yazi, wrapped with its settings and keymap baked in; home-manager only
# provides the shell integrations (cd-on-exit wrappers and ctrl-y bindings).
{ config, ... }:
let
  flakeCfg = config;
in
{
  flake = {
    wrappers.yazi = { wlib, pkgs, ... }: {
      imports = [ wlib.wrapperModules.yazi ];
      package = pkgs.yazi.overrideAttrs (old: {
        # Yazi ships a `ya` CLI binary that may collide with other popular tools.
        # `pkgs.yazi` is a `runCommand` wrapper, so its `buildCommand` must be extended
        # (`postBuild`/`postInstall` are not run by `runCommand`).
        buildCommand = (old.buildCommand or "") + ''
          rm -f "$out/bin/ya"
        '';
      });
      settings = {
        yazi = {
          mgr = {
            show_hidden = true;
          };
        };
        keymap = {
          mgr.prepend_keymap = [
            {
              on = [ "?" ];
              run = "help";
              desc = "Show help";
            }
            {
              on = [ "<C-n>" ];
              run = "arrow 1";
              desc = "Next item";
            }
            {
              on = [ "<C-p>" ];
              run = "arrow -1";
              desc = "Prev item";
            }
            {
              on = [ "<C-d>" ];
              run = "arrow 20";
              desc = "Scroll file list down";
            }
            {
              on = [ "<C-u>" ];
              run = "arrow -20";
              desc = "Scroll file list up";
            }
            {
              on = [ "<C-f>" ];
              run = "seek 10";
              desc = "Scroll content down";
            }
            {
              on = [ "<C-b>" ];
              run = "seek -10";
              desc = "Scroll content up";
            }
          ];
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
          (fishlib.mkSnippet pkgs "57-yazi" ''
            for mode in default insert
              bind --mode $mode ctrl-y yazi
            end

            function y
              set -l tmp (mktemp -t "yazi-cwd.XXXXX")
              command yazi $argv --cwd-file="$tmp"
              if read cwd <"$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
                builtin cd -- "$cwd"
              end
              rm -f -- "$tmp"
            end
          '')
        ];
      };

    modules.homeManager.base = { pkgs, ... }: {
      programs = {
        yazi = {
          enable = true;
          package = flakeCfg.flake.packages.${pkgs.stdenv.hostPlatform.system}.yazi;
          enableBashIntegration = true;
          enableFishIntegration = false; # Handled by the wrapped fish snippet.
          enableNushellIntegration = true;
          enableZshIntegration = true;
        };
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
    };
  };
}
