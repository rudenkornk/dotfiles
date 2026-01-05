_:

{
  home = {
    shellAliases =
      let
        eza_common_args = "eza --classify --icons --all --group-directories-first --long --header --tree";
        eza_long_args = "--binary --group --smart-group --links --inode --modified --created --accessed --time-style relative --flags --blocksize";
      in
      {
        b = "bat";
        d = "docker";
        g = "git";
        l = "eza --classify --icons --all --group-directories-first";
        lg = "${eza_common_args} --level 1 --git-ignore";
        lgs = "${eza_common_args} --level 1 --git-ignore --total-size --sort size";
        ll = "${eza_common_args} --level 1";
        lll = "${eza_common_args} --level 1 ${eza_long_args}";
        llls = "${eza_common_args} --level 1 ${eza_long_args} --total-size --sort size";
        lls = "${eza_common_args} --level 1 --total-size --sort size";
        lt = "${eza_common_args} --level 2";
        lt3 = "${eza_common_args} --level 3";
        lts = "${eza_common_args} --level 2 --total-size --sort size";
        p = "podman";
        v = "nvim";
        vd = "nvim -d";
        nix-search-tv = ''command nix-search-tv print | fzf --prompt="Search NixOS> " --preview 'command nix-search-tv preview {}' --scheme history'';
        rvim =
          # Disable network.
          "unshare --net "
          +
            # Prevent 'Operation not permitted' error.
            # Appears as pseudo-root in environment.
            # https://unix.stackexchange.com/a/370484/500020
            "--map-root-user "
          + "vim "
          +
            # Restricted mode.
            "-Z "
          +
            # Disable all config files.
            "-u DEFAULTS "
          +
            # Disable history (`:help shada`).
            "-i NONE "
          +
            # Disable swap files.
            "-n";
      };

    sessionVariables = {
      MANPAGER = "bat --plain --language man";
      SOPS_EDITOR = "unshare --net --map-root-user vim -Z -u DEFAULTS -i NONE -n";
    };
  };

}
