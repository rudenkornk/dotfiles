{ pkgs, ... }:

# VPN clients and related tooling.
{
  home.packages = with pkgs; [
    openconnect
    openvpn
    sing-box
    throne
  ];

  programs.fish = {
    functions = {
      openconnect_corp = {
        body =
          with pkgs;
          lib.replaceStrings
            [ "@corp_auth@" "@jq@" "@sops-cached@" "@openconnect@" ]
            [ "${pkgs.locallib.secrets + /corp_auth.sops.json}" "${jq}" "${sops-cached}" "${openconnect}" ]
            (builtins.readFile ./fish/functions/openconnect_corp.fish);
        wraps = "openconnect";
      };
      ThroneRun = {
        body =
          with pkgs;
          lib.replaceStrings [ "@throne@" ] [ "${throne}" ] (
            builtins.readFile ./fish/functions/ThroneRun.fish
          );
        wraps = "Throne";
      };
      sing-box-run = {
        body =
          with pkgs;
          lib.replaceStrings
            [ "@bash@" "@sing-box@" "@sops@" "@default_config@" ]
            [ "${bash}" "${sing-box}" "${sops}" "${pkgs.locallib.secrets + /vpn/beta.json.sops}" ]
            (builtins.readFile ./fish/functions/sing-box-run.fish);
        wraps = "sing-box";
      };
    };
  };
}
