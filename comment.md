  The two comments

  1. PR comment: "why not just [rebuild wpa_supplicant with CONFIG_PKCS11_ENGINE_PATH]? Moreover, if set at build time it would also work for users that run wpa_supplicant manually."
  2. Inline comment on the ExecStartPre chgrp lines: "Won't this clash with other services/users? Is /etc/tpm2_pkcs11 specific to wpa_supplicant?"

  Two facts I verified in hostap source that make the first reply strong: the CONFIG_PKCS11_* build defines don't set defaults — they compile out the struct fields and the config-parser entries (#ifndef guards in config.h:677 and config.c:5831), so
  the runtime pkcs11_engine_path=/pkcs11_module_path= options stop being recognized at all. That inverts rnhmjoj's "manual users" argument: baking paths removes the mechanism manual users have today. And wpa_supplicant.c:7982 confirms D-Bus-added
  interfaces get wpa_config_alloc_empty() — the reason your v2 live test failed and why config-file delivery can't serve the NM case.

  Suggested reply 1 — to the build-time question

  ▎ That was actually my first working setup (as a private overlay), but the build-time defines behave worse than they look:
  ▎
  ▎ - They don't add defaults — they remove the runtime options. CONFIG_PKCS11_ENGINE_PATH/CONFIG_PKCS11_MODULE_PATH compile out both the config struct fields and the parser entries (#ifndef in config.h and config.c), so pkcs11_engine_path= /
  ▎ pkcs11_module_path= stop being recognized in wpa_supplicant.conf. Users running wpa_supplicant manually are better served by the stock binary: the config options already exist for them, and baking paths in would take exactly that away.
  ▎ - The baked path has to point somewhere. A libp11 store path couples the packages, so wpa_supplicant rebuilds on every libp11 change; /run/current-system/sw/... (what my overlay used) avoids the coupling but hardcodes NixOS system-environment
  ▎ layout into a generic package and silently requires libp11 in environment.systemPackages. A unit environment variable is scoped to the service and can point at exact store paths.
  ▎ - CONFIG_PKCS11_MODULE_PATH additionally hardwires one module choice (tpm2? OpenSC?) for every user of the package. With #550646, the engine's own default already resolves through p11-kit, so no module path needs to be baked anywhere.
  ▎
  ▎ For completeness, the third option — generating pkcs11_engine_path/pkcs11_module_path into nixos.conf — I have tried as well, and it cannot cover the NetworkManager case, which shares this unit through dbusControlled: interfaces added over D-Bus
  ▎ get wpa_config_alloc_empty() because NM sends only Driver and Ifname in CreateInterface, so global options from any config file never reach them (verified with strace — the file is never even opened). OPENSSL_ENGINES is the one mechanism covering
  ▎ both D-Bus-added and command-line-added interfaces, since it acts through OpenSSL's engine search rather than per-interface configuration.

  Suggested reply 2 — to the /etc/tpm2_pkcs11 inline comment

  ▎ It's not specific to wpa_supplicant — /etc/tpm2_pkcs11 is tpm2-pkcs11's system-wide store, the fallback it uses whenever the caller has no usable $HOME (which is why it is what applies inside this service). You're right that the recursive chgrp
  ▎ appropriates it from any other consumer.
  ▎
  ▎ I've reworked it to leave ownership alone: security.tpm2.pkcs11 now creates the store as root:tss 2770 (tmpfiles), and the hardened unit reaches it through SupplementaryGroups = tss, which it already needs for /dev/tpmrm0 anyway. Nothing gets
  ▎ rewritten at service start, and other tss-group consumers keep working. One documented caveat: tmpfiles manages only the directory itself, so contents provisioned as root need a one-time chmod -R g+rwX.

  Notes before you post

- Reply 2 presupposes pushing the store rework first. The two engine-2 commits that do exactly this (60d7b7bf tpm2 tmpfiles rule, 23cd2766 TSS-group access) are delivery-independent and directly answer the review — they can be cherry-picked onto the
  PR branch as-is.
- I'd keep OPENSSL_ENGINES delivery upstream and not push the other two engine-2 commits (150a207 conf-file delivery, 7ba26d0 pkcs11.module option): your live test just confirmed conf delivery is dead under NM, and reply 1 turns that finding into
  the argument for the env var.

  If you want, I can prepare that updated PR branch (v1 delivery + the two store commits, with the option docs reconciled), and/or fix wpa_test the same way — restore OPENSSL_ENGINES while keeping the tmpfiles/tss-group store fix from yesterday's
  commit.
