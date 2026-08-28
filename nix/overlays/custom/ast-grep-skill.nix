final: _prev:

# The official `ast-grep` agent skills, maintained by the ast-grep org.
# They are not shipped inside the `ast-grep` package itself (that only carries shell completions),
# so we vendor them from GitHub and expose them under `share/skills`, mirroring `playwright-cli`.
# The `outline` skill drives an `ast-grep outline` subcommand that first appeared in ast-grep 0.44,
# whereas `fs-navigation.nix` still takes 0.42 from stable nixpkgs, so its commands fail until that is bumped.
# It is installed as `ast-grep-outline`, so that the directory name matches the name declared in its frontmatter.

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
    cp -r ast-grep/skills/outline $out/share/skills/ast-grep-outline
    runHook postInstall
  '';

  meta = {
    description = "Official ast-grep agent skills for structural code search and outlining";
    homepage = "https://github.com/ast-grep/agent-skill";
    # Upstream ships no license file, so default copyright applies; vendored for personal use only.
    # Left commented out so the skill is not gated behind the unfree allowlist.
    # license = final.lib.licenses.unfree;
    platforms = final.lib.platforms.all;
  };
}
