_: final: prev: {
  custom = {
    sops-cached =
      # Simple wrapper over sops, which cache its output in tmpfs /run/user/$id/ dir.
      # This is primarily needed to avoid multiple costly decryption queries when using TPM.
      final.writeShellApplication {
        name = "sops-cached";
        runtimeInputs = [
          final.age
          final.age-plugin-tpm
          final.sops
          final.uutils-coreutils-noprefix
        ];
        text = builtins.readFile ./custom/sops-cached.sh;
      };

    throne-run = final.writeShellApplication {
      name = "throne-run";
      runtimeInputs = [ final.throne ];
      text = builtins.readFile ./custom/throne-run.sh;
    };

    sing-box-run = final.writeShellApplication {
      name = "sing-box-run";
      runtimeInputs = [
        final.bash
        final.sing-box
        final.sops
        final.tmux
      ];
      text =
        final.lib.replaceStrings
          [ "@default_config@" ]
          [ "${final.locallib.secrets + /vpn/beta.json.sops}" ]
          (builtins.readFile ./custom/sing-box-run.sh);
    };

    rvim = final.lib.hiPrio (
      final.writeShellApplication {
        name = "rvim";
        runtimeInputs = [
          final.util-linux
          final.vim
        ];
        text = builtins.readFile ./custom/rvim.sh;
      }
    );

    sops-diff = final.writeShellApplication {
      name = "sops-diff";
      runtimeInputs = [
        final.coreutils
        final.custom.rvim
        final.git
        final.sops
      ];
      text = builtins.readFile ./custom/sops-diff.sh;
    };

    ast-grep-skill = import ./custom/ast-grep-skill.nix final prev;

    comment-checker = import ./custom/comment-checker.nix final prev;

    merge-config = import ./custom/merge-config final prev;

    playwright-cli = import ./custom/playwright-cli.nix final prev;

    vim-spell = import ./custom/vim-spell.nix final prev;

    tmux-agent-status =
      let
        runtimeInputs = [
          final.curl
          final.gawk
          final.gnugrep
          final.gnused
          final.jq
          final.libnotify
          final.niri
          final.procps
          final.tmux
          final.uutils-coreutils-noprefix
        ];
        tmux-agent-label = final.writeShellApplication {
          name = "tmux-agent-label";
          inherit runtimeInputs;
          text = builtins.readFile ./custom/tmux-agent-status/tmux-agent-label.sh;
        };
        tmux-agent-status = final.writeShellApplication {
          name = "tmux-agent-status";
          inherit runtimeInputs;
          text = builtins.readFile ./custom/tmux-agent-status/tmux-agent-status.sh;
        };
        tmux-agent-install-format = final.writeShellApplication {
          name = "tmux-agent-install-format";
          inherit runtimeInputs;
          text = builtins.readFile ./custom/tmux-agent-status/tmux-agent-install-format.sh;
        };
        tmux-agent-name = final.writeShellApplication {
          name = "tmux-agent-name";
          inherit runtimeInputs;
          text =
            final.lib.replaceStrings
              [ "@codex_transcript_jq@" ]
              [ "${./custom/tmux-agent-status/codex-transcript.jq}" ]
              (builtins.readFile ./custom/tmux-agent-status/tmux-agent-name.sh);
        };
      in
      final.symlinkJoin {
        name = "tmux-agent-status";
        paths = [
          tmux-agent-label
          tmux-agent-status
          tmux-agent-install-format
          tmux-agent-name
        ];
      };
  };
}
