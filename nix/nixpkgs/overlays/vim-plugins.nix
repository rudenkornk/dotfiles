_: final: prev: {
  unstable = prev.unstable // {
    vimPlugins = prev.unstable.vimPlugins // {
      # TODO(rudenkornk): remove this overlay once LazyVim supports all the quirks.
      # Special treatment for leap, which migrated to new repo and also rewritten some code.
      # LazyVim seemingly adapted, but for some reason it does not work.
      # See https://github.com/LazyVim/LazyVim/issues/7174
      LazyVim = prev.unstable.vimPlugins.LazyVim.overrideAttrs (_: {
        version = "2025-11-11";
        src = final.fetchFromGitHub {
          owner = "LazyVim";
          repo = "LazyVim";
          rev = "c64a61734fc9d45470a72603395c02137802bc6f";
          sha256 = "0krwss7gfssvgsk9gg7qzspcq2q8rp2f284i93ragl3ymxlsmqlx";
        };
      });
      leap-nvim = prev.unstable.vimPlugins.leap-nvim.overrideAttrs (_: {
        version = "2025-11-21";
        src = final.fetchFromGitHub {
          owner = "ggandor";
          repo = "leap.nvim";
          rev = "a3d721dffbc634cdea2d7e3d868501a8b59da058";
          sha256 = "0nl7b6ppn830l1rf57b0wcahaw373n7381s2823w094jz7kvc1d4";
        };
      });
    };
  };
}
