{ pkgs, ... }:

# Debuggers.
let
  # `LazyVim`'s DAP language extras invoke these adapters by bare command name, since mason is disabled.
  # The binaries ship inside the vscode extension packages under different names or paths,
  # so expose each one under the name that `LazyVim` expects.
  codelldb = pkgs.writeShellScriptBin "codelldb" ''
    exec ${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb "$@"
  '';
  js-debug-adapter = pkgs.writeShellScriptBin "js-debug-adapter" ''
    exec ${pkgs.vscode-js-debug}/bin/js-debug "$@"
  '';
  php-debug-adapter = pkgs.writeShellScriptBin "php-debug-adapter" ''
    exec ${pkgs.nodejs}/bin/node \
      ${pkgs.vscode-extensions.xdebug.php-debug}/share/vscode/extensions/xdebug.php-debug/out/phpDebug.js "$@"
  '';
  renamed-adapters = [
    codelldb
    js-debug-adapter
    php-debug-adapter
  ];
in
{
  home.packages =
    with pkgs;
    [
      creduce
      delve # Provides `dlv`, the Go debug adapter.
      gdb
      lldb
      netcoredbg
      python3Packages.debugpy
      valgrind
      vscode-extensions.vadimcn.vscode-lldb
      vscode-extensions.xdebug.php-debug
      vscode-js-debug
    ]
    ++ renamed-adapters;
}
