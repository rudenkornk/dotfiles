{
  flake.modules.nixos.base = { pkgs, ... }: {
    # https://wiki.nixos.org/wiki/Printing
    services = {
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
      printing = {
        enable = true;
        drivers = with pkgs; [
          cups-browsed
          cups-filters
        ];

        # Security issues?
        # https://discourse.nixos.org/t/newly-announced-vulnerabilities-in-cups/52771
        browsed.enable = false;
        browsing = false; # Default value.
        defaultShared = false; # Default value.
        startWhenNeeded = true; # Default value.
      };
    };
  };
}
