# AI Instructions for dotfiles Repository

## Repository Overview

This is a **NixOS configuration repository** (~5MiB, ~250 tracked files) that provides a complete, reproducible personal machine setup.
The repository focuses on configuring development tools including Neovim (LazyVim-based), tmux, fish shell, and support for C++, Python, LaTeX, and Lua development.

**Key Technologies:**

- **NixOS/Nix Flakes**: Primary configuration system (~95 .nix files)
- **Python 3.13**: CLI tooling and automation (12 .py files in `dotfiles_py/`)
- **Home Manager**: User environment configuration
- **Languages**: Shell scripts (.sh, .fish), Lua configs (23 files), Nix expressions
- **Package Management**: Nix flakes
- **Secrets**: sops + age, stored encrypted directly in the repo

## Build and Validation Commands

### Environment Setup

**ALWAYS run commands inside the Nix development shell unless you're running nixos-rebuild:**

```bash
nix develop
```

This command:

- Takes ~10-60 seconds on first run (may fetch packages from cache.nixos.org)
- Provides all necessary tools: python313, formatters, linters, and more
- Generates a `__build/dotfiles` wrapper and puts it on `PATH`, so `dotfiles` invokes the local CLI
- Installs the git pre-commit hook (equivalent to `dotfiles hooks`; skipped in git worktrees, which share the main checkout's hooks)

**CRITICAL:** Do NOT run `uv sync` or `pip install` manually. The `nix develop` shell hook wires up the Python env automatically.

There is also a bootstrap-only shell used from a NixOS live USB (provides `disko`, `sbctl`, `nixos-install`):

```bash
nix develop .#install
```

### Primary Commands

All commands below assume you're inside `nix develop`.
Each of them can also run without the dev shell via `nix run . -- <command>`.

1. **Format Check** (~1-2 seconds):

   ```bash
   dotfiles format --check
   ```

   Runs formatters in check mode: statix, nixfmt, ruff, mdformat, shfmt, fish_indent, prettier, stylua, kdlfmt.

1. **Format (Apply)** (~1-2 seconds):

   ```bash
   dotfiles format
   ```

   Same formatters as above, but applies changes (also runs `ruff check --fix --unsafe-fixes`).

1. **Lint** (~1-2 seconds; the independent linters run in parallel):

   ```bash
   dotfiles lint
   ```

   Runs comprehensive linting:

   - `gitleaks git`: Checks entire git history for leaked credentials (~1900 commits at time of writing).
   - `statix check`: Nix linter.
   - `mypy`: Python type checking (strict mode).
   - `ruff check`: Python linter.
   - `yamllint --strict`: YAML linting for the `.github/` directory.
   - `shellcheck`: Shell script linting (tracked `.sh` files).
   - `typos`: Spell checking.
   - `markdownlint-cli2`: Markdown linting (the binary ships in the dev shell and is invoked directly).

1. **Flake Check** (~60 seconds):

   ```bash
   nix flake check --no-build
   ```

   Validates flake structure and evaluates every NixOS and Home Manager configuration.
   Home Manager configs are the cartesian product of users (`rudenkornk`, `rudenkornk_corp`) and hosts (`dellxps`, `thinkpad`),
   registered as checks so `nix flake check` builds each `user@host` activation package.

   **Do not run `nix flake check` during intermediate code changes.**
   If Nix validation is actually needed while a change is in progress, evaluate or build only the exact affected flake output.
   For example, to evaluate one Home Manager check without building it:

   ```bash
   nix eval --raw '.#checks.x86_64-linux."rudenkornk_corp@thinkpad".drvPath'
   ```

   In general avoid running this expensive command unless doing quirky nix changes, which have to be verified.
   In this case run the full `nix flake check --no-build` only as the final step of the entire validation pipeline,
   immediately before reporting to the user.

1. **Git Hooks Setup**:

   ```bash
   dotfiles hooks
   ```

   Symlinks a pre-commit hook that refuses plaintext secrets by filename and scans the staged diff with gitleaks.
   Runs automatically on `nix develop` entry, so the manual command is only needed outside the dev shell.

### CI Pipeline

The GitHub Actions workflow (`.github/workflows/workflow.yml`) runs on all PRs to `main` and on `main` pushes:

```yaml
- nix flake check --no-build
- nix run . -- format --check
- nix run . -- lint
```

CI checks out the full history (`fetch-depth: 0`) so the gitleaks credential scan can run.
**ALWAYS replicate these three commands locally before committing** to avoid CI failures.

## Known Issues and Workarounds

1. **Gitleaks Requires Full Git History**:

   - The lint command checks the entire git history starting from first commit `78946fc7d7e562042c62d589b331abf222c688e7`.
   - If git history is shallow, `dotfiles lint` will fail with "Looks like git history is shallow and credential check cannot be performed."
   - **Workaround**: Ensure you have the full git history (`git fetch --unshallow` if needed).

1. **Path Dependencies**:

   - All tools (nixfmt, ruff, mypy, etc.) must be available in the `nix develop` environment.
   - Do NOT attempt to use system Python or pip-installed tools—they will be incorrect versions.

## Project Structure

### Root Directory Files

- `flake.nix`: Nix flake defining `nixosConfigurations` (per host), `homeConfigurations` (per `user@host` pair), standalone `packages`,
  the `dotfiles` CLI package with its default `nix run` app, and dev shells.
- `flake.lock`: Locked dependency versions (nixpkgs 26.05, home-manager release-26.05, plus nixpkgs_unstable, nur, nixos-hardware, preservation, disko).
- `pyproject.toml`: Python project config with dependencies and ruff/mypy settings.
- `readme.md`: User-facing documentation with bootstrap and recovery instructions.
- `history.md`: Narrative history of the repository's evolution.
- `license.md`: MIT license.

### Configuration Files

- `.editorconfig`: Code style (2-space indents for `.sh`, 120 char line length for `.yaml`).
- `.gitleaks.toml`: Credential leak detection config with allowlists.
- `.yamllint.yaml`: YAML linting rules (120 char max, document-start disabled).
- `.markdownlint.yaml`: Markdown rules (180 char line length, MD033/MD024/MD025 disabled).
- `.prettierrc.json`: Empty (uses defaults).
- `.prettierignore`: Ignores lazy-lock.json, lazyvim.json, \_\_build\_\_, \_\_artifacts\_\_, .venv, and `*.md` (markdown is handled by mdformat/markdownlint).
- `.stylua.toml`: Lua formatter config (2-space indents).
- `.luarc.json`: Lua LSP config for Neovim development.
- `.sops.yaml`: sops rules mapping age recipients to encrypted secret paths.

### Python CLI (`dotfiles_py/`)

**Entry point**: `dotfiles_py/__main__.py` runs the typer app in `dotfiles_py/cli.py`, which defines commands:

- `lint`: Runs all linters (see Build Commands above).
- `format`: Runs all formatters, with a `--check`/`-c` flag.
- `hooks`: Sets up git hooks from `dotfiles_py/data/hooks/`.
- `gui`: Regenerates GNOME dconf settings and Noctalia settings from rules.
- `updatekeys`: Re-encrypts sops secrets when age recipients change.
- `bootstrap-host`: Probes the current machine and interactively generates its initial host definition and Facter report.
- `bootstrap-crypto`: Provisions AGE keys on a fresh machine: verifies a pasted key against repo secrets,
  optionally generates and registers a TPM key (re-encrypting and committing secrets),
  installs the TPM identity into user and root `keys.txt`, restarts the secret decryption services,
  and switches the repo `origin` from https to ssh.
- `syms`: Symlinks dotfile configs (nvim, ai, desktop-envs, linters, messengers, remote-desktop, system, terminals, vcs) into the home directory.
- `password`: Generates random passwords.

**Key modules**:

- `cli.py`: Main CLI app, command definitions, logging setup.
- `utils.py`: Shell command runner, git-file helpers, retry/makelike decorators, YAML utilities.
- `targets/lint.py`: Lint and format implementations.
- `targets/hooks.py`: Git hooks symlinking logic.
- `targets/gnome.py`: GNOME dconf configuration generation.
- `targets/noctalia.py`: Noctalia shell settings generation.
- `targets/host.py`: Initial host definition and Facter report generation.
- `targets/secrets.py`: sops age-key rotation and fresh-machine AGE key provisioning.
- `targets/syms.py`: Symlink materialization for configs.

**Data files**:

- `dotfiles_py/data/hooks/pre-commit`: Pre-commit hook preventing sensitive file commits.
- `dotfiles_py/data/scripts/`: Utility shell scripts (google_takeout.sh, nvim_time.sh, select_nvim.sh, colors.sh).

### Nix Configuration (`nix/`)

**Structure**:

- `nix/configuration.nix`: Shared NixOS system configuration (boot, networking, users, desktop, VPN, sops secrets).
- `nix/hosts/`: Per-machine definitions (`dellxps.nix`, `thinkpad.nix`); hardware config is inlined per host, plus host subdirs (e.g. `dellxps/noctalia_monitors.nix`).
- `nix/users/`: Per-user definitions (`rudenkornk.nix`, `rudenkornk_corp.nix`) with profile images.
- `nix/home.nix`: Home Manager entry point importing all program modules.
- `nix/home-manager/`: One directory per program or category, holding its modules, configs, scripts, and dotfiles.
  Categories include shell, terminals, text-editors (neovim), toolchains, lsp,
  linters, debuggers, desktop-envs, ai, vcs, browsers, messengers, media, networking, vpn, remote-desktop, and virtualization.
- `nix/packages/`: Standalone packages installed outside the main config (`arc`, `itsme-cli`, `openvpn-ya`, `skotty`, `splitty`, `ya`).
- `nix/modules/home/`: `local.home.file`, which links whole directory trees into `$HOME` one file at a time,
  so several modules can populate a shared target directory.
- `nix/modules/secrets/`: sops secrets modules (`nixos.nix`, `home-manager.nix`, `lib.nix`).
- `nix/overlays/`: Nixpkgs overlays (`custom`, `locallib`, `sops`, and others).
- `nix/unfree.nix`: Nixpkgs unfree-package allowlist.
- `nix/keyboard/`: Custom keyboard layouts (`qwerty_rnk`, `jcuken_rnk`).
- `nix/secrets/`: Encrypted secrets (`corp`, `nmconnections`, `ssh`, `vpn`) using sops.
- `nix/tooling.nix`: The `dotfiles` CLI package and its default flake app, plus the `default` and `install` dev shells.

**Key Nix Patterns**:

- Uses NixOS 26.05 (stable channel), with `nixpkgs_unstable` available as a separate input.
- Home Manager builds a config for every `user@host` pair (`rudenkornk` / `rudenkornk_corp` × `dellxps` / `thinkpad`).
- Secrets are encrypted with sops and age; config still evaluates even when secrets are not decrypted.
- Custom keyboard layouts via xkb.
- Fish is the primary shell; Neovim config is based on LazyVim.
- NOTE: WHEN ADDING A NEW NIX OR CONFIG FILE, ADD IT TO THE GIT STAGING AREA. OTHERWISE NIX WILL NOT SEE IT.

### Overlay Rules

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

## Secrets Management

**Tools**: sops + age. No community `sops-nix` — the repo uses a custom `local.secrets` module.

**Age keys**: Three recipients in `.sops.yaml`: one regular key, two TPM-bound via `age-plugin-tpm` (one per laptop).
TPM-bound keys ensure secrets decrypt only on the physical host.
Private keys live in `~/.config/sops/` and `/root/.config/sops/`, preserved across reboots by the `preservation` module in `disk.nix`.

**Decryption**: Both paths use `sops-cached` (`nix/overlays/custom/scripts/sops-cached.sh`),
which decrypts `.sops` files into `/run/user/$UID/secrets/` (tmpfs),
caches results (avoiding costly TPM re-decryption), and optionally creates symlinks to target paths.

1. **Systemd services at startup** — a custom module (`nix/modules/secrets/`) generates two `decrypt-secrets.service` oneshots:

   - System-level (as root, at boot) — decrypts secrets listed in `local.secrets.file` before NetworkManager and osquery start.
   - User-level (at login) — decrypts user secrets (itsme VPN, SSH, opencode auth) before `default.target`.
     Both produce symlinks-from-tmpfs, so programs read decrypted files at their normal paths.

1. **On-demand via `with_secrets` wrapper** — `bash_secrets.nix` sources `keys.sh.sops` and `proxy.sh.sops` using `sops-cached`,
   injecting API keys, tokens, and proxy settings into the shell environment.
   `with_secrets` (`nix/overlays/locallib/with_secrets.nix`) wraps any binary with these env vars at launch.
   Used by all AI CLI tools (`ai.nix`) and Neovim (`extraWrapperArgs`).

   Additionally, fish shell sources `tokens.sh.sops` at startup (`corp.nix`), and the SSH agent decrypts `~/.ssh/*.sops` on demand (`ssh_client.sh`).

**Key files**:

- `.sops.yaml` — age recipients and encryption rules.
- `nix/modules/secrets/{lib,nixos,home-manager}.nix` — the custom secrets module.
- `nix/overlays/custom/scripts/sops-cached.sh` — decryption engine.
- `nix/overlays/locallib/with_secrets.nix` — wraps binaries with secret env vars.
- `nix/overlays/locallib/bash_secrets.nix` — shell snippet sourcing `keys.sh.sops`/`proxy.sh.sops`.
- `nix/overlays/sops.nix` — network-isolated vim wrapper for editing secrets.
- `dotfiles_py/targets/secrets.py` — `dotfiles updatekeys` re-encrypts all `.sops` files.

**Security layers**: pre-commit hook blocks plaintext private keys/VPN configs, gitleaks scans full history for credentials,
AI tools are denied access to secrets dirs, sops editor runs with `unshare --net` and vim in restricted mode.

### Important File Locations

- Python source: `dotfiles_py/{cli.py,utils.py,targets/*.py}`
- Nix configs: `nix/{configuration.nix,home.nix,home-manager/**/*.nix}`
- Git hooks: `dotfiles_py/data/hooks/pre-commit`
- CI workflow: `.github/workflows/workflow.yml`
- Format configs: `.editorconfig`, `.prettierrc.json`, `.stylua.toml`, `pyproject.toml` (ruff sections)
- Lint configs: `.yamllint.yaml`, `.markdownlint.yaml`, `.gitleaks.toml`, `pyproject.toml` (mypy/ruff sections)

## Validation Steps

Before submitting changes:

1. **Format**: `nix develop --command dotfiles format`
1. **Lint**: `nix develop --command dotfiles lint` (takes ~1-2 seconds; linters run in parallel)
1. **Flake Check (final step only)**: `nix flake check --no-build` (takes ~60 seconds)

If making Python changes:

1. **Type Check**: `mypy` is run as part of `dotfiles lint`
1. **Ruff**: `ruff check` and `ruff format` are run as part of lint/format

If making Nix changes:

1. **Statix**: `statix check` and `statix fix` are run as part of lint/format
1. **Nixfmt**: `nixfmt` is run as part of format

## Code Style Guidelines

- **Python**: Strict mypy, ruff with "ALL" rules (see pyproject.toml ignores), 120 char line length, no docstrings for most functions
- **Nix**: nixfmt with --strict, statix linting
- **Shell**: shellcheck, shfmt (2-space indents from .editorconfig)
- **Markdown**: 180 char line length, HTML allowed
- **YAML**: 120 char line length, no document-start
- **Lua**: stylua (2-space indents)
- **KDL**: kdlfmt

## Comment & Markdown Style Guidelines

These rules apply to comments in all source files (Python, Lua, Nix, shell, etc.) as well as to prose text in
Markdown files.

### Rule 1: Comment only what the code cannot say

Preferably do not comment new code at all.
Add a comment only in the exceptional case where it is not obvious from the code why something is built the way it is.
Never document external tools: whoever wonders what a tool does will look it up
and get a better answer than any paraphrase kept in this repo.

Prefer comments that are short, inlined and precise.
Multiline comments placed above the code are acceptable,
but only when they describe actual specifics of this project and its unobvious quirks.

**Bad** — explains `nix-direnv` itself, which is what its own documentation is for:

```diff
+    # Caches `nix develop` environments in `.direnv` and keeps them alive with GC roots,
+    # so entering a project directory does not re-evaluate the flake.
+    nix-direnv.enable = true;
```

**Good:**

```diff
+    nix-direnv.enable = true;
```

**Bad** — an obscure change with no comment at all, which leaves room for an accidental revert
and for re-discovering the problem it fixes:

```diff
-        Linter(["statix", "check", repo_path]),
+        Linter(["statix", "check"]),
```

**Bad** — better, but too wordy, and it breaks up the structure of the surrounding code:

```diff
-        Linter(["statix", "check", repo_path]),
+        # `statix` drops its `.gitignore` filtering when given an absolute path,
+        # so it is left with its default target, the current directory.
+        Linter(["statix", "check"]),
```

**Good:**

```diff
-        Linter(["statix", "check", repo_path]),
+        Linter(["statix", "check"]),  # NOTE: `statix` respects `.gitignore` only with no or relative path.
```

### Rule 2: Comments are prose

Comments and Markdown prose should be treated as continuous text formatted as paragraphs, with proper punctuation
and capitalization. Even a single-sentence comment must start with a capital letter and end with punctuation
(`.`, `!`, or `?`).

**Exceptions:**

- If the comment starts with a backtick-quoted code reference, the capitalization follows the identifier's own casing.
- If the last word of a comment is a URL, do not append a trailing dot — URL pickers may misparse it.
  Start a new line for the next sentence instead.

**Good:**

```lua
-- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
-- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
lazy = true,
version = false, -- Always use the latest git commit.
```

```lua
enabled = true,
-- `bullet = true` and `right_pad = 2` makes line same width rendered and unrendered.
bullet = true,
right_pad = 2,
```

```lua
clangd = {
  -- See https://www.lazyvim.org/extras/lang/clangd
  cmd = {
```

**Bad:**

```lua
-- Do not add "v" mode: it might conflict with other keymaps   ← missing dot
mode = { "i", "n", "t" },
```

```lua
{ "folke/tokyonight.nvim", opts = { style = "night" } }, -- moon, storm, night, day   ← not a sentence
```

### Rule 3: Line length ≤ 120 characters

No comment line may exceed 120 characters. When a sentence does not fit, split it at a meaningful boundary —
after a comma, or before a conjunction such as "and", "or", "which". A sentence that fits within 120 chars
may still be split across lines.

**Good:**

```lua
-- `LazyVim` defaults for `<leader><space>` find files and `<leader>/` live grep open in a "root" directory.
```

```lua
-- `LazyVim` defaults for `<leader><space>` find files and
-- `<leader>/` live grep open in a "root" directory.
```

```lua
-- For example, in cases with nested projects inside one repo,
-- `lsp` detector correctly recognizes root of each sub-project, whereas I need a root of entire project.
```

**Bad:**

```lua
-- For example, in cases with nested projects inside one repo, `lsp` detector correctly recognizes root of each sub-project, whereas I need a root of entire project.
```

```lua
-- For example, in cases with nested projects inside one repo, `lsp` detector correctly recognizes root of each
-- sub-project, whereas I need a root of entire project.   ← split at a bad boundary
```

### Rule 4: One sentence per line (generally)

Different sentences should generally each start on their own line. Two short sentences may share a line if together
they fit within 120 characters. A sentence must never be split across a line boundary with another sentence mixed in.

**Good:**

```lua
-- `LazyVim` defaults for `<leader><space>` find files and `<leader>/` live grep open in a "root" directory.
-- This `root` directory has a rather complicated algorithm,
-- which defaults to `{ "lsp", { ".git", "lua" }, "cwd" }` and does not work for me well.
-- For example, in cases with nested projects inside one repo,
-- `lsp` detector correctly recognizes root of each sub-project, whereas I need a root of entire project.
```

```lua
-- Setup is very cumbersome. At the end the problem was in a very slow performance.
```

**Bad:**

```lua
-- `LazyVim` defaults for `<leader><space>` find files and
-- `<leader>/` live grep open in a "root" directory. This `root` directory has a rather complicated algorithm,
-- which defaults to `{ "lsp", { ".git", "lua" }, "cwd" }` and does not work for me well. For example,
-- in cases with nested projects inside one repo, `lsp` detector correctly recognizes root of each sub-project,
-- whereas I need a root of entire project.
```

## Commit Message Style

Commit messages must be short.
In ~95% of cases the message is only the title (`type(scope): summary`, as in the existing history) — no body at all.

A small body is allowed only for notes about git ordering and implementation plans rather than about the code itself —
e.g. "Preparation for the upcoming change...", or how this commit relates to neighboring patches in a series.
All information related to the code itself MUST live in the code (comments, docs), not in the commit message.

### Exception: commits that delete code

When a commit removes code — especially a workaround that is no longer needed — the rule above inverts.
Deleted code has nowhere to live, so leaving behind a ghost comment describing what used to be there
and why it went away just trades one piece of dead weight for another.
Delete the code cleanly and put the explanation in the commit body instead, where `git log` and `git blame` will surface it
for whoever wonders why the workaround disappeared.

### Refactoring commits come first

If a patch requires changes in existing code — extracting a helper, extending a function signature,
moving things around — commit that refactoring separately, before the commit that builds on it.
The refactoring commit must not change behavior; the main commit then contains only the new functionality.

## Trust These Instructions

These instructions are comprehensive and tested. Only search for additional information if:

- The instructions are incomplete for your specific task
- You encounter an error not documented here
- You need details about code not covered in the structure section

When you encounter the documented gitleaks shallow-history issue, apply the documented workaround rather than investigating alternatives.
