# Wrapper modules

`fzf.nix` is a nix-wrapper-modules module, evaluated independently of Home Manager:

```nix
wlib.evalPackage {
  imports = [ ./fzf.nix ];
  inherit pkgs;
  commands = {
    editor = "${pkgs.neovim}/bin/nvim";
    imagePreview = "${pkgs.coreutils}/bin/true";
    clipboard = "${pkgs.coreutils}/bin/cat";
    privilege = "";
  };
  dependencies = {
    nixSearchTv = pkgs.unstable.nix-search-tv;
    tealdeer = pkgs.tealdeer;
  };
}
```

The result is the configured fzf package.
Its `shellIntegrations` attribute provides Bash, Fish, Zsh, and Nushell hooks.
Each integration exposes `packages`, `earlyInteractiveInit`, and `interactiveInit`.
Consumers make the packages available on `PATH` and load the hooks in their interactive startup stages.
The early stage installs upstream widgets before other history integrations take ownership of their bindings.
Nushell currently provides only custom picker bindings.

The wrapper defaults `FZF_DEFAULT_OPTS` only when unset.
Bash, Fish, and Zsh hooks also default the file command, file options, and history options only when unset.
Explicitly empty values are preserved.

Command inputs are shell command fragments, not unescaped executable paths.
The editor must accept file names and Neovim-style `+line` arguments.
The image preview receives a file name and fzf's preview environment variables.
The clipboard command reads process IDs from standard input.
The privilege command prefixes htop invocations; an empty string runs htop without elevation.
Companion tools retain responsibility for their own configuration and mutable data.

`../home-manager/shell/fzf.nix` supplies the current desktop commands and configured companion packages,
installs the wrapper, and connects the prepared hooks to Home Manager startup options.
It does not require changes to the shell modules.

`nix build .#checks.x86_64-linux.fzf` checks wrapper defaults and shell integration behavior without activating a home.
