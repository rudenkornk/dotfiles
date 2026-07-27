# Core flake-parts wiring shared by every module in this tree.
{ inputs, ... }: {
  imports = [ inputs.flake-parts.flakeModules.modules ];

  systems = [ "x86_64-linux" ];
}
