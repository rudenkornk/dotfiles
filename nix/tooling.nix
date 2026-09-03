{ pkgs, ... }:

let
  python = pkgs.python313;

  # Python env with libraries of the `dotfiles` CLI itself.
  pyEnv = python.withPackages (
    ps: with ps; [
      click
      rich
      ruamel-yaml
      typer
    ]
  );

  # Tools the `dotfiles` CLI shells out to, shared between the dev shell and the CLI package.
  tools = with pkgs; [
    bashInteractive # Without this there would be broken console when using direnv.

    # Tools for dumping gnome settings.
    dconf
    dconf2nix

    # Secrets tooling for `updatekeys` and `bootstrap-crypto`.
    age-plugin-tpm
    sops
    unstable.atuin # TODO(rudenkornk): change to stable in next 26.11 release.

    # Format & lint tools.
    fish
    git
    gitleaks
    jq
    kdlfmt
    markdownlint-cli2
    mypy
    nixfmt
    prettier
    ruff
    shellcheck
    shfmt
    statix
    stylua
    typos
    yamllint
    (mdformat.withPlugins (
      ps: with ps; [
        mdformat-beautysh
        mdformat-gfm
      ]
    ))

    # Install tools.
    disko
    e2fsprogs # chattr, lsattr, etc.
    git
    mokutil
    nixos-facter
    nixos-install
    sbctl
    util-linux # lsblk.
    vim
  ];

  # Only the CLI sources, so unrelated repo changes do not rebuild the package.
  cliSrc = pkgs.lib.fileset.toSource {
    root = ../.;
    fileset = ../dotfiles_py;
  };

  mkDotfiles =
    { name, runtimeInputs }:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = ''
        # `mypy` resolves the CLI's third-party imports through PYTHONPATH, so expose the python env there too.
        export PYTHONPATH="${cliSrc}:${pyEnv}/${python.sitePackages}''${PYTHONPATH:+:$PYTHONPATH}"
        exec python3 -m dotfiles_py "$@"
      '';
    };

  dotfiles = mkDotfiles {
    name = "dotfiles";
    runtimeInputs = [ pyEnv ] ++ tools;
  };

  commonShellHook =
    # bash
    ''
      # `mypy` resolves the CLI's third-party imports through PYTHONPATH, so expose the python env there too.
      export PYTHONPATH="$PWD/src:$PWD:${pyEnv}/${python.sitePackages}:$PYTHONPATH"
      mkdir --parents __build
      echo -e '#!/usr/bin/env bash\n\npython3 -m dotfiles_py "$@"' > __build/dotfiles
      chmod +x __build/dotfiles
      export PATH="$PWD/__build:$PATH"

      # Hook setup is an idempotent symlink refresh, so it is safe to run on every shell entry.
      # Worktrees are skipped (`.git` is a file there); they share the main checkout's hooks anyway.
      if [ -d .git ]; then
        dotfiles --log-level warning hooks
      fi
    '';
in
{
  devShells = {
    default = pkgs.mkShell {
      packages = [ pyEnv ] ++ tools;
      shellHook = commonShellHook;
    };
  };

  packages = { inherit dotfiles; };

  apps = {
    default = {
      type = "app";
      program = pkgs.lib.getExe dotfiles;
    };
  };
}
