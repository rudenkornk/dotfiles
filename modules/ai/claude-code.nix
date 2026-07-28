# Claude Code, wrapped with its settings, MCP servers and runtime secret env.
# `keybindings.json` and `statusline.sh` remain plain `~/.claude` files
# (Claude Code only reads them from disk); they are linked by `ai.nix`.
{ config, ... }:
let
  flakeCfg = config;
in
{
  flake = {
    wrappers.claude-code =
      {
        wlib,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [
          wlib.wrapperModules.claude-code
          ../secrets/_fragments/secret-env.nix
        ];
        package = pkgs.claude-code;
        # The upstream wrapper module strips ANTHROPIC_API_KEY by default;
        # keep the runtime-injected provider keys usable instead.
        unsetVar = lib.mkForce [ "DEV" ];
        settings = lib.importJSON ./_configs/.claude/settings.json;
        mcpConfig.nixos = {
          command = lib.getExe pkgs.mcp-nixos;
          type = "stdio";
        };
      };

    modules.homeManager.base = { pkgs, ... }: {
      home.packages = [ flakeCfg.flake.packages.${pkgs.stdenv.hostPlatform.system}.claude-code ];
    };
  };
}
