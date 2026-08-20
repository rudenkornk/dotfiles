{ pkgs, config, ... }:

# CLI AI tools.

let
  skills = {
    ast-grep = "${pkgs.custom.ast-grep-skill}/share/skills/ast-grep";
    ast-grep-outline = "${pkgs.custom.ast-grep-skill}/share/skills/ast-grep-outline";
    playwright-cli = "${pkgs.custom.playwright-cli}/share/skills/playwright-cli";
  };
in
{
  home.packages = with pkgs; [
    (locallib.with_secrets { pkg = aider-chat-full; })
    (locallib.with_secrets { pkg = amazon-q-cli; })
    (locallib.with_secrets { pkg = cursor-cli; })
    (locallib.with_secrets { pkg = gemini-cli; })
    (locallib.with_secrets { pkg = github-copilot-cli; })
    (locallib.with_secrets { pkg = grok-cli; })
    (locallib.with_secrets { pkg = pi-coding-agent; })
    (locallib.with_secrets {
      pkg = unstable.claude-code;
      extraScript = ''
        if [[ -s "$HOME/.claude/mcp-corp.json" ]]; then
          set -- --mcp-config ${./claude.mcp.json} "$HOME/.claude/mcp-corp.json" "$@"
        else
          set -- --mcp-config ${./claude.mcp.json} "$@"
        fi
      '';
    })
    (locallib.with_secrets {
      pkg = unstable.codex;
      extraScript = ''
        set -- --profile nixos "$@"
      '';
    })
    (locallib.with_secrets {
      pkg = nur.repos.charmbracelet.crush;
      binary = "crush";
    })
    (locallib.with_secrets { pkg = unstable.opencode; })
    (locallib.with_secrets { pkg = qwen-code; })

    mcp-nixos
    custom.playwright-cli
  ];

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
      # Codex ignores symlinked `SKILL.md` files, but follows symlinked skill directories,
      # thus omitting `recursive = true` here.
      ".codex/skills/${name}".source = source;
    }) skills);
}
