{ pkgs, config, ... }:

# CLI AI tools.

let
  skills = {
    ast-grep = "${pkgs.custom.ast-grep-skill}/share/skills/ast-grep";
    playwright-cli = "${pkgs.custom.playwright-cli}/share/skills/playwright-cli";
  };
in
{
  home.packages = with pkgs; [
    (locallib.with_secrets { pkg = aider-chat-full; })
    (locallib.with_secrets { pkg = unstable.claude-code; })
    (locallib.with_secrets { pkg = unstable.codex; })
    (locallib.with_secrets { pkg = cursor-cli; })
    (locallib.with_secrets { pkg = gemini-cli; })
    (locallib.with_secrets {
      pkg = nur.repos.charmbracelet.crush;
      binary = "crush";
    })
    (locallib.with_secrets { pkg = unstable.opencode; })
    (locallib.with_secrets { pkg = qwen-code; })

    mcp-nixos
    custom.playwright-cli
  ];

  xdg = {
    configFile = {
      "opencode/opencode.jsonc".source = ./opencode.jsonc;
    };

    dataFile = { };
  };

  home.file =
    (pkgs.locallib.homefiles {
      inherit (config) xdg;
      path = ./configs;
    })
    # Claude Code and OpenCode read `~/.claude/skills`, Codex reads `~/.codex/skills`.
    // (pkgs.lib.concatMapAttrs (name: source: {
      ".claude/skills/${name}" = {
        inherit source;
        recursive = true;
      };
      ".codex/skills/${name}" = {
        inherit source;
        recursive = true;
      };
    }) skills);
}
