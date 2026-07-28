# Helpers for contributing to the wrapped fish shell.
{
  # A fish wrapper "plugin" holding a single conf.d snippet.
  # The numeric name prefix documents the intended sourcing order; the actual
  # order across modules follows the deterministic module merge order.
  mkSnippet = pkgs: name: text: {
    src = pkgs.writeTextDir "share/fish/vendor_conf.d/${name}.fish" text;
  };
}
