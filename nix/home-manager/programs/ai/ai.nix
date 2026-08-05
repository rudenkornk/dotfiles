{ pkgs, config, ... }:

# CLI AI tools.
{
  home.packages = with pkgs; [
    (locallib.with_secrets { pkg = aider-chat-full; })
    (locallib.with_secrets { pkg = unstable.claude-code; })
    (locallib.with_secrets { pkg = codex; })
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
    // {
      ".agents/skills/playwright-cli" = {
        source = "${pkgs.custom.playwright-cli}/share/skills/playwright-cli";
        recursive = true;
      };
    };
}
