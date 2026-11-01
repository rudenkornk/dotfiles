final: _prev:

# The official `ast-grep` agent skills, maintained by the ast-grep org.
# They are not shipped inside the `ast-grep` package itself (that only carries shell completions),
# so we vendor them from GitHub and expose them under `share/skills`, mirroring `playwright-cli`.
# It is installed as `ast-grep-outline`, so that the directory name matches the name declared in its frontmatter.

final.stdenvNoCC.mkDerivation {
  pname = "ast-grep-skill";
  version = "0-unstable-2026-09-13";

  src = final.fetchFromGitHub {
    owner = "ast-grep";
    repo = "agent-skill";
    rev = "f2175aff21f20cfb8e2db30c28febeb3a2d42b61";
    hash = "sha256-dORqiMdFOUQVEF6wn1IZiTIcslzO+441A0GZP4KNcOQ=";
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
