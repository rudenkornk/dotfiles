# oh-my-posh prompt. bash/zsh/nushell keep the home-manager integration;
# the wrapped fish gets its init as a baked snippet.
{
  flake = {
    wrappers.fish =
      { pkgs, lib, ... }:
      let
        fishlib = import ./_fish/lib.nix;
      in
      {
        plugins = [
          (fishlib.mkSnippet pkgs "20-oh-my-posh" ''
            ${lib.getExe pkgs.oh-my-posh} init fish --config ${./_oh-my-posh/config.json} | source
          '')
        ];
      };

    modules.homeManager.base = _: {
      programs.oh-my-posh = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = false; # Handled by the wrapped fish snippet above.
        enableNushellIntegration = true;
        enableZshIntegration = true;
        configFile = ./_oh-my-posh/config.json;
      };
    };
  };
}
