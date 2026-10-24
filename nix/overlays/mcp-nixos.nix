_: _final: prev: {
  mcp-nixos = prev.mcp-nixos.overrideAttrs (old: {
    # Project Python paths can shadow MCP dependencies with packages built for an incompatible Python version.
    makeWrapperArgs = (old.makeWrapperArgs or [ ]) ++ [
      "--unset PYTHONPATH"
      "--unset PYTHONHOME"
    ];
  });
}
