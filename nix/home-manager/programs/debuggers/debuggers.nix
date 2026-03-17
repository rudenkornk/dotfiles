{ pkgs, ... }:

# Debuggers.
{
  home.packages = with pkgs; [
    creduce
    gdb
    lldb
    netcoredbg
    python3Packages.debugpy
    valgrind
    vscode-extensions.vadimcn.vscode-lldb
    vscode-extensions.xdebug.php-debug
    vscode-js-debug
  ];
}
