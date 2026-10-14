final: _prev:

let
  launcher = final.writeShellApplication {
    name = "keymap-defaults";
    runtimeInputs = [ final.coreutils ];
    text = ''
      exec cat "$(dirname "$(readlink -f "$0")")/../share/keymap-defaults/$1"
    '';
  };
in
final.runCommand "keymap-defaults"
  {
    meta = {
      description = "Pinned upstream keybinding catalogs for dotfiles configuration generation";
      license = with final.lib.licenses; [
        mit
        asl20
      ];
      mainProgram = "keymap-defaults";
      platforms = final.lib.platforms.all;
    };
  }
  ''
    mkdir -p "$out/bin" "$out/share/keymap-defaults"
    cp ${launcher}/bin/keymap-defaults "$out/bin/keymap-defaults"
    cp ${final.yazi-unwrapped.passthru.srcs.code_src}/yazi-config/preset/keymap-default.toml \
      "$out/share/keymap-defaults/yazi.toml"
    cp ${final.unstable.opencode.src}/packages/tui/src/config/keybind.ts \
      "$out/share/keymap-defaults/opencode.ts"
    cp ${final.gemini-cli.src}/docs/reference/keyboard-shortcuts.md \
      "$out/share/keymap-defaults/gemini.md"
  ''
