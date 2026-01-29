_:

{
  programs.bash = {
    enable = true;
    historyControl = [ "ignoreboth" ];
    historyFileSize = 1000000;
    initExtra = builtins.readFile ./bash/init_extra.sh;
  };
}
