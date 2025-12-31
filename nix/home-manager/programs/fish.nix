{ pkgs, inputs, ... }:

{
  programs.fish = {
    enable = true;

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
      };
    functions = {
      c = {
        wraps = "z";
        body = builtins.readFile ./fish/functions/c.fish;
      };
      fish_greeting = {
        body = "";
      };
      fish_remove_path = {
        body = builtins.readFile ./fish/functions/fish_remove_path.fish;
        description = "Shows user added PATH entries and removes the selected one";
      };
      ldaps = {
        body = builtins.readFile (
          pkgs.replaceVars ./fish/functions/ldaps.fish {
            # Here we could use a bit simpler form like this:
            # proxy = ../secrets/proxy.sh.sops;
            # (I.e. without quotes and ${}), but that issues a warning:
            # warning: Using 'builtins.derivation' to create a derivation named 'nvim.fish'
            #   that references the store path without a proper context.
            ldap_auth = "${../secrets/ldap.auth.sops.json}";
          }
        );
        wraps = "ldapsearch";
      };
      rvim = {
        body = builtins.readFile ./fish/functions/rvim.fish;
        wraps = "vim";
      };
      sops = {
        body = builtins.readFile ./fish/functions/sops.fish;
        wraps = "sops";
      };
    };
    interactiveShellInit = ''
      source ${./fish/conf.d/fzf.fish}
      source ${./fish/conf.d/neovim.fish}
      source ${./fish/conf.d/python.fish}
      source ${./fish/conf.d/shell_utils.fish}
      source ${./fish/conf.d/ssh_client.fish}
      source ${./fish/conf.d/tmux.fish}
    '';
    plugins = [
      {
        name = "autopair";
        inherit (pkgs.fishPlugins.autopair) src;
      }
      {
        name = "puffer";
        inherit (pkgs.fishPlugins.puffer) src;
      }
      {
        name = "fzf";
        # git format-patch @~1
        src = pkgs.runCommand "patched_fzf" { } ''
          cp -r ${pkgs.fishPlugins.fzf-fish.src} $out
          chmod -R +w $out
          cd $out
          patch -p1 < ${./fish/fzf.fish.patch}
        '';
      }
    ];
  };
}
