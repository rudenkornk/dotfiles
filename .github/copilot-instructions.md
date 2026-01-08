# Copilot Instructions for dotfiles Repository

## Repository Overview

This is a **NixOS configuration repository** (~640KiB, 130 files) that provides a complete, reproducible personal machine setup.
The repository focuses on configuring development tools including Neovim (LazyVim-based), tmux, fish shell, and support for C++, Python, LaTeX, and Lua development.

**Key Technologies:**

- **NixOS/Nix Flakes**: Primary configuration system (21 .nix files)
- **Python 3.13**: CLI tooling and automation (8 .py files in `dotfiles_py/`)
- **Home Manager**: User environment configuration
- **Languages**: Shell scripts (.sh, .fish), Lua configs (21 files), Nix expressions
- **Package Management**: uv (Python), Nix flakes

## Build and Validation Commands

### Environment Setup

**ALWAYS run commands inside the Nix development shell unless you're running nixos-rebuild:**

```bash
nix develop
```

This command:

- Takes ~10-60 seconds on first run (may fetch packages from cache.nixos.org)
- Automatically runs `uv sync` to install Python dependencies into `.venv/`
- Activates the virtual environment automatically
- Provides all necessary tools: python313, uv, formatters, linters, and more

**CRITICAL:** Do NOT run `uv sync` manually. The `nix develop` shell hook handles this automatically.

### Primary Commands

All commands below assume you're inside `nix develop`:

1. **Format Check** (~1-2 seconds):

   ```bash
   dotfiles format --check
   ```

   Runs formatters in check mode: statix, nixfmt, ruff, mdformat, shfmt, fish_indent, prettier, stylua.

1. **Format (Apply)** (~1-2 seconds):

   ```bash
   dotfiles format
   ```

   Same formatters as above, but applies changes.

1. **Lint** (~7-8 seconds):

   ```bash
   dotfiles lint
   ```

   Runs comprehensive linting:

   - `gitleaks git`: Checks entire git history for leaked credentials (scans 1344 commits, ~2MB in 198ms)
   - `statix check`: Nix linter
   - `mypy`: Python type checking (strict mode)
   - `ruff check`: Python linter
   - `yamllint --strict`: YAML linting for `.github/` directory
   - `shellcheck`: Shell script linting (6 .sh files)
   - `markdownlint`: Markdown linting (note: command name is `markdownlint-cli2`)
   - `typos`: Spell checking

1. **Flake Check** (~10 seconds):

   ```bash
   nix flake check
   ```

   Validates flake structure and evaluates NixOS/Home Manager configurations for `dellxps` host and two users.

1. **Git Hooks Setup**:

   ```bash
   dotfiles hooks
   ```

   Symlinks pre-commit hook that prevents committing sensitive files (ssh keys, vpn configs, credentials).

### CI Pipeline

The GitHub Actions workflow (`.github/workflows/workflow.yml`) runs on all PRs and main branch pushes:

```yaml
  - nix flake check --no-build
  - nix develop --command dotfiles format --check
  - nix develop --command dotfiles lint
```

**ALWAYS replicate these three commands locally before committing** to avoid CI failures.

## Known Issues and Workarounds

1. **Gitleaks Requires Full Git History**:

   - The lint command checks the entire git history starting from first commit `78946fc7d7e562042c62d589b331abf222c688e7`.
   - If git history is shallow, `dotfiles lint` will fail with "Looks like git history is shallow and credential check cannot be performed."
   - **Workaround**: Ensure you have the full git history (`git fetch --unshallow` if needed).

1. **Missing Markdownlint Binary**:

   - For some reason even after entering `nix develop`, `markdownlint-cli2` binary is missing in the shell.
   - To work around this, run `nix-shell -p markdownlint-cli2` to enter a shell with `markdownlint-cli2` available.

1. **Path Dependencies**:

   - All tools (nixfmt, ruff, mypy, etc.) must be available in the `nix develop` environment.
   - Do NOT attempt to use system Python or pip-installed tools—they will be incorrect versions.

## Project Structure

### Root Directory Files

- `flake.nix`: Nix flake defining NixOS configs, Home Manager configs, and dev shell
- `flake.lock`: Locked dependency versions (nixpkgs 25.11, home-manager, sops-nix)
- `pyproject.toml`: Python project config with dependencies, ruff/mypy/black/pylint settings
- `uv.lock`: Python dependency lock file (417 lines)
- `readme.md`: User-facing documentation with bootstrap instructions
- `manual_tests.md`: Interactive test scenarios (fzf, tmux)
- `license.md`: MIT license

