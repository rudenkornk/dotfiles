{ pkgs, config, ... }:

# LSP servers.
{
  home.packages = with pkgs; [
    angular-language-server
    astro-language-server
    bash-language-server
    copilot-language-server
    docker-compose-language-service
    dockerfile-language-server
    gitlab-ci-ls
    gopls
    helm-ls
    kotlin-language-server
    lua-language-server
    marksman
    neocmakelsp
    nil
    ocamlPackages.ocaml-lsp
    phpactor
    pyright
    ruby-lsp
    rust-analyzer
    svelte-language-server
    tailwindcss-language-server
    taplo
    terraform-ls
    texlab
    tinymist
    typescript-language-server
    vscode-extensions.elixir-lsp.vscode-elixir-ls
    vscode-extensions.gleam.gleam
    vscode-extensions.mathiasfrohlich.kotlin
    vscode-extensions.redhat.ansible
    vscode-js-debug
    vscode-langservers-extracted
    vtsls
    vue-language-server
    yaml-language-server
    zls
  ];
}
