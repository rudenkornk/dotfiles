final: _prev:

# The `i-have-adhd` agent skill, which shapes assistant output for a reader with ADHD:
# lead with the next action, number multi-step work, restate progress and suppress tangents.
# Upstream ships plugin manifests for a dozen harnesses, but the skill itself is a single `SKILL.md`,
# so only `skills/i-have-adhd` is vendored, mirroring `ast-grep-skill`.
# The marketplace install route is deliberately unused, because it records itself in `~/.claude/settings.json`,
# which home-manager owns and therefore keeps read-only.
# `disable-model-invocation` in the frontmatter keeps the skill opt-in,
# so it only takes effect after an explicit `/i-have-adhd`.

final.stdenvNoCC.mkDerivation {
  pname = "i-have-adhd-skill";
  version = "0.1.0-unstable-2026-08-10";

  src = final.fetchFromGitHub {
    owner = "ayghri";
    repo = "i-have-adhd";
    rev = "2ed064090711586e0c97a2fbbf15465fe8f1808b";
    hash = "sha256-/h4HxkUbtRGoqgyFvjJrd++XmOd1KSVku5dR2/f9b/s=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/skills
    cp -r skills/i-have-adhd $out/share/skills/i-have-adhd
    runHook postInstall
  '';

  meta = {
    description = "Agent skill shaping assistant output for a reader with ADHD";
    homepage = "https://github.com/ayghri/i-have-adhd";
    license = final.lib.licenses.mit;
    platforms = final.lib.platforms.all;
  };
}
