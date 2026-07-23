{ pkgs, ... }:

let
  ignoreFile = toString ./fzf/ignore;

  h1 = "[1/4]  > ";
  h2 = "[2/4]  󰘓 > ";
  h3 = "[3/4]  󰘓  > ";
  h4 = "[4/4]  󰘓 󰘓  > ";

  # ── ctrl-t: fd search ────────────────────────────────────────────────

  fdCommon = "${pkgs.fd}/bin/fd --type file --follow --color always";
  fd1 = "${fdCommon} --no-hidden --ignore --ignore-file ${ignoreFile}";
  fd2 = "${fdCommon} --hidden --ignore --ignore-file ${ignoreFile}";
  fd3 = "${fdCommon} --hidden --no-ignore --ignore-file ${ignoreFile}";
  fd4 = "${fdCommon} --hidden --no-ignore";

  fdCycleTransform = pkgs.writeShellScript "fzf-fd-cycle-transform" ''
    set -euo pipefail

    case "$FZF_PROMPT" in
      "${h4}"*) echo "change-prompt(${h1})+reload(${fd1})" ;;
      "${h1}"*) echo "change-prompt(${h2})+reload(${fd2})" ;;
      "${h2}"*) echo "change-prompt(${h3})+reload(${fd3})" ;;
      "${h3}"*) echo "change-prompt(${h4})+reload(${fd4})" ;;
      *) echo "change-prompt(${h2})+reload(${fd2})" ;;
    esac
  '';

  fdPreview = pkgs.writeShellScript "fzf-fd-preview" ''
    set -euo pipefail
    mime="$(${pkgs.file}/bin/file --mime-type -b -- "$1")"
    case "$mime" in
      image/*) ${pkgs.kitty}/bin/kitty +kitten icat --transfer-mode=memory \
        --stdin=no --place="$FZF_PREVIEW_COLUMNS"x"$FZF_PREVIEW_LINES""@0x0" -- "$1" ;;
      *) ${pkgs.bat}/bin/bat --color=always --style=numbers --line-range :300 -- "$1" ;;
    esac
  '';

  # ── ctrl-q: ripgrep search ────────────────────────────────────────────────

  rgCommon =
    "${pkgs.ripgrep}/bin/rg "
    + "--column "
    + "--line-number "
    + "--no-heading "
    + "--smart-case "
    + "--follow "
    + "--colors 'match:fg:white' "
    + "--colors 'path:fg:blue' "
    + "--color=always";
  rg1 = "${rgCommon} --ignore-file ${ignoreFile}";
  rg2 = "${rgCommon} --hidden --ignore-file ${ignoreFile}";
  rg3 = "${rgCommon} --hidden --no-ignore --ignore-file ${ignoreFile}";
  rg4 = "${rgCommon} --hidden --no-ignore";

  rgCycleTransform = pkgs.writeShellScript "fzf-rg-cycle-transform" ''
    set -euo pipefail

    case "$FZF_PROMPT" in
      "${h4}"*) echo "change-prompt(${h1})+reload(${rg1} -- {q} || true)" ;;
      "${h1}"*) echo "change-prompt(${h2})+reload(${rg2} -- {q} || true)" ;;
      "${h2}"*) echo "change-prompt(${h3})+reload(${rg3} -- {q} || true)" ;;
      "${h3}"*) echo "change-prompt(${h4})+reload(${rg4} -- {q} || true)" ;;
      *) echo "change-prompt(${h2})+reload(${rg2} -- {q} || true)" ;;
    esac
  '';

  rgBatPreview = "${pkgs.bat}/bin/bat --color=always --style=numbers --highlight-line {2} {1}";

  rgScript = pkgs.writeShellScript "fzf-rg" ''
    set -euo pipefail

    ${pkgs.fzf}/bin/fzf \
      --disabled \
      --prompt='${h1}' \
      --bind "start:reload:${rg1} -- {q} || true" \
      --bind "change:reload:sleep 0.05; ${rg1} -- {q} || true" \
      --bind "ctrl-q:transform:${rgCycleTransform}" \
      --delimiter : \
      --preview '${rgBatPreview}' \
      --preview-window='right,60%,wrap,+{2}+3/3,~3,<90(down,60%,wrap,+{2}+3/3,~3)' \
      --bind 'ctrl-o:execute(nvim {1} +{2})' \
      --bind 'enter:execute(nvim {1} +{2})'
  '';

  historyPreview = pkgs.writeShellScript "fzf-history-preview" ''
    set -euo pipefail
    # This sed relies on specific format enforced in current version of `fzf`.
    # `fzf` may change it in the future and this preview should be adjusted accordingly.
    echo "$@" | sed -E 's|[[:blank:]][0-9]+[[:blank:]]| >  |' \
    | ${pkgs.bat}/bin/bat --language=bash --color=always --style=plain
  '';

  # ── ctrl-o: nix-search-tv ────────────────────────────────────────────────

  nsBin = "${pkgs.nix-search-tv}/bin/nix-search-tv";

  nsScript = pkgs.writeShellScript "fzf-ns" ''
    set -euo pipefail

    ${pkgs.fzf}/bin/fzf \
      --prompt='  > ' \
      --scheme=history \
      --bind "start:reload:${nsBin} print" \
      --bind "ctrl-v:execute-silent(${pkgs.xdg-utils}/bin/xdg-open \$(${nsBin} source {}) 2>/dev/null || true)" \
      --bind "ctrl-o:execute-silent(${pkgs.xdg-utils}/bin/xdg-open \$(${nsBin} homepage {}) 2>/dev/null || true)" \
      --preview "${nsBin} preview {}"
  '';

  # ── ctrl-v: tealdeer ─────────────────────────────────────────────────────

  tldrScript = pkgs.writeShellScript "fzf-tldr" ''
    set -euo pipefail

    ${pkgs.fzf}/bin/fzf \
      --prompt='  > ' \
      --bind "start:reload:${pkgs.tealdeer}/bin/tldr --list" \
      --preview "${pkgs.tealdeer}/bin/tldr {} | ${pkgs.bat}/bin/bat --style=plain --color=always --language=markdown"
  '';

  # ── ctrl-x: process search ────────────────────────────────────────────────

  psFormat = "pid:7,user:16,%cpu:6,%mem:5,rss:8,time:10,args";
  psPreviewFormat = "pid:7,ppid:7,user:16,%cpu:6,%mem:5,rss:8,time:10,stat:5,args";
  psAbsPathFilter = "sed -E 's| (/[^ ]*/)| |'";
  # --language=conf colors only several few lines for some reason.
  # --language=log works well, but is very slow.
  psBat = "${pkgs.bat}/bin/bat --language=bat --color=always --style=plain";
  # `--ppid 2 -p 2 --deselect` filters out kernel processes.
  psCommon = "ps --ppid 2 -p 2 --deselect -o ${psFormat}";

  ps1 = "${psCommon} --sort=-%cpu | ${psAbsPathFilter} | ${psBat}";
  ps2 = "${psCommon} --sort=-time | ${psAbsPathFilter} | ${psBat}";
  ps3 = "${psCommon} --sort=-%mem | ${psAbsPathFilter} | ${psBat}";
  ps4 = "${psCommon} --sort=comm  | ${psAbsPathFilter} | ${psBat}";
  ps5 = "${psCommon} --sort=pid   | ${psAbsPathFilter} | ${psBat}";

  psh1 = "[1/5]     > ";
  psh2 = "[2/5] 󱑁    > ";
  psh3 = "[3/5]     > ";
  psh4 = "[4/5] CMD  > ";
  psh5 = "[5/5] PID  > ";

  psPidScript = pkgs.writeShellScript "fzf-ps-pid" ''
    set -euo pipefail
    printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}'
  '';

  psPreview = pkgs.writeShellScript "fzf-ps-preview" ''
    set -euo pipefail
    pid="$(${psPidScript} "$1")"
    # -ww flag makes ps to ignore terminal width. Otherwise it will truncate them.
    ps -ww -p "$pid" -o ${psPreviewFormat} | ${psAbsPathFilter} | ${psBat} 2>/dev/null
  '';

  psCycleTransform = pkgs.writeShellScript "fzf-ps-cycle-transform" ''
    set -euo pipefail

    case "$FZF_PROMPT" in
      "${psh5}"*) echo "change-prompt(${psh1})+reload(${ps1})" ;;
      "${psh1}"*) echo "change-prompt(${psh2})+reload(${ps2})" ;;
      "${psh2}"*) echo "change-prompt(${psh3})+reload(${ps3})" ;;
      "${psh3}"*) echo "change-prompt(${psh4})+reload(${ps4})" ;;
      "${psh4}"*) echo "change-prompt(${psh5})+reload(${ps5})" ;;
      *) echo "change-prompt(${psh2})+reload(${ps2})" ;;
    esac
  '';

  psReloadTransform = pkgs.writeShellScript "fzf-ps-reload-transform" ''
    set -euo pipefail

    case "$FZF_PROMPT" in
      "${psh1}"*) echo "reload(${ps1})" ;;
      "${psh2}"*) echo "reload(${ps2})" ;;
      "${psh3}"*) echo "reload(${ps3})" ;;
      "${psh4}"*) echo "reload(${ps4})" ;;
      "${psh5}"*) echo "reload(${ps5})" ;;
      *) echo "reload(${ps2})" ;;
    esac
  '';

  psSignalScript = pkgs.writeShellScript "fzf-ps-signal" ''
    set -euo pipefail
    pid="$(${psPidScript} "$1")"

    signals="$(printf '%s\n' \
      '15  SIGTERM     graceful stop' \
      ' 9  SIGKILL     force kill' \
      ' 1  SIGHUP      reload config / hangup' \
      ' 2  SIGINT      interrupt (ctrl-c)' \
      ' 3  SIGQUIT     quit and dump core' \
      ' 4  SIGILL      illegal instruction' \
      ' 5  SIGTRAP     trace/breakpoint trap' \
      ' 6  SIGABRT     abort' \
      ' 7  SIGBUS      bus error' \
      ' 8  SIGFPE      floating-point exception' \
      '10  SIGUSR1     user-defined signal 1' \
      '11  SIGSEGV     segmentation fault' \
      '12  SIGUSR2     user-defined signal 2' \
      '13  SIGPIPE     broken pipe' \
      '14  SIGALRM     alarm clock' \
      '16  SIGSTKFLT   stack fault' \
      '17  SIGCHLD     child stopped or exited' \
      '18  SIGCONT     continue if stopped' \
      '19  SIGSTOP     stop process' \
      '20  SIGTSTP     stop typed at terminal' \
      '21  SIGTTIN     terminal input for background process' \
      '22  SIGTTOU     terminal output for background process' \
      '23  SIGURG      urgent condition on socket' \
      '24  SIGXCPU     CPU time limit exceeded' \
      '25  SIGXFSZ     file size limit exceeded' \
      '26  SIGVTALRM   virtual alarm clock' \
      '27  SIGPROF     profiling timer expired' \
      '28  SIGWINCH    window resize signal' \
      '29  SIGIO       I/O now possible' \
      '30  SIGPWR      power failure' \
      '31  SIGSYS      bad system call')"

    choice="$(printf '%s\n' "$signals" | ${pkgs.fzf}/bin/fzf --prompt="signal > pid $pid > " --no-multi)" || exit 0
    sig="$(printf '%s' "$choice" | awk '{print $1}')"
    kill "-$sig" "$pid"
  '';

  psEnterScript = pkgs.writeShellScript "fzf-ps-enter" ''
    set -euo pipefail
    for line in "$@"; do
      printf '%s' "$line"
      echo
    done
    for line in "$@"; do
      ${psPidScript} "$line"
    done | ${pkgs.wl-clipboard}/bin/wl-copy --primary --trim-newline
  '';

  psHtopScript = pkgs.writeShellScript "fzf-ps-htop" ''
    set -euo pipefail
    pids="$(for line in "$@"; do ${psPidScript} "$line"; done | paste -sd,)"
    ${pkgs.htop-vim}/bin/htop --pid "$pids"
  '';

  psScript = pkgs.writeShellScript "fzf-ps" ''
    set -euo pipefail

    # Note: alternative layout (`<1(...)` syntax) for `--preview-window` here is required.
    # Without it, `fzf` ignores custom layout from this CLI and applies defaultOptions for some reason.
    fzf \
      --prompt='${psh1}' \
      --bind "start:reload:${ps1}" \
      --bind "ctrl-x:transform:${psCycleTransform}" \
      --bind "ctrl-r:transform:${psReloadTransform}" \
      --bind "enter:become(${psEnterScript} {+})" \
      --bind "ctrl-o:execute(${psHtopScript} {+})" \
      --bind "ctrl-v:execute(${pkgs.htop-vim}/bin/htop)" \
      --bind "ctrl-t:execute(${psSignalScript} {})+transform:${psReloadTransform}" \
      --preview "${psPreview} {}" \
      --preview-window 'down,8,wrap,<1(down,8,wrap)' \
      --header-lines 1
  '';
