{ pkgs, ... }:

# This util generates recursive `home.file` entries for home-manager
# based on passed directory with home files.
# Despite home.file.<name> has `recursive` flag, it does not work when we need to merge
# same directory in different `nix` modules.
# For example,
#   home.file.".config" = { source = ./config, recursive=true };
# will not work if declared in two different home-manager modules.
# This util tries to remove such limitation by "manually" scraping entries for `home.file` option.
# Additionally, it replaces leading directories with XDG locations if possible.

{ path, xdg, ... }:

let
  inherit (pkgs) lib;
  replace_with_xdg_gen =
    prefix: xdg_replacement: file:
    if lib.strings.hasPrefix prefix file then
      xdg_replacement + "/" + (lib.strings.removePrefix prefix file)
    else
      file;
  replace_config = replace_with_xdg_gen ".config/" xdg.configHome;
  replace_data = replace_with_xdg_gen ".local/share/" xdg.dataHome;
  replace_cache = replace_with_xdg_gen ".cache/" xdg.cacheHome;
  replace_state = replace_with_xdg_gen ".local/state/" xdg.stateHome;
  replace_with_xdg =
    file:
    lib.pipe file [
      (lib.path.removePrefix path)
      (lib.strings.removePrefix "./")
      replace_config
      replace_data
      replace_cache
      replace_state
    ];

  source_files = lib.filesystem.listFilesRecursive path;
  result_raw = map (file: {
    name = replace_with_xdg file;
    value = {
      source = file;
    };
  }) source_files;
in
builtins.listToAttrs result_raw
