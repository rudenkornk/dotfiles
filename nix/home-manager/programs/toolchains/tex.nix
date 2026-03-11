{ pkgs, ... }:

# Compilers, interpreters, build systems & language processors for text-like documents.
{
  home.packages = with pkgs; [
    graphviz
    mermaid-cli
    poppler-utils
    python3Packages.pylatexenc
    texlive.combined.scheme-full
    typst
  ];
}
