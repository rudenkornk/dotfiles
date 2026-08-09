# Make the OpenSSL `pkcs11` engine find PKCS#11 tokens through p11-kit.
#
# Observed problem:
#   Connecting to hardware-keyed WiFi through NetworkManager fails:
#   wpa_supplicant loads the `pkcs11` engine for `pkcs11:` URIs,
#   but the engine has no PKCS#11 module configured and finds no tokens.
#
# Root cause:
#   Upstream `libp11` derives the engine's default PKCS#11 module from p11-kit's
#   `proxy_module` pkg-config variable (see `configure.ac`),
#   falling back to no default at all when p11-kit is not found at build time.
#   nixpkgs builds `libp11` without p11-kit, so the engine only works for
#   applications that explicitly configure a module path — and most,
#   including wpa_supplicant started by NetworkManager, do not.
#
# Fix:
#   Pass `--with-pkcs11-module` explicitly, pointing at the p11-kit proxy.
#   The proxy in turn loads the modules registered system-wide in `/etc/pkcs11/modules`,
#   where the TPM2 module is registered from `nix/configuration.nix`.
#
# This is a backport of a pending nixpkgs fix (branch `libp11-p11-kit-default-module`).
# See also `systemd.services.wpa_supplicant.environment` and
# `environment.etc."pkcs11/modules/tpm2_pkcs11.module"` in `nix/configuration.nix`,
# which backport the NixOS-module parts of the same chain.

_: final: prev: {
  libp11 = prev.libp11.overrideAttrs (oldAttrs: {
    # Note: 0.4.17+ has another undebugged problem.
    # The only known thing is that this is a first problematic commit:
    # https://github.com/OpenSC/libp11/commit/60329e0502f751705bb939ad06574e36e4a42bc2
    version = "0.4.13";
    src = final.fetchurl {
      url = "https://github.com/OpenSC/libp11/archive/libp11-0.4.13.tar.gz";
      hash = "sha256-BE2i20ZL/1SmcewpGqE7SGsEa0xtZwVrROd9lr5Q38Q=";
    };
    configureFlags = oldAttrs.configureFlags ++ [
      "--with-pkcs11-module=${final.lib.getLib final.p11-kit}/lib/p11-kit-proxy.so"
    ];
  });
}
