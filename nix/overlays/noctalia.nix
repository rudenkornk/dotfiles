_: final: prev: {
  # Retry fprintd authorization while logind reactivates the session after resume.
  # See https://github.com/noctalia-dev/noctalia/pull/4365
  noctalia = prev.noctalia.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      (final.fetchpatch {
        url = "https://github.com/noctalia-dev/noctalia/commit/9a84476906165208286399a85fe62d802d47da1a.patch";
        hash = "sha256-wNn66UttKOnqbhARsXGjqJyST1hhRojUL6J1QNdMfGg=";
      })
      # See https://github.com/noctalia-dev/noctalia/issues/4473
      (final.locallib.patches + /noctalia-fingerprint-recovery.patch)
      (final.locallib.patches + /noctalia-upower-test-assertions.patch)
    ];
    nativeCheckInputs = (oldAttrs.nativeCheckInputs or [ ]) ++ [
      (final.writeShellScriptBin "dbus-run-session" ''
        exec ${final.dbus}/bin/dbus-run-session \
          --dbus-daemon=${final.dbus}/bin/dbus-daemon \
          --config-file=${final.dbus}/share/dbus-1/session.conf "$@"
      '')
    ];
  });
}
