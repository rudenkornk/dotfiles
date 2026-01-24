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
          with pkgs;
          lib.replaceStrings
            [ "@corp_auth@" "@jq@" "@sops-cached@" "@openldap@" ]
            [ "${../../secrets/corp_auth.sops.json}" "${jq}" "${sops-cached}" "${openldap}" ]
            (builtins.readFile ./fish/functions/ldaps.fish);
        wraps = "ldapsearch";
      };
      sops = {
        body = builtins.readFile ./fish/functions/sops.fish;
        wraps = "sops";
      };
      openconnect_corp = {
        body =
          with pkgs;
          lib.replaceStrings
            [ "@corp_auth@" "@jq@" "@sops-cached@" "@openconnect@" ]
            [ "${../../secrets/corp_auth.sops.json}" "${jq}" "${sops-cached}" "${openconnect}" ]
            (builtins.readFile ./fish/functions/openconnect_corp.fish);
        wraps = "openconnect";
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
    plugins = with pkgs.fishPlugins; [
      {
        name = "autopair";
        inherit (autopair) src;
      }
      {
        name = "puffer";
        inherit (puffer) src;
      }
      {
        name = "fzf";
        src = pkgs.applyPatches {
          inherit (fzf-fish) src;
          patches = [ ./fish/fzf.fish.patch ];
        };
      }
    ];
  };
}
