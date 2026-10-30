{ pkgs, wlib }:
let
  inherit (pkgs) lib;
  module = {
    imports = [ ../fzf.nix ];
    inherit pkgs;
    commands = {
      editor = "${pkgs.coreutils}/bin/true";
      imagePreview = "${pkgs.coreutils}/bin/true";
      clipboard = "${pkgs.coreutils}/bin/cat";
      privilege = "";
    };
    dependencies = {
      nixSearchTv = pkgs.unstable.nix-search-tv;
      inherit (pkgs) tealdeer;
    };
  };
  fzf = wlib.evalPackage module;
  probe = fzf.wrap {
    package = pkgs.writeShellScriptBin "fzf" ''
      printf '%s' "$FZF_DEFAULT_OPTS"
    '';
  };
  hooks =
    shell:
    pkgs.writeText "fzf-init.${shell}" (
      fzf.shellIntegrations.${shell}.earlyInteractiveInit
      + "\n"
      + fzf.shellIntegrations.${shell}.interactiveInit
    );
  bashTest = pkgs.writeText "fzf-test.bash" ''
    set -e
    set -o emacs
    unset FZF_DEFAULT_OPTS FZF_CTRL_T_COMMAND FZF_CTRL_T_OPTS FZF_CTRL_R_OPTS
    source ${hooks "bash"}
    [[ -n $FZF_DEFAULT_OPTS ]]
    bind -X | grep -q 'fzf-file-widget'
    bind -X | grep -q 'fzf-ps'
    eval "$(${lib.getExe pkgs.unstable.atuin} init bash --disable-up-arrow)"
    bind -s | grep -F '"\C-r": "\C-x\C-_A'
    bind -X | grep -q __atuin_widget_run
    FZF_DEFAULT_OPTS=""
    FZF_CTRL_T_COMMAND=""
    FZF_CTRL_T_OPTS="custom-file-options"
    FZF_CTRL_R_OPTS="custom-history-options"
    source ${hooks "bash"}
    [[ $FZF_DEFAULT_OPTS == "" && $FZF_CTRL_T_COMMAND == "" ]]
    [[ $FZF_CTRL_T_OPTS == custom-file-options && $FZF_CTRL_R_OPTS == custom-history-options ]]
  '';
  fishTest = pkgs.writeText "fzf-test.fish" ''
    set -e FZF_DEFAULT_OPTS FZF_CTRL_T_COMMAND FZF_CTRL_T_OPTS FZF_CTRL_R_OPTS
    source ${hooks "fish"}
    test -n "$FZF_DEFAULT_OPTS"; or exit 1
    bind ctrl-t | string match -q '*fzf-file-widget*'; or exit 1
    bind ctrl-x | string match -q '*fzf-ps*'; or exit 1
    ${lib.getExe pkgs.unstable.atuin} init fish --disable-up-arrow | source
    bind ctrl-r | string match -q '*atuin*'; or exit 1
    set -gx FZF_DEFAULT_OPTS ""
    set -gx FZF_CTRL_T_COMMAND ""
    set -gx FZF_CTRL_T_OPTS custom-file-options
    set -gx FZF_CTRL_R_OPTS custom-history-options
    source ${hooks "fish"}
    test "$FZF_DEFAULT_OPTS" = ""; or exit 1
    test "$FZF_CTRL_T_COMMAND" = ""; or exit 1
    test "$FZF_CTRL_T_OPTS" = custom-file-options; or exit 1
    test "$FZF_CTRL_R_OPTS" = custom-history-options; or exit 1
  '';
  zshTest = pkgs.writeText "fzf-test.zsh" ''
    set -e
    autoload -Uz compinit
    compinit -d "$TMPDIR/zcompdump"
    unset FZF_DEFAULT_OPTS FZF_CTRL_T_COMMAND FZF_CTRL_T_OPTS FZF_CTRL_R_OPTS
    source ${hooks "zsh"}
    [[ -n $FZF_DEFAULT_OPTS ]]
    bindkey '^T' | grep -q fzf-file-widget
    bindkey '^X' | grep -q _fzf_ps_widget
    set +e
    eval "$(${lib.getExe pkgs.unstable.atuin} init zsh --disable-up-arrow)"
    preexec_functions=()
    set -e
    bindkey '^R' | grep -q atuin
    FZF_DEFAULT_OPTS=""
    FZF_CTRL_T_COMMAND=""
    FZF_CTRL_T_OPTS="custom-file-options"
    FZF_CTRL_R_OPTS="custom-history-options"
    source ${hooks "zsh"}
    [[ $FZF_DEFAULT_OPTS == "" && $FZF_CTRL_T_COMMAND == "" ]]
    [[ $FZF_CTRL_T_OPTS == custom-file-options && $FZF_CTRL_R_OPTS == custom-history-options ]]
  '';
in
pkgs.runCommand "fzf-wrapper-check"
  {
    nativeBuildInputs = [
      fzf
      pkgs.bash
      pkgs.fish
      pkgs.zsh
      pkgs.nushell
      pkgs.unstable.atuin
      pkgs.util-linux
    ];
  }
  ''
      export HOME="$TMPDIR/home" TERM=xterm-256color
      mkdir -p "$HOME"
      test -n "$(env -u FZF_DEFAULT_OPTS ${lib.getExe probe})"
      test -z "$(FZF_DEFAULT_OPTS= ${lib.getExe probe})"
      test "$(FZF_DEFAULT_OPTS=custom ${lib.getExe probe})" = custom
      printf 'first\nsecond\n' | ${lib.getExe fzf} --filter=second | grep -qx second
    script --quiet --return --command 'bash --noprofile --norc -i ${bashTest}' /dev/null
    script --quiet --return --command 'fish --no-config --interactive ${fishTest}' /dev/null
    script --quiet --return --command 'zsh -f -i ${zshTest}' /dev/null
      nu --no-config-file --commands 'source ${hooks "nushell"}'
      touch "$out"
  ''