in
{
  programs = {
    nix-search-tv = {
      enable = true;
    };

    tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };

    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;

      defaultOptions = [
        "--ansi"
        "--style=full"
        "--bind=ctrl-u:half-page-up"
        "--bind=ctrl-d:half-page-down"
        "--bind=ctrl-b:preview-page-up"
        "--bind=ctrl-f:preview-page-down"
        "--bind=ctrl-g:'change-preview-window(down|right|hidden)'"
        "--cycle"
        "--height=100%"
        "--layout=reverse"
        "--marker=''"
        "--multi"
        "--preview-window='right,60%,wrap,<90(down,60%,wrap)'"
        "--input-label=' Input '"
      ];

      historyWidgetOptions = [
        "--prompt='  > '"
        "--scheme=history"
        "--preview='${historyPreview} {}'"
        # Note: alternative layout (`<1(...)` syntax) for `--preview-window` here is required.
        # Without it, `fzf` ignores custom layout from this CLI and applies defaultOptions for some reason.
        "--preview-window='down,5,wrap,<1(down,5,wrap)'"
      ];

      fileWidgetCommand = fd1;
      fileWidgetOptions = [
        "--prompt='${h1}'"
        "--preview='${fdPreview} {}'"
        "--bind='ctrl-t:transform:${fdCycleTransform}'"
        "--bind='ctrl-o:execute(nvim {})'"
      ];
    };

    fish.interactiveShellInit =
      # fish
      ''
        for mode in default insert
          bind --mode $mode ctrl-o "commandline -f cancel; ${nsScript}; echo; commandline -f repaint"
          bind --mode $mode ctrl-q "commandline -f cancel; ${rgScript}; commandline -f repaint"
          bind --mode $mode ctrl-v "commandline -f cancel; ${tldrScript}; echo; commandline -f repaint"
          bind --mode $mode ctrl-x "commandline -f cancel; ${psScript}; echo; commandline -f repaint"
        end
      '';

    bash.initExtra = # bash
      ''
        bind -x '"\C-o": "${nsScript}"'
        bind -x '"\C-q": "${rgScript}"'
        bind -x '"\C-v": "${tldrScript}"'
        bind -x '"\C-x": "${psScript}"'
      '';

    zsh.initContent =
      # zsh
      ''
        function _fzf_ns_widget() { ${nsScript}; zle reset-prompt }
        zle -N _fzf_ns_widget
        bindkey '^o' _fzf_ns_widget

        function _fzf_rg_widget() { ${rgScript}; zle reset-prompt }
        zle -N _fzf_rg_widget
        bindkey '^q' _fzf_rg_widget

        function _fzf_tldr_widget() { ${tldrScript}; zle reset-prompt }
        zle -N _fzf_tldr_widget
        bindkey '^v' _fzf_tldr_widget

        # ctrl-x is a prefix key in zsh (exchange-point-and-mark / execute-named-cmd)
        # and overriding it would break zsh line-editing conventions.
      '';

    nushell.extraConfig = # nu
      ''
        $env.config.keybindings = ($env.config.keybindings | append [
          {
            name: fzf_ns
            modifier: control
            keycode: char_o
            mode: [emacs, vi_normal, vi_insert]
            event: { send: ExecuteHostCommand cmd: "${nsScript}" }
          }
          {
            name: fzf_rg
            modifier: control
            keycode: char_q
            mode: [emacs, vi_normal, vi_insert]
            event: { send: ExecuteHostCommand cmd: "${rgScript}" }
          }
          {
            name: fzf_tldr
            modifier: control
            keycode: char_v
            mode: [emacs, vi_normal, vi_insert]
            event: { send: ExecuteHostCommand cmd: "${tldrScript}" }
          }
          {
            name: fzf_ps
            modifier: control
            keycode: char_x
            mode: [emacs, vi_normal, vi_insert]
            event: { send: ExecuteHostCommand cmd: "${psScript}" }
          }
        ])
      '';
  };
}
