# `vim` with custom hardened rvim wrapper.
_: final: prev: {
  # NOTE: `symlinkJoin` instead of `overrideAttrs`, otherwise replacing `rvim` rebuilds `vim` from source.
  vim = final.symlinkJoin {
    inherit (prev.vim) name;
    meta = builtins.removeAttrs prev.vim.meta [ "outputsToInstall" ]; # NOTE: the join has no `xxd` output.
    paths = [ prev.vim ];
    passthru = { inherit (prev.vim) xxd; };
    postBuild = ''
      rm -f "$out/bin/rvim"
      install -m755 ${
        final.writeText "rvim" (
          final.lib.replaceStrings
            [ "@unshare@" "@vim@" ]
            [ "${final.util-linux}/bin/unshare" "${prev.vim}/bin/vim" ]
            (builtins.readFile ./vim/rvim.sh)
        )
      } "$out/bin/rvim"
    '';
  };
}
