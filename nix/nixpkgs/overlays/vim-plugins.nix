{ inputs, ... }:
final: prev:
let
  # TODO: remove this overlay when/if these PRs are merged and propagated:
  # https://github.com/NixOS/nixpkgs/pull/506121
  # https://github.com/lumen-oss/nurr/pull/67

  unstable = import inputs.nixpkgs_unstable { inherit (prev) system config; };

  ipynb-nvim-src = final.fetchFromGitHub {
    owner = "ajbucci";
    repo = "ipynb.nvim";
    rev = "b9ec93f7c37a3a081810a733d6baf4973fc31f3d";
    hash = "sha256-uB89olqvc5m6DHwtOOPpTRtyBnhNp6z6Pr9DS6mX7JA=";
  };

  # Compile the tree-sitter grammar shipped inside the plugin repo.
  # buildGrammar outputs: $out/parser (the .so file) + $out/queries/
  tree-sitter-ipynb = unstable.tree-sitter.buildGrammar {
    language = "ipynb";
    version = "2026-01-31";
    src = ipynb-nvim-src;
    location = "tree-sitter-ipynb"; # subdirectory to cd into before compiling
    generate = false; # parser.c is already committed to the repo
  };

  # grammarToPlugin wraps the raw grammar into a vimPlugin-compatible derivation:
  #   $out/parser/ipynb.so  -> symlink to tree-sitter-ipynb/parser
  #   $out/queries/ipynb/*  -> symlinks to tree-sitter-ipynb/queries/ipynb/*
  ipynb-nvim-grammar = unstable.neovimUtils.grammarToPlugin tree-sitter-ipynb;

  # The Lua/Python plugin itself.
  ipynb-nvim = unstable.vimUtils.buildVimPlugin {
    pname = "ipynb.nvim";
    version = "2026-01-31";
    src = ipynb-nvim-src;
    meta = {
      description = "Jupyter Notebook Plugin for Neovim";
      homepage = "https://github.com/ajbucci/ipynb.nvim";
      license = final.lib.licenses.asl20;
    };
  };
in
{
  unstable = unstable // {
    vimPlugins = unstable.vimPlugins // {
      inherit ipynb-nvim;
      nvim-treesitter = unstable.vimPlugins.nvim-treesitter // {
        withAllGrammars = unstable.vimPlugins.nvim-treesitter.withAllGrammars // {
          dependencies = unstable.vimPlugins.nvim-treesitter.withAllGrammars.dependencies ++ [
            ipynb-nvim-grammar
          ];
        };
      };
    };
  };
}
