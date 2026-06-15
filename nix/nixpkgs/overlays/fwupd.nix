# Override `fwupd` to make it recognize the `FWUPD_EFIAPPDIR` environment variable.
#
# Observed problem:
#   `fwupdmgr update` fails with:
#   `fwupd-efi/libexec/fwupd/efi/fwupdx64.efi.signed cannot be found`
#
# Root cause:
#   The NixOS Limine Secure Boot integration (activated via `boot.loader.limine.secureBoot.enable = true`)
#   creates `fwupd-efi.service`, which signs the EFI helper binary with sbctl
#   and places the result at `/run/fwupd-efi/fwupdx64.efi.signed`.
#   The module also configures `FWUPD_EFIAPPDIR=/run/fwupd-efi` on the fwupd systemd service.
#   Despite this, fwupd ignores the variable and searches for the signed binary
#   under the build-time `fwupd-efi` store path instead —
#   a read-only location that only contains an unsigned `fwupdx64.efi`.
#   This happens because fwupd hardcodes `EFI_APP_LOCATION` at build time inside
#   `libfwupdplugin/fu-path-store.c:310`.
#   The runtime environment handler `fu_path_store_load_from_env()`
#   (lines 340–424) maps several well-known variables
#   (`FWUPD_UEFI_ESP_PATH`, `FWUPD_DATADIR`, etc.) to internal path kinds,
#   but `FWUPD_EFIAPPDIR` is missing from the list.
#   Consequently, the daemon silently ignores the one variable that NixOS relies
#   on to redirect the lookup to the signed runtime copy.
#
# Fix:
#   Insert `{"FWUPD_EFIAPPDIR", FU_PATH_KIND_EFIAPPDIR}` into the env-map
#   array so that fwupd honours the environment variable that the NixOS Limine
#   Secure Boot module already sets on the service.
#   The mapping key `FU_PATH_KIND_EFIAPPDIR` already exists in the source code
#   and is used at build time (line 310),
#   so the only missing piece is the runtime override entry.
#
# Why it must be a compile-time fix (not runtime configuration):
#   - fwupd 2.1.4 provides no CLI flag or daemon configuration key to change
#     the EFI helper directory.
#     The path is a compile-time `#define EFI_APP_LOCATION`.
#   - The `uefiCapsuleSettings`/`daemonSettings` config sections control
#     behaviours like shim usage, ESP free space, and disabled devices,
#     but none of them allow overriding the EFI binary path.
#   - The Limine module correctly solves the *distribution* problem
#     (signing + placing the binary) but relies on a runtime variable that fwupd
#     does not actually read —
#     the only way to close this gap is to teach fwupd about that variable.
_: final: prev: {
  fwupd = prev.fwupd.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace libfwupdplugin/fu-path-store.c \
        --replace-fail \
          '{"FWUPD_UEFI_ESP_PATH", FU_PATH_KIND_UEFI_ESP},' \
          $'{"FWUPD_UEFI_ESP_PATH", FU_PATH_KIND_UEFI_ESP},\n\t    {"FWUPD_EFIAPPDIR", FU_PATH_KIND_EFIAPPDIR},'
    '';
  });
}
