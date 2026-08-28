_: final: prev: {
  unstable = prev.unstable // {
    opencode = prev.unstable.opencode.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or [ ]) ++ [
        ./unstable-opencode/opencode-1.18.13-thought-start-timestamp.patch
      ];
    });
  };
}
