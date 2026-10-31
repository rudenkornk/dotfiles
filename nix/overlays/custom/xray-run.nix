final: _prev:

final.writeShellApplication {
  name = "xray-run";
  runtimeInputs = [
    final.coreutils
    final.iproute2
    final.iptables
    final.jq
    final.sops
    final.systemd
    final.tmux
    final.util-linux
    final.unstable.xray
  ];
  text =
    final.lib.replaceStrings
      [ "@config@" "@profiles@" ]
      [ "${final.custom.xray-config}/config.json" "${final.locallib.secrets}/vpn" ]
      (builtins.readFile ./scripts/xray/run.sh);
}
