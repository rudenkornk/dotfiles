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
    (locallib.with_secrets { pkg = opencode; })
    (locallib.with_secrets { pkg = qwen-code; })
  ];

  home.file = pkgs.locallib.homefiles {
    inherit (config) xdg;
    path = ./configs;
  };
}
