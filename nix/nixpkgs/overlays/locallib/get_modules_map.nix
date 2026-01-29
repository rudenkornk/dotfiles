_: path:

let
  inherit (builtins)
    attrNames
    filter
    listToAttrs
    readDir
    stringLength
    substring
    ;

  hasSuffix =
    suffix: str:
    let
      sufLen = stringLength suffix;
      strLen = stringLength str;
    in
    sufLen <= strLen && substring (strLen - sufLen) sufLen str == suffix;

  entries = readDir path;
  nixFiles = filter (name: entries.${name} == "regular" && hasSuffix ".nix" name) (attrNames entries);
in
listToAttrs (
  map (name: {
    name = substring 0 (stringLength name - 4) name;
    value = path + "/${name}";
  }) nixFiles
)
