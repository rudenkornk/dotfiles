# zoxide. bash/zsh/nushell keep the home-manager integration; the wrapped
# fish gets the init and the `c` helper function as a baked snippet.
{
  flake = {
    wrappers.fish =
      { pkgs, lib, ... }:
      let
        fishlib = import ../shell/_fish/lib.nix;
      in
      {
        plugins = [
          (fishlib.mkSnippet pkgs "58-zoxide" (
            ''
              ${lib.getExe pkgs.zoxide} init fish | source

              function c --wraps="z"
            ''
            + builtins.readFile ./_fish/functions/c.fish
            + ''
              end
            ''
          ))
        ];
      };

    modules.homeManager.base = _: {
      programs.zoxide = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = false; # Handled by the wrapped fish snippet above.
        enableNushellIntegration = true;
        enableZshIntegration = true;
      };
    };
  };
}
