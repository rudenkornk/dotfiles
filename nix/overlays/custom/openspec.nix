final: _:

let
  # TODO: Use final.openspec after upgrading to NixOS 26.11.
  openspec = final.unstable.openspec;
  skills = [
    "openspec-explore"
    "openspec-propose"
    "openspec-apply-change"
    "openspec-update-change"
    "openspec-sync-specs"
    "openspec-archive-change"
    "openspec-verify-change"
  ];
  config = final.writeText "openspec-config.json" (
    builtins.toJSON {
      profile = "custom";
      delivery = "skills";
      workflows = [
        "explore"
        "propose"
        "apply"
        "update"
        "sync"
        "archive"
        "verify"
      ];
    }
  );
in
final.symlinkJoin {
  pname = "openspec";
  inherit (openspec) version meta;
  paths = [ openspec ];
  nativeBuildInputs = [ final.makeWrapper ];

  postBuild = ''
    set -o pipefail
    wrapProgram "$out/bin/openspec" --set OPENSPEC_TELEMETRY 0

    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/openspec"
    cp ${config} "$XDG_CONFIG_HOME/openspec/config.json"
    # OpenSpec's progress renderer hangs on Nix's zero-width build TTY.
    "$out/bin/openspec" init "$TMPDIR/project" --tools claude 2>&1 | cat

    mkdir -p "$out/share"
    cp -r "$TMPDIR/project/.claude/skills" "$out/share/skills"

    test ! -e "$TMPDIR/project/.claude/commands"
    test "$(find "$out/share/skills" -name SKILL.md | wc -l)" -eq ${toString (builtins.length skills)}
    for skill in ${final.lib.escapeShellArgs skills}; do
      grep -Fx "name: $skill" "$out/share/skills/$skill/SKILL.md"
      grep -F 'generatedBy: "${openspec.version}"' "$out/share/skills/$skill/SKILL.md"
    done
    "$out/bin/openspec" --version
    "$out/bin/openspec" --help > /dev/null
  '';

  passthru = { inherit skills; };
}
