# AI Instructions for dotfiles Repository

# Repository Overview

This repository defines a reproducible NixOS and Home Manager setup through Nix flakes.
It includes a Python CLI, Neovim (LazyVim), tmux, fish, and development toolchains.

# Development and Validation

## Command Execution

Run ordinary commands, including Git, searches, and installed tools, directly in the normal shell environment.
Use `nix run . -- <command>` for the repository management CLI.
The flake app supplies the CLI's Python environment and tools; no manual dependency installation is needed.
For example, use `nix run . -- hooks` to install the repository hooks.
See `readme.md` for bootstrap and recovery instructions.

## Validation Policy

For routine changes, run `nix run . -- format` (or `nix run . -- format --check`) and `nix run . -- lint`.
Formatting also runs `ruff check --fix --unsafe-fixes`; lint includes strict mypy and full-history gitleaks scanning.
The complete formatter and linter lists live in `dotfiles_py/targets/lint.py`.
Run any checks specific to the changed behavior before finishing.

**Keep Nix configuration evaluation and build checks rare, and only at the end of the entire change set.**
Keep Nix configuration evaluation and build checks rare and at the end of the change set.
When required, the flake check must be the final validation step, after all changes and other checks are complete.
All required checks must pass before the final commit or reporting completion.
If validation requires further edits, rerun the affected checks and keep any required flake check last.
CI runs the same checks; see `.github/workflows/workflow.yml`.

If lint reports that git history is shallow, run `git fetch --unshallow` and rerun lint.
Use this documented workaround rather than investigating alternatives.

# Repository Map and Conventions

- `flake.nix` defines flake outputs; `flake.lock` pins dependencies.
  `nix/tooling.nix` defines the CLI package, default app, and development shells.
- `nix/configuration.nix` and `nix/home.nix` are the system and Home Manager entry points.
  `nix/hosts/` and `nix/users/` hold machine and user definitions; hardware configuration is inlined per host.
- `nix/home-manager/` holds program/category modules, configs, scripts, and dotfiles.
  Neovim's Lua configuration is in `nix/home-manager/text-editors/neovim/config/`.
- `nix/modules/` holds local modules; `nix/overlays/` holds package overlays.
  `nix/packages/` holds standalone packages; `nix/unfree.nix` is the unfree-package allowlist.
- `dotfiles_py/cli.py` defines CLI commands, `targets/` implements them, and `utils.py` provides shared utilities.
  Hooks and scripts live in `dotfiles_py/data/`.

## Nix Conventions

- **Add new Nix and configuration files to the git staging area so the flake can see them.**
- The default package set is stable; `pkgs.unstable` provides packages from a separate input.
- Home Manager configurations cover every configured `user@host` pair and are registered as flake checks.
- `local.home.file` in `nix/modules/home/` links directory trees into `$HOME` one file at a time,
  allowing several modules to populate a shared target directory.

## Overlay Rules

- `nix/overlays/unstable.nix` introduces `pkgs.unstable` from the `nixpkgs-unstable` input
  and auto-loads native overlays from regular `nix/overlays/unstable/*.nix` files.
- Put each `pkgs.unstable` amendment in its own file under `nix/overlays/unstable/`.
  Do not define package-specific overrides directly in `unstable.nix`.
  Each amendment must have the shape `final: prev: { ... }` and must not accept repository arguments.
- `nix/overlays/custom.nix` maps each regular `nix/overlays/custom/<name>.nix` module
  to `pkgs.custom.<name>`.
  Each module must have the shape `final: prev: derivation`.
- The custom loader is not recursive, so keep package modules at the root of `custom/`.
- Store all non-Nix custom package assets under `nix/overlays/custom/scripts/`,
  using package-specific subdirectories where useful.
- Store all package patches in `nix/overlays/patches/` and reference them via `final.locallib.patches + /<name>.patch`.
  `pkgs.unstable` also carries `locallib`, so the same reference works inside `nix/overlays/unstable/`.

# Secrets Management

Secrets in `nix/secrets/` use sops + age with the custom `local.secrets` modules in `nix/modules/secrets/`,
not community `sops-nix`.
Configurations must still evaluate without decrypted secrets.

- `.sops.yaml` defines recipients and encryption rules, including TPM-bound identities.
  Private keys live in `~/.config/sops/` and `/root/.config/sops/`, preserved across reboots by `nix/disk.nix`.
  `nix run . -- updatekeys` in `dotfiles_py/targets/secrets.py` re-encrypts secrets after recipient changes.
- `nix/overlays/custom/scripts/sops-cached.sh` decrypts into `/run/user/$UID/secrets/` (tmpfs), caches results,
  and optionally symlinks them to their target paths.
  Both system and user `decrypt-secrets.service` units use it.
- `nix/overlays/locallib/with_secrets.nix` uses `bash_secrets.nix` to inject decrypted environment variables at launch.
  This wrapper is used by all AI CLI tools and Neovim.
- The pre-commit hook blocks plaintext secret filenames and scans the staged diff with gitleaks.
  AI tools are denied access to secrets directories.
  `nix/overlays/sops.nix` runs the secret editor with `unshare --net` and restricted vim.

# Code Style Guidelines

- **Python**: Strict mypy, ruff with "ALL" rules (see pyproject.toml ignores), 120 char line length, no docstrings for most functions
- **Nix**: nixfmt with --strict, statix linting
- **Shell**: shellcheck, shfmt (2-space indents from .editorconfig)
- **Markdown**: 180 char line length, HTML allowed
- **YAML**: 120 char line length, no document-start
- **Lua**: stylua (2-space indents)
- **KDL**: kdlfmt

# Trust These Instructions

Use the documented workflows.
Look up additional information only for task-specific details not covered here or errors without a documented workaround.
