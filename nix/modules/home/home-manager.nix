{ config, lib, ... }:

# Home Manager keys `home.file` by target path, and `source` is not mergeable,
# so two modules cannot both claim a shared directory such as `.config`.
# This option expands a recursive directory into one entry per file instead,
# which lets modules share a target directory and lets a downstream module disable a single file.
#
# Prior art (evaluated 2026-09):
# - Making `source` itself mergeable was implemented and declined upstream.
#   The maintainer preferred an explicit `symlinkJoin`.
#   https://github.com/nix-community/home-manager/pull/3141
# - Pointing `home.file` at a whole dotfiles tree is a long-standing open request.
#   https://github.com/nix-community/home-manager/issues/3849

let
  cfg = config.local.home.file;

  cats = [
    {
      prefix = ".cache/";
      path = [
        "xdg"
        "cacheFile"
      ];
    }
    {
      prefix = ".config/";
      path = [
        "xdg"
        "configFile"
      ];
    }
    {
      prefix = ".local/share/";
      path = [
        "xdg"
        "dataFile"
      ];
    }
    {
      prefix = ".local/state/";
      path = [
        "xdg"
        "stateFile"
      ];
    }
    {
      prefix = "";
      path = [
        "home"
        "file"
      ];
    }
  ];

  # `join [ ".config/nvim" "." "lua/init.lua" ]` => `".config/nvim/lua/init.lua"`
  join = parts: lib.concatStringsSep "/" (lib.filter (s: s != "" && s != ".") parts);
  relative = root: file: lib.removePrefix "./" (lib.path.removePrefix root file);
  # Do not inspect derivation outputs, since that would trigger a build during evaluation.
  expandable = source: !builtins.hasContext (toString source) && lib.pathIsDirectory source;
  category_for =
    target: lib.findFirst (destination: lib.hasPrefix destination.prefix target) (lib.last cats) cats;
  destination_for =
    target:
    let
      cat = category_for target;
    in
    cat.path ++ [ (lib.removePrefix cat.prefix target) ];

  # Convert this:
  # {
  #  ".config/nvim" = {
  #    source = [ ./nvim ... ];
  #    recursive = true;
  #    };
  #  }
  # To this:
  #  [
  #    {
  #      target = ".config/nvim";
  #      source = ./nvim;
  #      recursive = true;
  #    }
  #    ...
  #  ]
  cfg_list = lib.concatLists (
    lib.mapAttrsToList (
      target: value:
      map (source: {
        inherit target source;
        inherit (value) recursive;
      }) value.source
    ) cfg
  );

  expand_entry =
    {
      target,
      source,
      recursive,
    }:
    map (
      file:
      let
        rel = relative source file;
      in
      {
        target = join [
          target
          rel
        ];
        source = "${source}/${rel}";
        recursive = false;
      }
    ) (lib.filesystem.listFilesRecursive source);

  entries_list = lib.concatMap (
    entry: if entry.recursive && (expandable entry.source) then expand_entry entry else [ entry ]
  ) cfg_list;

  entries_attrs = map (
    entry: lib.setAttrByPath (destination_for entry.target) { inherit (entry) source recursive; }
  ) entries_list;

  empty = {
    home.file = { };
    xdg = { };
  };
  config_result = lib.foldl' lib.recursiveUpdate empty entries_attrs;

  duplicates = lib.filterAttrs (_: entries: lib.length entries > 1) (
    lib.groupBy (entry: lib.concatStringsSep "/" (destination_for entry.target)) entries_list
  );

  duplicate_assertions = lib.mapAttrsToList (destination: entries: {
    assertion = false;
    message = "local.home.file: ${destination} is claimed by ${
      lib.concatMapStringsSep " and " (entry: toString entry.source) entries
    }";
  }) duplicates;
in
{
  options = {
    local.home.file = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            source = lib.mkOption {
              # A list, so that several modules can contribute to one target.
              type = lib.types.coercedTo lib.types.path lib.singleton (lib.types.listOf lib.types.path);
            };
            recursive = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
          };
        }
      );
      default = { };
      example = lib.literalExpression ''{ ".".source = ./configs; }'';
      description = ''
        Compared to native HM `home.file` this helper has several differences:
        1. It allows to specify `home.file.<path>` several times in different modules.
           Values are merged.
        2. To achieve that, it needs to enumerate all files in a specified target.
           If source is a derivation output, enumerating would cause a build during evaluation.
           Such sources skip enumeration and are handed to `home.file` untouched.
        3. It automatically replaces `.config`, `.cache`, `.local/share`, `.local/state` with `xdg` paths.
        4. `recursive` defaults to `true`, since sharing a target needs it.
      '';
    };
  };

  config = {
    assertions = duplicate_assertions;
    home = { inherit (config_result.home) file; };
    inherit (config_result) xdg;
  };
}
