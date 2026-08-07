final: _prev:

# The official `ast-grep` agent skill, maintained by the ast-grep org.
# It is not shipped inside the `ast-grep` package itself (that only carries shell completions),
# so we vendor it from GitHub and expose it under `share/skills`, mirroring `playwright-cli`.
# Only the `ast-grep` search skill is installed; the repo's `outline` skill relies on an
# `ast-grep outline` subcommand that does not exist in our pinned ast-grep, so it is left out.

final.stdenvNoCC.mkDerivation {
  pname = "ast-grep-skill";
  version = "0-unstable-2026-07-03";

  src = final.fetchFromGitHub {
    owner = "ast-grep";
    repo = "agent-skill";
    rev = "c2a9bc154f4ffe08b25d28d5e852dfac8c0d0d8a";
    hash = "sha256-awochSE2OupbsmaGx0xc7wHf0ovVMSdtHv4gZAGWOus=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/skills
    cp -r ast-grep/skills/ast-grep $out/share/skills/ast-grep
    runHook postInstall
  '';

  meta = {
    description = "Official ast-grep agent skill for structural code search and analysis";
    homepage = "https://github.com/ast-grep/agent-skill";
    # Upstream ships no license file, so default copyright applies; vendored for personal use only.
    # Left commented out so the skill is not gated behind the unfree allowlist.
    # license = final.lib.licenses.unfree;
    platforms = final.lib.platforms.all;
  };
}
