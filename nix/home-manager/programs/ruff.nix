_: {
  programs.ruff = {
    enable = true;
    settings = {
      # https://docs.astral.sh/ruff/configuration/#config-file-discovery
      line-length = 120;
      lint = {
        select = [ "ALL" ];

        ignore = [
          # warning: `one-blank-line-before-class` (D203) and
          #          `no-blank-line-before-class`  (D211) are incompatible.
          #          Ignoring `one-blank-line-before-class`.
          "D203"
          # warning: `multi-line-summary-first-line`  (D212) and
          #          `multi-line-summary-second-line` (D213) are incompatible.
          #          Ignoring `multi-line-summary-second-line`.
          "D213"
          # "Missing docstring"
          "D100"
          "D101"
          "D102"
          "D103"
          "D104"
          "D107"
          # "Logging statement uses f-string"
          # I personally don't find performance concerns reasonable enough.
          "G004"
          # "Prefer absolute imports over relative imports from parent modules"
          "TID252"

          # warning: The following rules may cause conflicts when used with the formatter: `COM812`, `ISC001`.
          # COM812: Checks for the absence of trailing commas.
          # ISC001: Checks for implicitly concatenated strings on a single line.
          "COM812"
          "ISC001"
        ];
      };

    };
  };
}
