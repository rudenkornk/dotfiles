_:

{
  programs.bash = {
    enable = true;
    historyControl = [ "ignoreboth" ];
    historyFileSize = 1000000;
    initExtra = # bash
      ''
        stty erase '^?'
        stty -ixon
        stty lnext undef
        # Reduce delay for ctrl-v key.
        # This cannot be disabled completely, since `atuin` uses this internally.
        bind 'set keyseq-timeout 50'
      '';
  };
}
