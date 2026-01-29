{ pkgs, ... }:

# Remote desktop, corporate tooling & VPNs.
{
  home.packages = with pkgs; [
    coder
    openconnect
    openldap
    openssh
    openvpn
    throne
  ];

  home = {
    file = {
      ".ssh" = {
        source = pkgs.locallib.secrets + /ssh;
        recursive = true;
      };
    };

    shellAliases = {
      Throne =
        # "Warm up" `sudo` before running it under `nohup`, to avoid failure.
        ''sudo echo "" && ''
        + "nohup sudo Throne "
        # Redirect both stdout and stderr to a log file.
        # Otherwise, `nohup` will create unnecessary `nohup.out` in cwd.
        + "&> /tmp/Throne_$USER.log &; "
        + "disown "
        +
          # `#` at the end is significant -- fish wrapper will add `$args` at the end
          # (since it will be a function in fish), which will mess up with `&` detachment.
          # Adding `#` allows to ignore added `$args`.
          "#";
    };
  };
}
