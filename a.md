# PR #550650 — updated description

Adds `networking.wireless.pkcs11.{enable,package}`, making the OpenSSL `pkcs11` engine (from libp11)
available to wpa_supplicant, so EAP-TLS can authenticate with client keys held on PKCS#11 tokens
(smartcards, TPM 2.0) instead of key files:

```
network={
  ssid="corp"
  key_mgmt=WPA-EAP
  eap=TLS
  identity="user@example.org"
  engine=1
  engine_id="pkcs11"
  key_id="pkcs11:object=mykey;type=private"
  client_cert="/etc/ssl/certs/user.pem"
}
```

## Why an environment variable

OpenSSL's dynamic engine loader searches only OpenSSL's own engine directory, which does not contain
the `pkcs11` engine (it is built separately, in libp11), so `ENGINE_by_id("pkcs11")` fails out of the
box. The option points the search path (`OPENSSL_ENGINES`) at the libp11 package, scoped to the unit.

The alternatives work worse:

- Build-time `CONFIG_PKCS11_ENGINE_PATH`/`CONFIG_PKCS11_MODULE_PATH` do not set defaults — they
  compile out the corresponding runtime options entirely (`#ifndef` guards around the config struct
  fields and parser entries), and couple the wpa_supplicant build to libp11.
- The runtime `pkcs11_engine_path=`/`pkcs11_module_path=` globals never reach interfaces added over
  D-Bus (e.g. by NetworkManager): those get an empty per-interface configuration, since D-Bus
  `CreateInterface` carries no config file. Verified live — the config file is not even opened for
  such interfaces. `OPENSSL_ENGINES` acts through OpenSSL's engine search instead, covering both
  command-line and D-Bus-added interfaces.

The PKCS#11 module is resolved through the engine's own default. With #550646 that default is the
p11-kit proxy, so any module registered with p11-kit (e.g. tpm2-pkcs11 via #550647) works without
further configuration.

## Hardened service

With `networking.wireless.enableHardening`, the unit is additionally granted access to the kernel TPM
resource manager (`/dev/tpmrm0`, plus `security.tpm2.tssGroup` membership), the pcscd socket, and
tpm2-pkcs11's system-wide token store `/etc/tpm2_pkcs11` (the sandboxed service has no home
directory, so only the system store location applies). tpm2-pkcs11 refuses to use a store it cannot
lock and update, so `security.tpm2.pkcs11.enable` now creates the store directory as
`root:tss 2770` via tmpfiles and recursively normalizes the group and group-write of its contents
(`Z /etc/tpm2_pkcs11 ~2770 - tss -`) on every boot and system activation — root-provisioned tokens
become usable without any manual permission fixes. File owners are left unchanged, and the `~` mask
keeps files non-executable and deliberately read-only files read-only.

Also mirrors `TPM2_PKCS11_TCTI` into the unit, since `security.tpm2.tctiEnvironment` exports it only
to login shells.

## Testing

Tested on real hardware (ThinkPad, TPM2-held client key, corporate EAP-TLS network,
NetworkManager-managed interface via D-Bus), hardening enabled.

Companion PRs: #550646 (libp11: default module = p11-kit proxy), #550647 (nixos/tpm2: register
tpm2-pkcs11 with p11-kit).

---

# Reply 1 — to rnhmjoj's build-time question

That was actually my first working setup (as a private overlay), but the build-time defines behave worse than they look:

- The first problem is that `CONFIG_PKCS11_ENGINE_PATH`/`CONFIG_PKCS11_MODULE_PATH` macro do not add sane defaults, they remove the runtime option whatsoever,
  which is a bit rough change to a once configurable tool.
- The baked path has to point somewhere.
  A libp11 store path couples the packages, so wpa_supplicant rebuilds on every libp11 change;
  `/run/current-system/sw/...` (what my overlay used) avoids the coupling but hardcodes NixOS system-environment layout into a generic package.
- `CONFIG_PKCS11_MODULE_PATH` additionally hardwires one module choice (tpm2? OpenSC?) for every user of the package.
  With https://github.com/NixOS/nixpkgs/pull/550646, the engine's own default already resolves through p11-kit, so no module path needs to be baked anywhere.

For completeness, the third option — generating `pkcs11_engine_path`/`pkcs11_module_path` into nixos.conf — I have tried as well, and it cannot cover the NetworkManager case, which shares this unit through `dbusControlled`: interfaces added over D-Bus get `wpa_config_alloc_empty()` because NM sends only Driver and Ifname in CreateInterface, so global options from any config file never reach them (verified with strace — the file is never even opened). `OPENSSL_ENGINES` is the one mechanism covering both D-Bus-added and command-line-added interfaces, since it acts through OpenSSL's engine search rather than per-interface configuration.

---

# Reply 2 — to the /etc/tpm2_pkcs11 inline comment

It's not specific to wpa_supplicant — `/etc/tpm2_pkcs11` is tpm2-pkcs11's system-wide store, the fallback it uses whenever the caller has no usable `$HOME` (which is why it is what applies inside this service). You're right that the recursive chgrp appropriates it from any other consumer.

I've reworked it to leave ownership alone: `security.tpm2.pkcs11` now creates the store as `root:tss 2770` (tmpfiles), and the hardened unit reaches it through `SupplementaryGroups = tss`, which it already needs for `/dev/tpmrm0` anyway. Nothing gets rewritten at service start, and other tss-group consumers keep working. A companion `Z /etc/tpm2_pkcs11 ~2770 - tss -` line normalizes the group and group-write of the contents at boot and activation (root-side provisioning tools create files 0644, which would lock the group out); file owners are untouched, and the `~` mask keeps files non-executable and read-only files read-only.
