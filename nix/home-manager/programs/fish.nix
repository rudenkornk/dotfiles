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
        # It would be nice to use `builtins.readFile (pkgs.replaceVars ...)` here,
        # but it causes errors during `nix flake check --no-build` in a fresh environment,
        # since `builtins.readFile` expects a valid existing path, which is not yet ready at
        # evaluation time:
        # "error: path '/nix/store/...-ldaps.fish.drv' is not valid"
        body =
          pkgs.lib.replaceStrings
            [ "@ldap_auth@" "@jq@" "@sops-cached@" ]
            [ "${../secrets/ldap.auth.sops.json}" "${pkgs.jq}" "${pkgs.sops-cached}" ]
            (builtins.readFile ./fish/functions/ldaps.fish);
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
