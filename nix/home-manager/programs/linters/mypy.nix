_: {
  programs.mypy = {
    enable = true;
    settings = {
      mypy = {
        strict = true;
      };
    };
  };
}
