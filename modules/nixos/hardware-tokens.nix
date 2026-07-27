# TPM and PKCS#11 hardware-token support, including WIFI authentication with
# TPM-backed keys.
{
  flake.modules.nixos.base = {
    security = {
      tpm2 = {
        # https://nixos.org/manual/nixos/stable/#module-security-tpm2-nixosmodule
        enable = true;
        abrmd.enable = true;
        pkcs11.enable = true;

        tctiEnvironment.enable = true;
        tctiEnvironment.interface = "tabrmd";
      };
    };

    networking = {
      wireless = {
        enableHardening = false; # Allow usage of smart cards and TPM for wifi connections.
        extraConfig = ''
          # Note: this configuration is a no-op due to NetworkManager not passing it to wpa_supplicant.
          # It is only specified here if any future upstream changes fix the problem.
          # See `./nix/nixpkgs/overlays/wpa_supplicant.nix` in this repo for details.

          # Hint wpa_supplicant on where to search for hardware-keys providers.
          pkcs11_engine_path=/run/current-system/sw/lib/engines/pkcs11.so
          pkcs11_module_path=/run/current-system/sw/lib/libtpm2_pkcs11.so
        '';
      };
    };

    environment = {
      etc = {
        # W/A for p11 tool not finding libtpm2.
        "pkcs11/modules/libtpm2-pkcs11".text = ''
          module: /run/current-system/sw/lib/libtpm2_pkcs11.so
          critical: yes
        '';
      };
    };
  };
}
