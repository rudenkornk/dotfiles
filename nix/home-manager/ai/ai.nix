{ pkgs, ... }:

# CLI AI tools.

let
  skills = {
    ast-grep = "${pkgs.custom.ast-grep-skill}/share/skills/ast-grep";
    ast-grep-outline = "${pkgs.custom.ast-grep-skill}/share/skills/ast-grep-outline";
    playwright-cli = "${pkgs.custom.playwright-cli}/share/skills/playwright-cli";
  };

  opencode-omo = pkgs.writeShellScriptBin "opencode-omo" ''
    export OPENCODE_CONFIG=${./opencode.omo.jsonc}
    export OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=true # `omo` serves `~/.claude` through its own compatibility layer.

    # `omo` consults `PATH` for these only as a last resort, behind a Node version gate it does not need.
    export OMO_CODEGRAPH_BIN=${pkgs.unstable.codegraph}/bin/codegraph
    export OMO_AST_GREP_SG_PATH=${pkgs.ast-grep}/bin/ast-grep

    exec -a opencode-omo ${pkgs.lib.getExe pkgs.unstable.opencode} "$@"
  '';
in
{
  home = {
    sessionVariables = {
      OPENCODE_EXPERIMENTAL_LSP_TOOL = "true";
    };

    packages = with pkgs; [
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
      (locallib.with_secrets { pkg = opencode-omo; })
      (locallib.with_secrets { pkg = qwen-code; })

      mcp-nixos
      custom.comment-checker
      custom.playwright-cli
      unstable.codegraph
    ];
  };

  local = {
    home.file = {
      ".".source = ./configs;
    }
    # Claude Code and OpenCode read `~/.claude/skills`, Codex reads `~/.codex/skills`.
    // pkgs.lib.concatMapAttrs (name: source: {
      ".claude/skills/${name}".source = source;
      # Codex ignores symlinked `SKILL.md` files, but follows symlinked skill directories,
      # thus disabling `recursive` here.
      ".codex/skills/${name}" = {
        inherit source;
        recursive = false;
      };
    }) skills;
  };
}
