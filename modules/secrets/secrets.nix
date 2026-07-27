# Runtime sops secret decryption: `local.secrets` options backed by
# `decrypt-secrets` systemd oneshots, for both NixOS and home-manager.
{ flake.modules.nixos.base = ./_impl/nixos.nix; }
