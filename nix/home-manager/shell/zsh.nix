{ pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    autocd = true;
    defaultKeymap = "emacs";
    setOptions = [
      "IGNORE_EOF" # Ignore ctrl-d to exit shell.
      "NO_FLOW_CONTROL" # Let Ctrl-Q reach shell keybindings.
    ];
    syntaxHighlighting = {
      enable = true;
      styles.comment = "fg=250";
    };
    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
        "match_prev_cmd"
      ];
    };
    history = {
      append = true;
      extended = true;
      size = 100000;
    };
    initContent = lib.mkMerge [
      (lib.mkOrder 550 # zsh
        ''
          zmodload zsh/complist
        ''
      )
      # zsh
      ''
        LISTMAX=500
        zstyle ':completion:*' menu select
        zstyle ':completion:*' special-dirs true
        zstyle ':completion:*:descriptions' format '%d'
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' matcher-list "" \
          'm:{a-zA-Z}={A-Za-z}' \
          'm:{a-zA-Z}={A-Za-z} r:|[._-]=* r:|=*'

        function _complete_parent_directory() {
          local -a words=("''${(@z)LBUFFER}")
          if [[ $RBUFFER = (|[[:space:]]*) && ''${words[-1]} = (..|*/..) ]]; then
            LBUFFER+=/
          fi
          zle expand-or-complete
        }
        zle -N _complete_parent_directory
        bindkey -M emacs '^I' _complete_parent_directory

        bindkey -M menuselect '^I' menu-complete
        bindkey -M menuselect '\e[Z' reverse-menu-complete
        bindkey -M menuselect '^N' menu-complete
        bindkey -M menuselect '^P' reverse-menu-complete
        bindkey -M menuselect '^M' accept-line
        bindkey -M menuselect '^C' send-break
        bindkey -M menuselect '^G' send-break

        WORDCHARS=''${WORDCHARS//\/}
        bindkey -M emacs '^Z' undo
        bindkey -M emacs ' ' magic-space

        source ${pkgs.custom.zsh-manydots-magic}/manydots-magic
        # Syntax highlighting cannot invoke the plugin's alias of the builtin deletion widget.
        zstyle ':manydots-magic' backward-delete-char-function .backward-delete-char

        source ${pkgs.zsh-autopair}/share/zsh/zsh-autopair/autopair.zsh
      ''
      (lib.mkOrder 1250 # zsh
        ''
          source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
          bindkey -M emacs '^P' history-substring-search-up
          bindkey -M emacs '^N' history-substring-search-down
          bindkey -M emacs '\e[A' history-substring-search-up
          bindkey -M emacs '\e[B' history-substring-search-down
          bindkey -M emacs '\eOA' history-substring-search-up
          bindkey -M emacs '\eOB' history-substring-search-down
        ''
      )
    ];
  };
}