### Configuration Files

- `.editorconfig`: Code style (2-space indents for .sh, 120 char line length for .yaml)
- `.gitleaks.toml`: Credential leak detection config with allowlists
- `.yamllint.yaml`: YAML linting rules (120 char max, document-start disabled)
- `.markdownlint.yaml`: Markdown rules (180 char line length, MD033/MD024/MD025 disabled)
- `.prettierrc.json`: Empty (uses defaults)
- `.prettierignore`: Ignores lazy-lock.json, lazyvim.json, \_\_build\_\_, \_\_artifacts\_\_, .venv
- `.stylua.toml`: Lua formatter config (2-space indents)
- `.luarc.json`: Lua LSP config for Neovim development

### Python CLI (`dotfiles_py/`)

**Entry point**: `dotfiles_py/cli.py` defines typer app with commands:

- `lint`: Runs all linters (see Build Commands above)
- `format`: Runs all formatters with `--check` flag option
- `hooks`: Sets up git hooks from `dotfiles_py/data/hooks/`
- `gnome`: Regenerates GNOME dconf settings from rules
- `password`: Generates random passwords

**Key modules**:

- `cli.py`: Main CLI app, command definitions, logging setup
- `utils.py`: Shell command runner, retry decorator, makelike decorator, YAML utilities
- `targets/lint.py`: Lint and format implementations
- `targets/hooks.py`: Git hooks symlinking logic
- `targets/gnome.py`: GNOME configuration generation

**Data files**:

- `dotfiles_py/data/hooks/pre-commit`: Pre-commit hook preventing sensitive file commits
- `dotfiles_py/data/scripts/`: Utility shell scripts (google_takeout.sh, nvim_time.sh, etc.)

### Nix Configuration (`nix/`)

**Structure**:

- `nix/configuration.nix`: NixOS system configuration (boot, networking, users, desktop, VPN, sops secrets)
- `nix/hosts/dellxps/hardware-configuration.nix`: Hardware-specific config
- `nix/home-manager/home.nix`: Home Manager config importing all program configs
- `nix/home-manager/programs/`: Individual program configs (atuin, bash, docker, eza, fish, git, kitty, lazygit, mypy, neovim, oh-my-posh, ruff, tmux, yazi, zoxide)
- `nix/home-manager/dconf/`: GNOME settings (settings.nix, rules.yaml)
- `nix/home-manager/secrets/`: Encrypted secrets (SSH keys, VPN configs) using sops
- `nix/home-manager/configs/`: Dotfiles symlinked to home directory
- `nix/keyboard/`: Custom keyboard layouts (qwerty_rnk, jcuken_rnk)

**Key Nix Patterns**:

- Uses NixOS 25.11 (stable channel)
- Home Manager manages user environment for `rudenkornk` and `rudenkornk_corp` users
- Secrets encrypted with sops-nix and age
- Custom keyboard layouts via xkb
- Fish shell is primary shell (11 .fish files)
- Neovim config based on LazyVim

### Important File Locations

- Python source: `dotfiles_py/{cli.py,utils.py,targets/*.py}`
- Nix configs: `nix/{configuration.nix,home-manager/home.nix,home-manager/programs/*.nix}`
- Git hooks: `dotfiles_py/data/hooks/pre-commit`
- CI workflow: `.github/workflows/workflow.yml`
- Format configs: `.editorconfig`, `.prettierrc.json`, `.stylua.toml`, `pyproject.toml` (ruff/black/isort sections)
- Lint configs: `.yamllint.yaml`, `.markdownlint.yaml`, `.gitleaks.toml`, `pyproject.toml` (mypy/ruff/pylint sections)

## Validation Steps

Before submitting changes:

1. **Format**: `nix develop --command dotfiles format`
1. **Lint**: `nix develop --command dotfiles lint` (takes ~7-8 seconds)
1. **Flake Check**: `nix flake check` (takes ~10 seconds)

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

## Trust These Instructions

These instructions are comprehensive and tested. Only search for additional information if:

- The instructions are incomplete for your specific task
- You encounter an error not documented here
- You need details about code not covered in the structure section

When you encounter the documented issues (gitleaks shallow history, markdownlint naming), apply the documented workarounds rather than investigating alternatives.
