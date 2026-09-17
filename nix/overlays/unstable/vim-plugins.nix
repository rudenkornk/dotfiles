final: prev: {
  vimPlugins = prev.vimPlugins // {
    LazyVim = prev.vimPlugins.LazyVim.overrideAttrs (old: {
      # https://github.com/LazyVim/LazyVim/issues/7174
      # https://github.com/LazyVim/LazyVim/pull/6756
      patches = (old.patches or [ ]) ++ [
        (final.fetchpatch {
          url = "https://github.com/LazyVim/LazyVim/commit/de8bc76a1a812897cfd2cc32c16c69e4f9545835.patch";
          hash = "sha256-brcwgVqNdFcbMZfEVHbtNivNUDo/G3Iu/hlGd/ZcKGU=";
        })
      ];
      nvimSkipModules = old.nvimSkipModules ++ [
        "lazyvim.plugins.extras.lang.python"
        "lazyvim.plugins.extras.lang.svelte"
        "lazyvim.plugins.extras.lang.typescript"
      ];
    });
  };
}
