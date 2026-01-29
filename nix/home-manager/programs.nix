{ pkgs, ... }:

{
  imports = [
    ./programs/ai.nix
    ./programs/archival.nix
    ./programs/basic.nix
    ./programs/debuggers.nix
    ./programs/editors.nix
    ./programs/encryption.nix
    ./programs/filesystem.nix
    ./programs/fonts.nix
    ./programs/gui.nix
    ./programs/linters.nix
    ./programs/lsp.nix
    ./programs/networking.nix
    ./programs/nix.nix
    ./programs/other.nix
    ./programs/package-managers.nix
    ./programs/remotes.nix
    ./programs/shell.nix
    ./programs/system.nix
    ./programs/toolchains.nix
    ./programs/vcs.nix
    ./programs/virtualization.nix
  ];
}
