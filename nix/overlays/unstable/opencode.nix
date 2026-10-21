final: prev: {
  opencode = final.symlinkJoin {
    inherit (prev.opencode) name meta;
    paths = [ prev.opencode ];
    nativeBuildInputs = [ final.makeBinaryWrapper ];
    # The native watcher needs libstdc++, see https://github.com/anomalyco/opencode/pull/53213
    postBuild = ''
      wrapProgram "$out/bin/opencode" \
        --prefix LD_LIBRARY_PATH : ${final.lib.makeLibraryPath [ final.stdenv.cc.cc.lib ]}
    '';
    passthru = (prev.opencode.passthru or { }) // {
      inherit (prev.opencode) pname version src;
    };
  };
}
