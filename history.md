# Dotfiles Project Evolution

**Repository Timeline**: November 2021 - Present (January 2026)\
**Total Commits**: 1,380 commits\
**Total Duration**: ~4.2 years

This document chronicles the complete evolution of a personal dotfiles repository from simple manual configuration files to a sophisticated,
fully reproducible NixOS-based system configuration spanning 1,380 commits across 5 major architectural rewrites.

> **NOTE: GENERATED WITH AI.**

______________________________________________________________________

## Table of Contents

1. [Phase 1: Manual Configuration Era (Nov 2021 - Apr 2022)](#phase-1-manual-configuration-era-nov-2021---apr-2022)
1. [Phase 2: Bash Script Automation (Apr 2022 - Dec 2022)](#phase-2-bash-script-automation-apr-2022---dec-2022)
1. [Phase 3: Ansible Infrastructure (Dec 2022 - May 2024)](#phase-3-ansible-infrastructure-dec-2022---may-2024)
1. [Phase 4: Python-Driven Automation (May 2024 - Oct 2025)](#phase-4-python-driven-automation-may-2024---oct-2025)
1. [Phase 5: Complete NixOS Rewrite (Oct 2025 - Present)](#phase-5-complete-nixos-rewrite-oct-2025---present)
1. [Technology Evolution Timeline](#technology-evolution-timeline)
1. [Current State (January 2026)](#current-state-january-2026)
1. [Major Milestones](#major-milestones)
1. [Statistics and Insights](#statistics-and-insights)

______________________________________________________________________

## Phase 1: Manual Configuration Era (Nov 2021 - Apr 2022)

**Duration**: ~5 months\
**Commits**: 11 commits (2021) + early 2022 commits\
**Key Commit**: `78946fc` - Initial commit (Nov 7, 2021)

### The Beginning

The project started as a simple collection of configuration files with minimal automation. The initial commit contained:

- `.gitconfig` - Git configuration
- `.vimrc` - Vim editor configuration
- `.tmux.conf` - Tmux terminal multiplexer settings
- `logid.cfg` - Logitech mouse configuration
- Custom keyboard layouts (qwerty_rnk, jcuken_rnk variants)

### Characteristics

- **Manual deployment**: Configuration files were manually copied to appropriate locations
- **README-based instructions**: `readme.txt` contained informal installation notes
- **Simple structure**: Flat directory structure with dotfiles at root
- **Basic version control**: No automation, just tracking configuration changes
- **Editor focus**: Early iterations focused heavily on Vim/Neovim configuration
  - Added Vundle plugin manager (Jan 2022)
  - Integrated YouCompleteMe (YCM) for code completion
  - Custom keymaps and language-specific settings

### Key Technologies

- Vim/Neovim (initial setup)
- Tmux (prefix changed to `C-s` early on)
- Custom XKB keyboard layouts for Linux
- Git for version control

______________________________________________________________________

## Phase 2: Bash Script Automation (Apr 2022 - Dec 2022)

**Duration**: ~8 months\
**Commits**: ~493 commits in 2022\
**Key Commit**: `283da71` - "Rewrite most of informal notes as bash install script" (Apr 24, 2022)

### The First Automation Wave

In April 2022, the project underwent its first major transformation from manual instructions to automated bash scripts.
The `readme.txt` informal notes were replaced with executable scripts:

- `config_system.sh` - System-level configuration (38 lines)
- `config_user.sh` - User-level configuration (53 lines)
- `bashrc` - Bash shell configuration

### Neovim Revolution (July 2022)

This phase saw explosive Neovim development:

1. **NvChad Migration** (Jul 9, 2022 - `a37a926`):

   - Complete rewrite of Neovim configuration using NvChad framework
   - Migrated from vim-plug to Packer plugin manager (Jul 1, 2022)
   - Deleted 493 lines of old init.lua, replaced with modular NvChad structure
   - Added custom plugins: Navigator, better-escape, illuminate, indent-blankline

1. **Lua Configuration** (Jul 25, 2022 - `f47e5f6`):

   - Rewrote configuration parts in Lua for better Neovim integration
   - Created Windows Terminal theme converter from NvChad themes

### Component Expansion

The repository grew to include configurations for:

- **Shell utilities**: fish shell, command-line tools (exa, fzf, zoxide)
- **Development tools**: Docker, various language LSPs
- **Desktop applications**: Chrome, Telegram, Slack, Zoom, VS Code
- **System tools**: Clipboard managers, Tilda terminal <!-- typos: ignore -->
- **Windows support**: WSL configuration, Windows Terminal themes

### Statistics

- **116 Neovim-related commits** (most active area)
- **41 shell-related commits**
- **38 secrets management commits** (early git-secret implementation)
- Multiple NvChad updates throughout the year

______________________________________________________________________

## Phase 3: Ansible Infrastructure (Dec 2022 - May 2024)

**Duration**: ~17 months\
**Commits**: 333 (2023) + 240 (2024)\
**Key Commit**: `66ab839` - "Rewrite configuration with Ansible" (Dec 1, 2022)

### The Great Ansible Transformation

December 2022 marked the project's second major rewrite. The entire bash-based configuration system was replaced with a professional Ansible infrastructure.

**Migration Statistics**:

- **231 files changed**
- **3,938 insertions, 1,948 deletions**
- Complete restructuring of the codebase

### New Infrastructure Components

1. **Ansible Playbooks**:

   - `playbook.yaml` - Main playbook
   - `playbook_bootstrap_control_node.yaml` - Control node setup
   - `playbook_bootstrap_hosts.yaml` - Target hosts setup
   - `playbook_dotfiles_container.yaml` - Container support

1. **Configuration Files**:

   - `ansible.cfg` - Ansible configuration
   - `.ansible-lint` - Linting rules
   - `inventory.yaml` - Infrastructure inventory
   - `.flake8` - Python linting for Ansible scripts

1. **Role-Based Structure**:

   - Organized configuration into Ansible roles
   - Each tool (neovim, tmux, fish, docker, etc.) became a separate role
   - Idempotent deployment model

1. **Python Support Scripts**:

   - `scripts/support.py` (87 lines)
   - `scripts/update.py` (147 lines)
   - `scripts/utils.py` (187 lines)
   - `scripts/graph.py` - Role dependency visualization

### Editor Evolution Continues

1. **LazyVim Transition** (2023):

   - Added LazyVim draft config alongside NvChad
   - NvChad 2.0 adoption (`c1ac3e7`)
   - Eventually fully transitioned to LazyVim (`5f4ee55`)
   - Removed NvChad v1 (`450d1d6`)

1. **LSP and Tooling Improvements**:

   - Ansible LSP integration
   - Python formatters and linters (ruff, black, mypy)
   - Better DAP (Debug Adapter Protocol) support
   - Markdown rendering and editing enhancements

### Secrets Management

- Transitioned from git-secret to **sops** (Software Operations Secret) with **age encryption**
- Added `.sops.yaml` configuration
- Encrypted SSH keys, VPN configs, API credentials
- Secure editor setup for encrypted files

### Key Technologies Added

- **Ansible**: Infrastructure as Code
- **sops + age**: Modern secrets management
- **fish shell**: Enhanced shell experience
- **LazyVim**: Neovim distribution (replacing NvChad)
- **Python tooling**: mypy, ruff, black, pylint
- **LSP ecosystem**: Comprehensive language server support

### Platform Expansion

- Added **Fedora support** (May 2024 - `3a13dcb`)
- Maintained Ubuntu/Debian compatibility
- WSL (Windows Subsystem for Linux) continued support

### 2023-2024 Highlights

- **113 Neovim commits (2023)**, **29 in 2024** (stabilization phase)
- **19 Ansible commits (2023)**, focusing on refinement
- Migrated from **exa to eza** (Apr 2024)
- Added **Docker** configuration and management
- Comprehensive **git configuration** with delta pager

______________________________________________________________________

## Phase 4: Python-Driven Automation (May 2024 - Oct 2025)

**Duration**: ~17 months\
**Commits**: Rest of 2024 (240 total) + 2025 until Oct (244 total)\
**Key Commit**: `780e75c` - "Rewrite makefile with python" (May 24, 2024)

### Makefile Elimination

The Makefile-based build system (added Apr 29, 2022 - `20a298a`) was completely replaced with a Python CLI tool.

**Migration Details** (`780e75c`):

- Removed `makefile` (118 lines)
- Removed `config.sh` (106 lines)
- Added comprehensive Python CLI in `scripts/src/`
- **592 insertions, 337 deletions**

### New Python CLI Architecture

Created `dotfiles_py/` module with:

1. **Core CLI** (`cli.py`):

   - Built with **Click** framework (migrated from argparse - May 18, 2024)
   - Migrated to **Typer** later for better type support
   - Rich logging support (migrated May 2, 2025)

1. **Command Targets**:

   - `targets/lint.py` - Comprehensive linting suite
   - `targets/format.py` - Multi-tool formatting
   - `targets/bootstrap.py` - System bootstrapping
   - `targets/config.py` - Configuration management (114 lines)
   - `targets/ansible_collections.py` - Ansible dependencies (55 lines)
   - `targets/hooks.py` - Git hooks installation
   - `targets/roles_graph.py` - Dependency visualization
   - `targets/update.py` - Update management
   - `targets/gnome.py` - GNOME configuration generator

1. **Utilities**:

   - `utils.py` - Shell command execution, retry logic, YAML handling
   - Makelike decorator for build system behavior
   - Rich terminal output formatting

### Package Management Evolution

**UV Adoption** (Aug 21, 2024 - `25b4b76`):

- Migrated from pip to **uv** for Python package management
- Added `uv.lock` lock file
- Created `pyproject.toml` for dependency management
- Significantly faster installation and resolution

### Nix Introduction (May 2025)

While still Ansible-based, **Nix** was first introduced:

- `fa0c273` - "Add nix installation" (May 10, 2025)
- Initial `flake.nix` added to manage certain tools
- Hybrid Ansible + Nix approach
- Used Nix for:
  - Static fish shell installation
  - Neovim distribution
  - Development tools (nixfmt, etc.)

### Shell Evolution

- **Nushell experimentation** (May 12, 2025 - `645183e`)
- **Static fish installation via Nix** (May 12, 2025 - `ece5566`)
- Auto-activation of Python virtual environments
- Enhanced prompt with oh-my-posh

### Linting and Formatting Standardization

**Ruff Migration** (May 26, 2025 - `a14e1e7`):

- Migrated Python linting to **ruff** (replacing pylint/flake8)
- Unified Python formatting (ruff format + black compatibility)
- Significantly faster linting
- Type checking with strict **mypy**

**Comprehensive Linting Suite**:

- **statix** - Nix linting
- **shellcheck** - Shell script linting
- **yamllint** - YAML validation
- **markdownlint** - Markdown standards
- **typos** - Spell checking across codebase
- **gitleaks** - Credential leak detection (entire git history scanning)

### GNOME Desktop Configuration

Added sophisticated GNOME configuration management:

- `targets/gnome.py` (153+ lines) - Automated dconf settings generation
- `dconf/rules.yaml` - Declarative configuration rules
- Python-based settings regeneration from rules
- Keyboard shortcuts, window management, appearance settings
- Pop Shell tiling extension integration (Jan 2026)

### GitHub Actions CI/CD

Comprehensive workflow established:

- Automated linting on PRs
- Format checking
- Secret scanning
- Multi-platform testing

______________________________________________________________________

## Phase 5: Complete NixOS Rewrite (Oct 2025 - Present)

**Duration**: Oct 2025 - Present (~3 months actively developed)\
**Commits**: 244 (rest of 2025) + 59 (Jan 2026)\
**Key Commit**: `bfdfb99` - "feat(project): rewrite everything with NIX" (Oct 23, 2025)

### The Ultimate Rewrite

October 23, 2025 marked the most radical transformation: **complete elimination of Ansible** in favor of pure NixOS configuration.

**Migration Scale**:

- Removed `ansible.cfg`, `inventory.yaml`, all playbooks
- Deleted `dotfiles.sh` (115 lines)
- Removed 430 lines from `targets/update_utils.py`
- Removed 265 lines from `targets/config.py`
- Deleted all Ansible role management code
- **Massive restructuring**: Focus shifted to declarative Nix expressions

### New NixOS Architecture

1. **System Configuration** (`nix/configuration.nix` - 188 lines):

   - NixOS system-level settings
   - Boot configuration (Limine bootloader)
   - Networking, users, desktop environment
   - Hardware-specific settings via `nix/hardware-configuration.nix`
   - VPN integration (WireGuard)
   - sops-nix for encrypted secrets

1. **Home Manager** (`nix/home-manager/home.nix`):

   - User environment management for:
     - `rudenkornk` (main user)
     - `rudenkornk_corp` (corporate user)
   - Declarative home directory configuration
   - Per-user package management

1. **Flake-Based System** (`flake.nix` - 100 lines):

   - Uses Nix flakes for reproducibility
   - NixOS 25.11 (stable channel)
   - Inputs:
     - `nixpkgs` - Main package repository
     - `home-manager` - User environment management
     - `sops-nix` - Secrets management
     - `nixos-hardware` - Hardware optimizations
     - Custom fish plugins as flake inputs
   - Development shell with all tools pre-configured

1. **Program-Specific Modules** (`nix/home-manager/programs/`):
   Each program has its own Nix module:

   - `neovim/` (1731 lines) - Complete Neovim setup with LazyVim configs
   - `fish/` (499 lines) - Fish shell with functions and configs
   - `oh-my-posh/` (261 lines) - Prompt theming with custom theme
   - `tmux/` (160 lines) - Terminal multiplexer with plugins
   - `git.nix` (150 lines) - Git configuration
   - `gnome-shell.nix` (70 lines) - GNOME settings
   - `yazi.nix` (51 lines) - File manager
   - `ruff.nix` (42 lines) - Python linter/formatter
   - `bash/` (37 lines) - Bash compatibility
   - `kitty.nix` (37 lines) - Terminal emulator
   - `atuin.nix` (32 lines) - Shell history sync
   - `lazygit.nix` (25 lines) - Git TUI
   - `docker-cli.nix` (10 lines) - Docker configuration
   - `mypy.nix` (10 lines) - Python type checker
   - `eza.nix` (9 lines) - Modern ls replacement
   - `zoxide.nix` (7 lines) - Smart directory jumping

1. **Secrets Management**:

   - **sops-nix** integration
   - **age encryption** with TPM-backed keys (`c63b96d` - Jan 2026)
   - Encrypted secrets stored in `nix/home-manager/secrets/`:
     - SSH keys
     - VPN configurations
     - API credentials (OpenAI, Anthropic, etc.)
     - Corporate credentials
   - Runtime secrets decryption
   - `sops-cached` utility for efficient secret access

1. **Configuration Files**:
   Actual dotfiles symlinked from `nix/home-manager/configs/`:

   - `.config/nvim/` - Complete Neovim configuration
     - LazyVim-based setup
     - Custom plugins: Avante → Sidekick (Jan 2026), blink, DAP, dial, duck
     - Language-specific configs (C++, Python, LaTeX, Lua)
     - Custom keymaps, clipboard integration (wl-clipboard for Wayland)
   - `.config/black` - Python formatter settings
   - `.config/luacheck/` - Lua linting
   - Fish functions and completions
   - Oh-My-Posh theme

### Python CLI Simplification

The Python CLI (`dotfiles_py/`) was dramatically simplified:

**Removed Commands** (no longer needed with Nix):

- `bootstrap` - NixOS installation handles this
- `config` - Nix manages all configuration
- `ansible_collections` - No more Ansible
- `update` - Nix handles updates
- `roles_graph` - No roles anymore
- `oh_my_posh` - Managed by Nix

**Remaining Commands**:

- `lint` - Still needed for CI/CD validation
- `format` - Code formatting across multiple languages
- `hooks` - Git hook management
- `gnome` - GNOME dconf settings regeneration from rules
- `password` - Random password generation utility

**CLI Refactoring** (`cli.py` - reduced from 146+ to fewer lines):

- Focus on linting and formatting only
- Integration with Nix development shell
- All linters/formatters provided by Nix environment

### Development Workflow

**Nix Development Shell**:

```bash
nix develop
```

This single command:

- Provides all development tools (python313, uv, formatters, linters)
- Automatically runs `uv sync` to install Python dependencies
- Activates Python virtual environment
- Takes 10-60 seconds on first run (cached afterwards)
- Creates reproducible development environment

**Key Commands**:

- `dotfiles format` - Format code
- `dotfiles lint` - Run all linters (~7-8 seconds)
- `dotfiles hooks` - Setup git hooks
- `nix flake check` - Validate Nix configuration (~10 seconds)

### AI Integration Evolution

The project shows significant AI tooling integration:

1. **GitHub Copilot CLI** (Jan 2026):

   - Custom instructions in `.github/copilot-instructions.md`
   - Detailed project documentation for AI assistance

1. **Neovim AI Plugins**:

   - Initial: **Avante.nvim** for AI-powered code assistance
   - Migration: **Sidekick** (Jan 3, 2026 - `db66d3a`)
   - Also tried: Supermaven (later removed), Minuet-AI
   - AI completions integrated with blink.cmp

### Latest Refinements (Dec 2025 - Jan 2026)

**NixOS Hardware Optimization**:

- Added `nixos-hardware` for Dell XPS optimizations (Jan 4, 2026)
- TPM-based secrets decryption (Jan 5, 2026)

**Additional Nix Utilities**:

- `nix-index` - Fast package searching
- `nix-search-tv` - TUI package search
- `nix-melt` - Dependency analysis

**Neovim Improvements**:

- Wayland clipboard support (`wl-clipboard`)
- Dial.nvim for increment/decrement pairs
- Better tmux integration
- Corporate vs. personal environment separation

**GNOME Polish**:

- Pop Shell tiling extension
- Refined keyboard shortcuts
- Updated launch shortcuts
- Removed too-slow easyeffects setup

**CI/CD Refinements**:

- Optimized linter execution order (typos before markdownlint)
- Comprehensive pre-commit hooks preventing secret commits
- Full git history scanning (1344 commits) for credentials

______________________________________________________________________

## Technology Evolution Timeline

### Configuration Management

1. **2021-2022**: Manual copying, bash scripts
1. **2022-2024**: Ansible playbooks and roles
1. **2024-2025**: Python CLI with Ansible backend
1. **2025-Present**: Pure NixOS with Home Manager

### Neovim Distributions

1. **2021**: Plain Vim
1. **Early 2022**: Vim-plug → Packer
1. **Jul 2022**: NvChad framework
1. **2023**: NvChad 2.0
1. **2023-Present**: LazyVim

### Python Package Management

1. **2022**: pip3
1. **2024**: Poetry (briefly considered)
1. **Aug 2024-Present**: uv

### Secrets Management

1. **2022**: git-secret (GPG-based)
1. **2024**: sops + age encryption
1. **2025-Present**: sops-nix with TPM backing

### Shell Environment

1. **2021**: Bash only
1. **2022**: Fish shell adoption
1. **2025**: Nushell experimentation (not adopted)
1. **2025**: Static fish via Nix

### Terminal Emulator

- **Kitty** (primary, stable throughout)
- Tmux for multiplexing (prefix: `C-s`)
- Windows Terminal theme support (2022)
- Tilda dropdown terminal (discontinued) <!-- typos: ignore -->

### Linting Tools Evolution

**Python**:

- flake8 → ruff
- pylint → ruff (supplementary)
- mypy (strict, throughout)

**Shell**:

- shellcheck (added 2025)

**Markdown**:

- markdownlint (added with CI)

**Nix**:

- statix (linting + fixing)
- nixfmt (formatting)

**Universal**:

- typos (spell checking, 2024+)
- gitleaks (credential scanning, 2022+)

______________________________________________________________________

## Current State (January 2026)

### Repository Structure

```txt
dotfiles/
├── flake.nix (100 lines) - Nix flake configuration
├── flake.lock - Locked Nix dependencies
├── pyproject.toml (130 lines) - Python project config
├── uv.lock - Python dependencies
├── nix/
│   ├── configuration.nix (188 lines) - NixOS system config
│   ├── hardware-configuration.nix - Hardware-specific settings
│   ├── home-manager/
│   │   ├── home.nix - Home Manager entry point
│   │   ├── programs/ - Per-program Nix modules (20+ programs)
│   │   ├── configs/ - Actual dotfiles (symlinked)
│   │   ├── secrets/ - Encrypted credentials (sops)
│   │   └── dconf/ - GNOME settings
│   └── keyboard/ - Custom XKB layouts
├── dotfiles_py/ - Python CLI tool
│   ├── cli.py - Main CLI entry point
│   ├── utils.py - Utilities
│   ├── targets/ - Command implementations
│   │   ├── lint.py
│   │   ├── gnome.py
│   │   └── hooks.py
│   └── data/ - Scripts and git hooks
├── .github/
│   ├── workflows/workflow.yml - CI/CD pipeline
│   └── copilot-instructions.md - AI assistant guide
└── Configuration files (.gitleaks.toml, .yamllint.yaml, etc.)
```

### Tech Stack

**Core Infrastructure**:

- NixOS 25.11 (operating system)
- Nix Flakes (package management + configuration)
- Home Manager (user environment)
- sops-nix + age (secrets, TPM-backed)

**Development Environment**:

- Python 3.13
- uv (package management)
- Nix development shell (reproducible environment)

**Editor**:

- Neovim (LazyVim distribution)
- 200+ plugins managed via lazy.nvim
- LSP support for: C++, Python, Lua, Nix, YAML, Markdown, LaTeX, Bash
- DAP debugging for multiple languages
- AI assistance (Sidekick, previously Avante)

**Shell & Terminal**:

- Fish shell (primary)
- Bash (compatibility)
- Kitty terminal emulator
- Tmux multiplexer
- oh-my-posh prompt

**CLI Tools**:

- eza (ls replacement)
- fzf (fuzzy finder)
- zoxide (smart cd)
- yazi (file manager)
- lazygit (git TUI)
- atuin (shell history)
- delta (git diff pager)

**Desktop Environment**:

- GNOME Shell
- Pop Shell (tiling extension)
- Declarative configuration via dconf

**Programming Languages Supported**:

- C++ (clang, cmake, gdb)
- Python (mypy, ruff, black, pytest)
- LaTeX (texlive)
- Lua (stylua, luacheck)
- Nix (nixfmt, statix)
- Shell (shellcheck, shfmt)
- Markdown, YAML, JSON, TOML

**CI/CD**:

- GitHub Actions
- Automated linting (8 tools)
- Format checking (8 formatters)
- Secret scanning (gitleaks on 1344 commits)
- Nix flake validation

### Reproducibility

The system is now **fully reproducible**:

1. Clone repository
1. Run `nixos-rebuild switch --flake .#dellxps`
1. Entire system configured: bootloader, kernel, packages, user environment, secrets

Development environment:

1. `nix develop` - Get identical dev environment
1. All tools at exact versions
1. Python dependencies automatically synced

### Key Metrics

- **130 Nix files** (`.nix`)
- **8 Python modules** (`.py`)
- **21 Lua config files** (Neovim)
- **11 Fish shell files** (`.fish`)
- **640 KiB total repository size**
- **20+ program configurations** (Neovim, fish, git, GNOME, tmux, kitty, etc.)

______________________________________________________________________

## Major Milestones

### Foundation (2021-2022)

1. **Nov 7, 2021** (`78946fc`) - Initial commit - First vim, tmux, keyboard configs
1. **Apr 24, 2022** (`283da71`) - Rewrite with bash scripts - First automation
1. **Jul 9, 2022** (`a37a926`) - NvChad adoption - Modern Neovim
1. **Jul 25, 2022** (`f47e5f6`) - Lua configs - Better Neovim integration

### Ansible Era (2022-2024)

1. **Dec 1, 2022** (`66ab839`) - Ansible rewrite - Professional infrastructure (231 files, 3938 additions)
1. **2023** (`5f4ee55`) - LazyVim transition - Final editor choice
1. **2024** (various) - sops adoption - Modern secrets management

### Python Modernization (2024-2025)

1. **May 18, 2024** (`05e37aa`) - Click CLI framework - Migrated from argparse
1. **May 24, 2024** (`780e75c`) - Python replaces Makefile - Full Python automation (592 insertions)
1. **Aug 21, 2024** (`25b4b76`) - UV adoption - Modern Python packaging
1. **May 10, 2025** (`fa0c273`) - Nix introduction - Hybrid Ansible+Nix phase
1. **May 26, 2025** (`a14e1e7`) - Ruff migration - Unified Python linting

### NixOS Revolution (2025-2026)

1. **Oct 23, 2025** (`bfdfb99`) - Complete NixOS rewrite - Ultimate reproducibility
1. **Jan 3, 2026** (`db66d3a`) - Sidekick AI - Latest editor evolution
1. **Jan 5, 2026** (`c63b96d`) - TPM secrets - Hardware-backed encryption

______________________________________________________________________

## Statistics and Insights

### Commit Distribution by Year

| Year | Commits      | Primary Focus                            |
| ---- | ------------ | ---------------------------------------- |
| 2021 | 11           | Foundation, manual configs               |
| 2022 | 493          | Bash automation, NvChad, Ansible rewrite |
| 2023 | 333          | Ansible refinement, LazyVim, secrets     |
| 2024 | 240          | Python CLI, UV, Fedora support           |
| 2025 | 244          | Nix adoption, complete NixOS rewrite     |
| 2026 | 59 (ongoing) | NixOS refinement, AI tools, TPM          |

### Activity by Category (All Time)

| Category | Commits | Peak Year              |
| -------- | ------- | ---------------------- |
| Neovim   | 441     | 2022 (116), 2023 (113) |
| Shell    | 131     | 2025 (39)              |
| Secrets  | 112     | 2024 (27)              |
| Python   | 50      | 2024 (15)              |
| Ansible  | 53      | 2023 (19)              |
| Nix      | 33      | 2026 (10)              |
| GNOME    | 23      | 2025 (10)              |

### Major Rewrites

1. **Bash Scripts** (Apr 2022) - First automation
1. **Ansible** (Dec 2022) - 231 files changed, IaC adoption
1. **Python CLI** (May 2024) - Makefile elimination, 592 insertions
1. **NixOS** (Oct 2025) - Complete paradigm shift, deleted Ansible entirely

### Tool Adoption Patterns

**Rapid Adoption** (< 3 months to full integration):

- NvChad (Jul 2022)
- Ansible (Dec 2022)
- UV (Aug 2024)
- LazyVim (2023)

**Gradual Migration** (6+ months):

- Fish shell (introduced 2022, primary by 2024)
- Nix (introduced May 2025, full rewrite Oct 2025)
- sops (introduced 2024, TPM-backed 2026)

**Experimental & Abandoned**:

- Nushell (added May 2025, not primary)
- NvChad (2022-2023, replaced by LazyVim)
- git-secret (2022-2024, replaced by sops)
- Avante (2025-2026, replaced by Sidekick)
- Supermaven (2025-2026, removed)

### Code Quality Evolution

**Linting Tools Added Over Time**:

- 2022: ansible-lint, flake8, yamllint
- 2023: mypy (strict mode)
- 2024: shellcheck, markdownlint
- 2025: statix (Nix), typos (spell checking), ruff
- 2026: gitleaks comprehensive scanning

**Formatter Standardization**:

- Python: black → ruff format (Aug 2024)
- Nix: nixfmt --strict (2025)
- Shell: shfmt with .editorconfig (2 spaces)
- Lua: stylua (2 spaces)
- Markdown: mdformat + prettier
- Fish: fish_indent

______________________________________________________________________

## Lessons from 1,380 Commits

### Architectural Evolution Drivers

1. **Reproducibility**: Manual → Bash → Ansible → NixOS

   - Each step improved reproducibility
   - NixOS achieved complete system reproducibility

1. **Complexity Management**: Flat configs → Roles → Modules

   - Started with flat files
   - Grew to role-based (Ansible)
   - Now modular Nix expressions

1. **Dependency Hell**: System packages → Ansible packages → Nix packages

   - Package management became declarative
   - Version conflicts eliminated with Nix

1. **Secrets Security**: Plain files → git-secret → sops → sops-nix + TPM

   - Continuous improvement in security posture
   - TPM-backed keys in 2026

### Technology Choices

**Winners**:

- **LazyVim**: Stable since 2023, feature-rich, actively developed
- **Fish shell**: Better UX than bash, widespread adoption
- **Kitty**: Fast, feature-rich, stable terminal
- **uv**: 10x faster than pip, excellent dependency resolution
- **NixOS**: Ultimate reproducibility, worth the learning curve

**Experimented & Moved On**:

- NvChad (good but LazyVim better for customization)
- Ansible (great for servers, overkill for single machine)
- git-secret (sops more flexible)
- Nushell (promising but fish sufficient)

### Development Patterns

1. **Commit Frequency**: Averaged ~328 commits/year (excluding 2021 and partial 2026)
1. **Rewrite Cycle**: Major rewrite every ~12-18 months
1. **Tool Migration**: Typically 2-3 tool replacements per year
1. **Editor Focus**: Neovim consistently highest activity (32% of categorized commits)

### Current Stability

After 5 rewrites, the project has reached high stability:

- NixOS provides strong foundation
- LazyVim stable for 2+ years
- Core tools standardized (fish, kitty, tmux)
- CI/CD catching issues early
- Declarative configuration reduces drift

______________________________________________________________________

## Future Trajectory

Based on the evolution pattern, likely future developments:

1. **More Nix Modules**: Additional programs converted to Nix modules
1. **NixOS Server Configs**: Extending to server infrastructure
1. **Cross-Machine Sync**: Multiple hosts with shared base config
1. **AI Tooling**: Continued AI editor integration evolution
1. **Performance Optimization**: Further Nix build optimization

The project has evolved from simple dotfiles to a comprehensive, reproducible personal computing environment spanning development, desktop, and security.
The NixOS rewrite represents likely the final major architectural shift, with future work focusing on refinement and expansion within the Nix ecosystem.
