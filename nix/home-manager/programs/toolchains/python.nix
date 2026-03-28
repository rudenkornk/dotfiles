{ pkgs, ... }:

# Compilers, interpreters, build systems & language processors.
{
  home.packages = with pkgs; [
    (lib.setPrio 10 python3)
    (lib.setPrio 11 python311)
    (lib.setPrio 12 python312)
    (lib.setPrio 13 python313)
    (lib.setPrio 14 python314)
  ];
}
