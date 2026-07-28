# fzf itself plus the standalone fzf-based tools from `_fzf/scripts.nix`
# (fzf-rg, fzf-ns, fzf-tldr, fzf-ps), bound to keys in every shell.
{ config, ... }:
let
  flakeCfg = config;
in
{
  perSystem = { pkgs, ... }: { packages = import ./_fzf/scripts.nix { inherit pkgs; }; };

  flake.modules.homeManager.base =
    { pkgs, lib, ... }:
    let
      inherit (import ./_fzf/prompts.nix)
        h1
        h2
        h3
        h4
        ;
      tool = name: lib.getExe flakeCfg.flake.packages.${pkgs.stdenv.hostPlatform.system}.${name};
      rgScript = tool "fzf-rg";
      nsScript = tool "fzf-ns";
      tldrScript = tool "fzf-tldr";
      psScript = tool "fzf-ps";

      ignoreFile = toString ./_fzf/ignore;

      # ── ctrl-t: fd search ────────────────────────────────────────────────

      fdCommon = "${lib.getExe pkgs.fd} --type file --follow --color always";
      fd1 = "${fdCommon} --no-hidden --ignore --ignore-file ${ignoreFile}";
      fd2 = "${fdCommon} --hidden --ignore --ignore-file ${ignoreFile}";
      fd3 = "${fdCommon} --hidden --no-ignore --ignore-file ${ignoreFile}";
      fd4 = "${fdCommon} --hidden --no-ignore";

      fdCycleTransform = pkgs.writeShellScript "fzf-fd-cycle-transform" ''
        set -euo pipefail

        case "$FZF_PROMPT" in
          "${h4}"*) echo "change-prompt(${h1})+reload(${fd1})" ;;
          "${h1}"*) echo "change-prompt(${h2})+reload(${fd2})" ;;
          "${h2}"*) echo "change-prompt(${h3})+reload(${fd3})" ;;
          "${h3}"*) echo "change-prompt(${h4})+reload(${fd4})" ;;
          *) echo "change-prompt(${h2})+reload(${fd2})" ;;
        esac
      '';

      fdPreview = pkgs.writeShellScript "fzf-fd-preview" ''
        set -euo pipefail
        mime="$(${lib.getExe pkgs.file} --mime-type -b -- "$1")"
        case "$mime" in
          image/*) ${lib.getExe pkgs.kitty} +kitten icat --transfer-mode=memory \
            --stdin=no --place="$FZF_PREVIEW_COLUMNS"x"$FZF_PREVIEW_LINES""@0x0" -- "$1" ;;
          *) ${lib.getExe pkgs.bat} --color=always --style=numbers --line-range :300 -- "$1" ;;
        esac
      '';

      historyPreview = pkgs.writeShellScript "fzf-history-preview" ''
        set -euo pipefail
        # This sed relies on specific format enforced in current version of `fzf`.
        # `fzf` may change it in the future and this preview should be adjusted accordingly.
        echo "$@" | sed -E 's|[[:blank:]][0-9]+[[:blank:]]| >  |' \
        | ${lib.getExe pkgs.bat} --language=bash --color=always --style=plain
      '';
    in
    {
      programs = {
        nix-search-tv = {
          enable = true;
        };

        tealdeer = {
          enable = true;
          settings.updates.auto_update = true;
        };

        fzf = {
          enable = true;
          enableBashIntegration = true;
          enableFishIntegration = true;
          enableZshIntegration = true;

          defaultOptions = [
            "--ansi"
            "--style=full"
            "--bind=ctrl-u:half-page-up"
            "--bind=ctrl-d:half-page-down"
            "--bind=ctrl-b:preview-page-up"
            "--bind=ctrl-f:preview-page-down"
            "--bind=ctrl-g:'change-preview-window(down|right|hidden)'"
            "--cycle"
            "--height=100%"
            "--layout=reverse"
            "--marker=''"
            "--multi"
            "--preview-window='right,60%,wrap,<90(down,60%,wrap)'"
            "--input-label=' Input '"
          ];

          historyWidgetOptions = [
            "--prompt='  > '"
            "--scheme=history"
            "--preview='${historyPreview} {}'"
            # Note: alternative layout (`<1(...)` syntax) for `--preview-window` here is required.
            # Without it, `fzf` ignores custom layout from this CLI and applies defaultOptions for some reason.
            "--preview-window='down,5,wrap,<1(down,5,wrap)'"
          ];

          fileWidgetCommand = fd1;
          fileWidgetOptions = [
            "--prompt='${h1}'"
            "--preview='${fdPreview} {}'"
            "--bind='ctrl-t:transform:${fdCycleTransform}'"
            "--bind='ctrl-o:execute(nvim {})'"
          ];
        };

        fish.interactiveShellInit =
          # fish
          ''
            for mode in default insert
              bind --mode $mode ctrl-o "commandline -f cancel; ${nsScript}; echo; commandline -f repaint"
              bind --mode $mode ctrl-q "commandline -f cancel; ${rgScript}; commandline -f repaint"
              bind --mode $mode ctrl-v "commandline -f cancel; ${tldrScript}; echo; commandline -f repaint"
              bind --mode $mode ctrl-x "commandline -f cancel; ${psScript}; echo; commandline -f repaint"
            end
          '';

        bash.initExtra = # bash
          ''
            bind -x '"\C-o": "${nsScript}"'
            bind -x '"\C-q": "${rgScript}"'
            bind -x '"\C-v": "${tldrScript}"'
            bind -x '"\C-x": "${psScript}"'
          '';

        zsh.initContent =
          # zsh
          ''
            function _fzf_ns_widget() { ${nsScript}; zle reset-prompt }
            zle -N _fzf_ns_widget
            bindkey '^o' _fzf_ns_widget

            function _fzf_rg_widget() { ${rgScript}; zle reset-prompt }
            zle -N _fzf_rg_widget
            bindkey '^q' _fzf_rg_widget

            function _fzf_tldr_widget() { ${tldrScript}; zle reset-prompt }
            zle -N _fzf_tldr_widget
            bindkey '^v' _fzf_tldr_widget

            # ctrl-x is a prefix key in zsh (exchange-point-and-mark / execute-named-cmd)
            # and overriding it would break zsh line-editing conventions.
          '';

        nushell.extraConfig = # nu
          ''
            $env.config.keybindings = ($env.config.keybindings | append [
              {
                name: fzf_ns
                modifier: control
                keycode: char_o
                mode: [emacs, vi_normal, vi_insert]
                event: { send: ExecuteHostCommand cmd: "${nsScript}" }
              }
              {
                name: fzf_rg
                modifier: control
                keycode: char_q
                mode: [emacs, vi_normal, vi_insert]
                event: { send: ExecuteHostCommand cmd: "${rgScript}" }
              }
              {
                name: fzf_tldr
                modifier: control
                keycode: char_v
                mode: [emacs, vi_normal, vi_insert]
                event: { send: ExecuteHostCommand cmd: "${tldrScript}" }
              }
              {
                name: fzf_ps
                modifier: control
                keycode: char_x
                mode: [emacs, vi_normal, vi_insert]
                event: { send: ExecuteHostCommand cmd: "${psScript}" }
              }
            ])
          '';
      };
    };
}
