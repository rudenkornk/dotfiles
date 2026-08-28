final: _prev:

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
    text = builtins.readFile ./scripts/tmux-agent-status/tmux-agent-label.sh;
  };
  tmux-agent-status = final.writeShellApplication {
    name = "tmux-agent-status";
    inherit runtimeInputs;
    text = builtins.readFile ./scripts/tmux-agent-status/tmux-agent-status.sh;
  };
  tmux-agent-install-format = final.writeShellApplication {
    name = "tmux-agent-install-format";
    inherit runtimeInputs;
    text = builtins.readFile ./scripts/tmux-agent-status/tmux-agent-install-format.sh;
  };
  tmux-agent-name = final.writeShellApplication {
    name = "tmux-agent-name";
    inherit runtimeInputs;
    text =
      final.lib.replaceStrings
        [ "@codex_transcript_jq@" ]
        [ "${./scripts/tmux-agent-status/codex-transcript.jq}" ]
        (builtins.readFile ./scripts/tmux-agent-status/tmux-agent-name.sh);
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
}
