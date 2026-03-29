{ pkgs, ... }:

# Compilers, interpreters, build systems & language processors for text-like documents.
{
  home.packages = with pkgs; [
    cairosvg
    graphviz
    mermaid-cli
    netpbm
    pandoc
    pnglatex
    poppler-utils
    python3Packages.kaleido
    python3Packages.plotly
    python3Packages.pylatexenc
    texlive.combined.scheme-full
    texlivePackages.cm-unicode
    typst
  ];
}
