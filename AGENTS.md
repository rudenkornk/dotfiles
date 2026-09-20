# AI Instructions for dotfiles Repository

## Repository Overview

This repository defines a reproducible NixOS and Home Manager setup through Nix flakes.
It includes a Python CLI, Neovim (LazyVim), tmux, fish, and development toolchains.

## Development and Validation

### Command Execution

Run ordinary commands, including Git, searches, and installed tools, directly in the normal shell environment.
Use `nix run . -- <command>` for the repository management CLI.
The flake app supplies the CLI's Python environment and tools; no manual dependency installation is needed.
For example, use `nix run . -- hooks` to install the repository hooks.
See `readme.md` for bootstrap and recovery instructions.

### Validation Policy

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

## Repository Map and Conventions

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

### Nix Conventions

- **Add new Nix and configuration files to the git staging area so the flake can see them.**
- The default package set is stable; `pkgs.unstable` provides packages from a separate input.
- Home Manager configurations cover every configured `user@host` pair and are registered as flake checks.
- `local.home.file` in `nix/modules/home/` links directory trees into `$HOME` one file at a time,
  allowing several modules to populate a shared target directory.

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

## Code Style Guidelines

- **Python**: Strict mypy, ruff with "ALL" rules (see pyproject.toml ignores), 120 char line length, no docstrings for most functions
- **Nix**: nixfmt with --strict, statix linting
- **Shell**: shellcheck, shfmt (2-space indents from .editorconfig)
- **Markdown**: 180 char line length, HTML allowed
- **YAML**: 120 char line length, no document-start
- **Lua**: stylua (2-space indents)
- **KDL**: kdlfmt

## Implementation Scope and Complexity

Prefer the most straightforward implementation for the current task.
Small behavioral compromises are acceptable when avoiding them requires substantially more complexity.
Optimize for readable code and fewer responsibilities to maintain.

### Start with the simplest viable approach

- For existing code, first consider changing configuration, adding a parameter, or using an existing extension point.
- For new code, start with a direct implementation for the current inputs and callers.

### Weigh behavior against implementation cost

A small compromise affects convenience or optional coverage while preserving the main workflow.
Examples include retaining an existing upstream limitation or supporting explicitly named variants
instead of every possible configuration.

Prefer such compromises when the alternative requires substantial special-case code, adapters, or state management.
If unsure whether a compromise is acceptable, present explained choices.

### Let simple utilities fail naturally

For internal utilities and configuration glue, exceptions or panics are acceptable when an operation cannot succeed.
Use the caller's established preconditions and the underlying API's error behavior.

### When new code/infrastructure is required or recommended

If decided to go with a complex solution, then **design a plan** and split it into these major steps:

1. Refactoring existing **code structure** (if needed).\
   This step never changes functionality or behavior. Usually includes code motion, formatting, renaming.
   This is something which is very easy to prove equivalence with a previous version.

   This steps typically deserve its one single separate commit and is not limited by size.

1. Refactoring existing **code functionality**. Adding new glue/infrastructure code.\
   Not yet a meaningful part of an actual feature. Examples include:

   - Add new glue/infrastructure/helpers.
   - Use new glue/infrastructure/helpers in existing code replacing old inline implementation.
   - Support new simple cases in existing code.
   - Make existing code more defensive.
   - Add the tests for an untested area vulnerable to dev mistakes.
   - Add more logging / instrumentation where it was needed.

   This step NEVER includes changes related to changed code indent, changed formatting, style, etc.
   All of that should have happened on the previous step.

   This steps may consist of any number of commits. Each of those should be readable and easy to verify on its own.

1. Implementing an actual feature.\
   This bullet typically deserve only one single commit with mostly `+` diff, less that 250 lines of code.

   If implementing a big feature with different functionality, decompose it:

   - For new files: a simple and straightforward base layer. Commit.
   - Next several complications, each should have its own commit.
     (This relate both when adding to new file, or changing existing one.)

1. Apply feature to the code.\
   Typically a single refactoring commit which replaces old approach with a new one over the codebase.

As said, this should be applied recursively.
Refactoring existing functionality on upper level may become a feature if decomposed further.
A good sign that a stage decomposition is needed (except for structural refactoring)
is net addition of more than 250 lines of code (do not treat this too literally, though).

**Each step on its own is affected by main rules of simplicity from previous topics.**

Example of this workflow:

1. Refactoring code **structure**:\
   9c1678df7a54: refactor(merge-config): rename json mode to dict.
1. Refactoring code **functionality** (simple generalization):\
   8cd565661db1: refactor(merge-config): generalize dictionary merging.
1. Refactoring code infra
   (added `typer` since future code now requires non-stdlib deps and we can relax stdlib requirement):\
   742c9b4965cd: refactor(merge-config): use typer for argument parsing.
1. Adding lint tests:\
   e35a6fba6419: test(merge-config): add package-local lint checks.
1. Feature 1 (decomposed out of a bigger feature request):\
   f43183ebdb62: feat(merge-config): infer dictionary formats from target.
1. Feature 2 (the main requested part):\
   5126b3df0523: feat(merge-config): support jsonc in merge-config util.
1. Feature 3 (additional planned feature):\
   c807d4773ec9: feat(merge-config): route clear merge-config configs via XDG_RUNTIME_DIR.
1. Refactoring: finally a usage of requested feature in the code:\
   15d128092db0: refactor(corp): generate opencode corp config using dict merge instead of a block one.

This entire sequence can itself be a prerequisite stage of a larger change.

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

## Trust These Instructions

Use the documented workflows.
Look up additional information only for task-specific details not covered here or errors without a documented workaround.
