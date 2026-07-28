# CLI AI tools, wrapped with runtime secret injection.
{ config, ... }:
let
  flakeCfg = config;
  ailib = import ./_lib.nix;
in
{
  flake = {
    wrappers = {
      aider-chat-full = ailib.mkSecretTool { package = pkgs: pkgs.aider-chat-full; };
      codex = ailib.mkSecretTool { package = pkgs: pkgs.codex; };
      cursor-cli = ailib.mkSecretTool { package = pkgs: pkgs.cursor-cli; };
      gemini-cli = ailib.mkSecretTool { package = pkgs: pkgs.gemini-cli; };
      crush = ailib.mkSecretTool {
        package = pkgs: pkgs.nur.repos.charmbracelet.crush;
        binName = "crush";
      };
      qwen-code = ailib.mkSecretTool { package = pkgs: pkgs.qwen-code; };
    };

    modules.homeManager.base =
      { config, pkgs, ... }:
      let
        wrapped = name: flakeCfg.flake.packages.${pkgs.stdenv.hostPlatform.system}.${name};
      in
      {
        home.packages = [
          (wrapped "aider-chat-full")
          (wrapped "codex")
          (wrapped "cursor-cli")
          (wrapped "gemini-cli")
          (wrapped "crush")
          (wrapped "qwen-code")

          pkgs.mcp-nixos
          pkgs.custom.playwright-cli
        ];

        home.file =
          (pkgs.locallib.homefiles {
            inherit (config) xdg;
            path = ./_configs;
          })
          // {
            ".agents/skills/playwright-cli" = {
              source = "${pkgs.custom.playwright-cli}/share/skills/playwright-cli";
              recursive = true;
            };
          };
      };
  };
}
