_: path:

let
  inherit (builtins)
    attrNames
    concatLists
    filter
    readDir
    ;

  entries = readDir path;
  nixDirs = filter (name: entries.${name} == "directory") (attrNames entries);
  nixDirsPaths = map (name: path + "/${name}") nixDirs;
  get_modules = import ./get_modules.nix null;
  module_lists = map get_modules nixDirsPaths;
in
concatLists module_lists
