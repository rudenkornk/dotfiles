{ pkgs, ... }:

# Debuggers.
{
  home.packages = with pkgs; [
    gdb
    lldb
    netcoredbg
    python3Packages.debugpy
    vscode-extensions.vadimcn.vscode-lldb
    vscode-extensions.xdebug.php-debug
    vscode-js-debug
  ];
}
