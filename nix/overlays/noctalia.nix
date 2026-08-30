_: _: prev: {
  noctalia-shell = prev.noctalia-shell.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [ ./noctalia-shell-4.7.6-lock-input-focus.patch ];
  });
}
