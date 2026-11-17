final: _prev:

final.runCommand "human-in-the-way" { } ''
  mkdir -p "$out/share/skills"
  cp -r ${./scripts/human-in-the-way} "$out/share/skills/human-in-the-way"
''
