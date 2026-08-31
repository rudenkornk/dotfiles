final: prev: {
  opencode = prev.opencode.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      (final.locallib.patches + /opencode-1.18.13-thought-start-timestamp.patch)
    ];
  });
}
