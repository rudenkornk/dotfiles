# fish, wrapped with plugins, functions and all shell configuration baked in.
# Other feature modules contribute their own snippets and aliases to
# `flake.wrappers.fish`; this file owns the shell core.
{ config, ... }:
let
  flakeCfg = config;
  fishlib = import ./_fish/lib.nix;
in
{
  flake = {
    wrappers.fish =
      {
        wlib,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [ wlib.wrapperModules.fish ];
        package = pkgs.fish;
        # `--no-config` would also skip fish's own init, which populates the
        # default completion and function paths; without them tab completion
        # dies entirely. All actual configuration is still baked below.
        flags."--no-config" = lib.mkForce false;
        # Also cover the top-level layout used by `fishPlugins.*.src` sources.
        # (Per-plugin dir overrides trip a nested-list bug in the upstream
        # module, so the shared dir list is extended instead; empty globs for
        # snippet-only plugins are harmless.)
        pluginConfigDirs = [
          "share/fish/vendor_functions.d"
          "etc/fish/functions"
          "share/fish/vendor_conf.d"
          "etc/fish/conf.d"
          "functions"
          "conf.d"
        ];
        pluginCompletionDirs = [
          "share/fish/vendor_completions.d"
          "share/fish/completions"
          "completions"
        ];
        plugins = [
          { src = pkgs.fishPlugins.autopair.src; }
          { src = pkgs.fishPlugins.puffer.src; }
          (fishlib.mkSnippet pkgs "10-session-vars" ''
            # Load the home-manager session variables when they were not already
            # applied by the login shell (e.g. a bare `nix run` fish).
            if test -r ~/.nix-profile/etc/profile.d/hm-session-vars.fish
              source ~/.nix-profile/etc/profile.d/hm-session-vars.fish
            end
          '')
          (fishlib.mkSnippet pkgs "15-functions" ''
            function fish_greeting
            end

            function fish_remove_path --description="Shows user added PATH entries and removes the selected one"
            ${builtins.readFile ./_fish/functions/fish_remove_path.fish}
            end
          '')
          (fishlib.mkSnippet pkgs "50-shell-utils" (builtins.readFile ./_fish/conf.d/shell_utils.fish))
        ];
      };

    modules.homeManager.base = { pkgs, ... }: {
      home.packages = [ flakeCfg.flake.packages.${pkgs.stdenv.hostPlatform.system}.fish ];
    };
  };
}
