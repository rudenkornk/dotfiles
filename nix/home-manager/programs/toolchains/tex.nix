{ pkgs, ... }:

# Compilers, interpreters, build systems & language processors for text-like documents.
{
  home.packages = with pkgs; [
    graphviz
    mermaid-cli
    pandoc
    poppler-utils
    python3Packages.pylatexenc
    texlive.combined.scheme-full
    texlivePackages.cm-unicode
    typst
  ];
}
