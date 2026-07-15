{
  pkgs,
  config,
  lib,
  user,
  ...
}:

# CLI AI tools.
{
  home.packages = with pkgs; [
    (locallib.with_secrets { pkg = aider-chat-full; })
    (locallib.with_secrets { pkg = claude-code; })
    (locallib.with_secrets { pkg = codex; })
    (locallib.with_secrets { pkg = cursor-cli; })
    (locallib.with_secrets { pkg = gemini-cli; })
    (locallib.with_secrets {
      pkg = nur.repos.charmbracelet.crush;
      binary = "crush";
    })
    (locallib.with_secrets { pkg = unstable.opencode; })
    (locallib.with_secrets { pkg = qwen-code; })

    custom.playwright-cli
  ];

  xdg = {
    configFile =
      { }
      // lib.optionalAttrs (user.userkind == "default") {
        "opencode/opencode.jsonc".source = ./opencode.jsonc;
      };

    dataFile = {
      # W/A for https://github.com/anomalyco/opencode/issues/16885
      "opencode/opencode.db".source =
        config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/opencode/opencode-stable.db";
    };
  };

  local = {
    secrets.links =
      { }
      // lib.optionalAttrs (user.userkind == "corp") {
        "${config.xdg.dataHome}/opencode/auth.json".source =
          pkgs.locallib.secrets + /corp/opencode.auth.json.sops;
        "${config.xdg.configHome}/opencode/opencode.jsonc".source =
          pkgs.locallib.secrets + /corp/opencode.jsonc.sops;
      };
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
