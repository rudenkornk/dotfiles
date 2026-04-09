{ inputs, ... }:
final: prev:
let
  # Fix tmux.nvim interaction with snacks.
  # https://github.com/folke/snacks.nvim/discussions/1802
  # https://github.com/aserowy/tmux.nvim/issues/133

  unstable = import inputs.nixpkgs_unstable { inherit (prev) system config; };
in
{
  unstable = unstable // {
    vimPlugins = unstable.vimPlugins // {
      tmux-nvim = unstable.vimUtils.buildVimPlugin {
        pname = "tmux.nvim";
        version = "0-unstable-2026-04-09";
        src = final.fetchFromGitHub {
          owner = "rudenkornk";
          repo = "tmux.nvim";
          rev = "4aab248686d305f215530ffb428236faf4012f8f";
          hash = "sha256-iyDqd0c6AwmCY52UHcnXY7WaLmp/ARWQ3Wdd/wPpaW4=";
        };
        meta.homepage = "https://github.com/rudenkornk/tmux.nvim";
      };
    };
  };
}
