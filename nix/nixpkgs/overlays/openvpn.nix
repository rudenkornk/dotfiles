# Enable PKCS#11 support in `openvpn` so it can authenticate against the TPM-backed smartcard module.
# This is required for the corp itsme VPN, whose config uses a `pkcs11-id` pointing at the TPM token.
# Overriding the top-level attribute keeps the override in one place,
# so both the plain `openvpn` package and the `custom.openvpn_corp` wrapper share the same build.
_: final: prev: { openvpn = prev.openvpn.override { pkcs11Support = true; }; }
