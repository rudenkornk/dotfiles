{ pkgs, config, ... }:

# CLI AI tools.
{
  home.packages = with pkgs; [
    (locallib.with_secrets { pkg = aider-chat-full; })
    (locallib.with_secrets { pkg = claude-code; })
    (locallib.with_secrets { pkg = codex; })
    (locallib.with_secrets { pkg = cursor-cli; })
    (locallib.with_secrets { pkg = gemini-cli; })
    (locallib.with_secrets { pkg = github-copilot-cli; })
    (locallib.with_secrets {
      pkg = nur.repos.charmbracelet.crush;
      binary = "crush";
    })
    (locallib.with_secrets { pkg = unstable.opencode; })
    (locallib.with_secrets { pkg = qwen-code; })
  ];

  home.file =
    pkgs.locallib.homefiles {
      inherit (config) xdg;
      path = ./configs;
    }
    // {
      # W/A for https://github.com/anomalyco/opencode/issues/16885
      "${config.xdg.dataHome}/opencode/opencode.db".source =
        config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/opencode/opencode-stable.db";
    };
}
