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

# Keyboard Layout and Keymap Design

Design keymaps around shared muscle memory, home-row reachability, and clear ownership between layers.
Use the conventions below when planning shortcuts.
Consult the reference files only for relevant conflicts, exceptions, or implementation details.

## Navigation and Shared Semantics

- Never use plain or modified arrow keys as convenient keymaps or recommend them as ergonomic alternatives.
  Existing arrow aliases may remain, but must not be the only convenient way to perform an action.
- In input contexts, analogous to Vim insert mode, prefer Emacs-style navigation:
  - `Ctrl+B/F` moves backward/forward by character.
  - `Alt+B/F` moves backward/forward by word.
  - `Ctrl+W` deletes the previous word.
  - `Ctrl+P/N` navigates previous/next entries, history items, or completion candidates.
  - `Ctrl+A` moves to the start of the line.
  - Do not assume `Ctrl+E` is available for moving to line end; it is generally used for line scrolling.
- In non-input contexts, analogous to Vim normal mode, prefer Vim-style `hjkl` navigation.
  Do not bind bare letters globally when they would interfere with typing.
- In both contexts, prefer `Ctrl+U/D` for page or half-page navigation and `Ctrl+Y/E` for scrolling up/down by line.
  `Ctrl+B/F` can provide full-page or preview paging in non-input contexts.
- `Ctrl+R` generally has search semantics.
  `Ctrl+C` generally cancels the current operation or exits.
- Prefer consistent meanings across applications rather than preserving conflicting upstream defaults.
  Respect context: text editing, list selection, transcript scrolling, and pane navigation are different operations.
- For additional actions, extend existing application-local leaders and mnemonic groups
  before inventing modifier chords.

## Shortcut Ownership

- Reserve all `Ctrl+Alt+*` and `Shift+Alt+*` combinations for niri, even when a particular chord is currently unbound.
  Existing application-specific exceptions do not make these namespaces available for new shortcuts.
- `Alt+hjkl` belongs to niri window navigation.
  `Ctrl+hjkl` belongs to integrated tmux pane and Neovim split navigation.
  Keep these layers separate; do not reuse their navigation chords for application-local actions.
- `Ctrl+S` is the tmux prefix.
  Preserve the `Alt+Z` resizing sequences used by the Neovim/tmux integration.
- An application binding does not make a shortcut available if the compositor, terminal, or tmux intercepts it first.
  Account for inherited defaults, plugins, and mode-specific bindings when checking a concrete conflict.
- Prefer a reachable, conflict-free application keymap over adding terminal forwarding workarounds.
  Changes to shortcut ownership or cross-layer forwarding require explicit review.

## Custom Layout and Language Support

- Design for the custom `qwerty_rnk` and `jcuken_rnk` layouts, not standard US QWERTY.
  Win keys produce Alt, physical Alt keys provide Level3 symbols, Caps Lock provides Ctrl,
  and right Ctrl provides Super.
- Check the actual gestures needed for punctuation and modifier combinations.
  A mnemonic-looking symbol is not necessarily convenient on this layout.
- Preserve equivalent physical gestures in English and Russian.
  Use the existing generated aliases, tmux alias mechanism, and Neovim language mappings where applicable.
- For generated configurations, edit their `*-overlay.*` sources and regenerate with `nix run . -- configs`.
  Do not maintain generated bindings or Russian aliases manually when an existing generator handles them.

## Cross-Application Conventions

AI tools generally align on `Ctrl+Enter` to submit, Enter to insert a newline,
`Alt+E` for the external editor, and `Alt+V` for image paste.
Preserve these conventions where supported, without assuming every application exposes identical commands or contexts.

Verify that newly chosen modifier combinations remain distinct through Kitty and tmux.
Do not assume that a shortcut accepted by an application's configuration reaches it unchanged.

## Reference Map

Paths below are relative to the repository root.

- Custom keyboard layouts: `nix/keyboard/qwerty_rnk` and `nix/keyboard/jcuken_rnk`.
- niri shortcuts: `nix/home-manager/desktop-envs/configs/.config/niri/config.kdl`.
- Kitty mappings and key forwarding: `nix/home-manager/terminals/configs/.config/kitty/kitty.conf`.
- tmux prefix and plugins: `nix/home-manager/shell/tmux.nix`.
- tmux navigation and forwarding: `nix/home-manager/shell/tmux/tmux.conf`.
- tmux Russian aliases: `nix/overlays/custom/scripts/tmux-russian-keymaps.py`.
- Neovim keymaps and language mappings:
  `nix/home-manager/text-editors/neovim/config/lua/config/keymaps.lua`.
- Neovim plugin-specific bindings:
  `nix/home-manager/text-editors/neovim/config/lua/plugins/configs/`,
  especially `tmux.lua`, `snacks.lua`, `blink.lua`, and `dap.lua`.
- Shell editing conventions: `nix/home-manager/shell/shell.nix` and shell-specific modules beside it.
- Shell picker bindings: `nix/home-manager/shell/fzf.nix`.
- Application keymaps and overlays: the `configs/` trees under `nix/home-manager/ai/`,
  `nix/home-manager/fs-navigation/`, `nix/home-manager/vcs/`, `nix/home-manager/shell/`,
  and `nix/home-manager/other/`.
- Configuration generation and Russian aliases: `dotfiles_py/targets/config_gen.py`.
- Pinned upstream keybinding catalogs: `nix/overlays/custom/keymap-defaults.nix`.

# Secrets Management

Secrets in `nix/secrets/` use sops + age with the custom `local.secrets` modules in `nix/modules/secrets/`,
not community `sops-nix`.
Configurations must still evaluate without decrypted secrets.

- `.sops.yaml` defines recipients and encryption rules, including TPM-bound identities.
  Private keys live in `~/.config/sops/` and `/root/.config/sops/`, preserved across reboots by `nix/disk.nix`.
  `nix run . -- updatekeys` in `dotfiles_py/targets/secrets.py` re-encrypts secrets after recipient changes.
- `nix/overlays/custom/scripts/sops-cached.sh` decrypts into `/run/user/$UID/secrets/` (tmpfs), caches results,
  and optionally symlinks them to their target paths.
  System and user decryption services use it.
  Assign secrets with consumer dependencies to a shared `service-name = "decrypt-<consumer>"` group,
  so the consumer waits only for its own secrets instead of the default `decrypt-secrets.service` batch.
  Bootstrap recovery restarts loaded `decrypt-*.service` and `merge-*.service` groups.
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
