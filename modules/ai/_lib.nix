# Helpers for wrapping AI CLI tools.
{
  # A wrapper module for a plain CLI tool: the package, wrapped with runtime
  # secret-env injection. `package` is a selector called with the wrapper's
  # `pkgs`; `binName` overrides binary detection for packages without
  # `meta.mainProgram`.
  mkSecretTool =
    {
      package,
      binName ? null,
    }:
    {
      wlib,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        wlib.modules.default
        ../secrets/_fragments/secret-env.nix
      ];
      config = {
        package = package pkgs;
      }
      // lib.optionalAttrs (binName != null) { inherit binName; };
    };
}
