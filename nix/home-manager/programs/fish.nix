{ pkgs, inputs, ... }:

{
  programs.fish = {
    enable = true;

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
            inherit (pkgs) jq sops-cached;
          }
        );
        wraps = "ldapsearch";
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
