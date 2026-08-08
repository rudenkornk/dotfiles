_: final: prev: {
  unstable = prev.unstable // {
    vimPlugins = prev.unstable.vimPlugins // {
      # The healthcheck crashes on neovim >= 0.11, which renamed the `vim.health.report_*` API.
      # Upstream still uses the old names, and only `health.lua` is affected, so patch it in place.
      # https://github.com/GCBallesteros/jupytext.nvim
      jupytext-nvim = prev.unstable.vimPlugins.jupytext-nvim.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace lua/jupytext/health.lua --replace-fail "vim.health.report_" "vim.health."
        '';
      });

      # TODO(rudenkornk): remove this overlay once LazyVim supports all the quirks.
      # Special treatment for leap, which migrated to new repo and also rewritten some code.
      # LazyVim seemingly adapted, but for some reason it does not work.
      # See https://github.com/LazyVim/LazyVim/issues/7174
      LazyVim = prev.unstable.vimPlugins.LazyVim.overrideAttrs (old: {
        version = "2025-11-11";
        src = final.fetchFromGitHub {
          owner = "LazyVim";
          repo = "LazyVim";
          rev = "c64a61734fc9d45470a72603395c02137802bc6f";
          sha256 = "0krwss7gfssvgsk9gg7qzspcq2q8rp2f284i93ragl3ymxlsmqlx";
        };
        nvimSkipModules = old.nvimSkipModules ++ [
          "lazyvim.plugins.extras.lang.python"
          "lazyvim.plugins.extras.lang.svelte"
          "lazyvim.plugins.extras.lang.typescript"
        ];
      });
      # nixpkgs generates `nvim-treesitter` grammars through the intermediary `nurr` repo,
      # which lags a few hours behind the plugin itself.
      # The current unstable snapshot caught this window for the `diff` grammar:
      # it is built at an old revision without the `change` node,
      # while the plugin queries already reference it,
      # so every diff buffer (e.g. a commit message) fails to highlight.
      # Pin the grammar to the revision from the plugin's `lua/nvim-treesitter/parsers.lua`.
      # The assert fails the evaluation as soon as nixpkgs bumps the grammar,
      # forcing a re-check of the pin instead of silently applying a by-then-outdated version.
      # TODO(rudenkornk): remove this overlay once https://github.com/NixOS/nixpkgs/pull/547258
      # reaches the unstable channel.
      nvim-treesitter =
        let
          base = prev.unstable.vimPlugins.nvim-treesitter;
          brokenVersion = "0.0.0+rev=7d20331";
          fixedDiff = base.builtGrammars.diff.overrideAttrs (_: {
            version = "0.0.0+rev=1a24d30";
            src = final.fetchFromGitHub {
              owner = "tree-sitter-grammars";
              repo = "tree-sitter-diff";
              rev = "1a24d30d9b2b0bbf8420e229164462f410fb3ad0";
              hash = "sha256-GmnHPkdF9MpEyP3CGsGMgiptjemrD5BaU9f6fiGGjJ8=";
            };
          });
          fixedGrammars = map (g: if g.language or null == "diff" then fixedDiff else g) base.allGrammars;
        in
        assert final.lib.assertMsg (base.builtGrammars.diff.version == brokenVersion) ''
          nixpkgs bumped the nvim-treesitter `diff` grammar from ${brokenVersion}
          to ${base.builtGrammars.diff.version}.
          The pinned override is now stale: check whether the new grammar matches the plugin queries
          and drop (or update) this overlay.'';
        base.overrideAttrs (old: {
          passthru = old.passthru or { } // {
            withAllGrammars = base.withPlugins (_: fixedGrammars);
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
