final: prev:
let
  version = "1.18.29"; # NOTE: Pinned ahead of `nixpkgs`, until it ships the Codex OAuth GPT-6 model filter fix.
  src = final.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-lCXlxTOhcX70jxJAbpolyGlIxQK2nst+6bFhq3Xzdmc=";
  };
in
{
  opencode = prev.opencode.overrideAttrs (
    _: prevAttrs: {
      inherit version src;
      patches = (prevAttrs.patches or [ ]) ++ [
        (final.locallib.patches + /opencode-1.18.29-thought-start-timestamp.patch)
      ];
      passthru = prevAttrs.passthru // {
        node_modules = prevAttrs.passthru.node_modules.overrideAttrs {
          outputHash = "sha256-0rpyP6nqK4FrJNjl0WV5adPjEQhe8a55RM7CgP9wlak=";
        };
      };
    }
  );
}
