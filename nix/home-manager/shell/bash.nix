_:

{
  programs.bash = {
    enable = true;
    historyControl = [ "ignoreboth" ];
    historyFileSize = 1000000;
    initExtra = ''
      stty erase '^?'
      stty -ixon
    '';
  };
}
