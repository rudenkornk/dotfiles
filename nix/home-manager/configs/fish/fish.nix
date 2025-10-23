{ pkgs, ... }:

{
  enable = true;

  shellAliases = let
    eza_common_args = "eza --classify --icons --all --long --header --tree";
    eza_long_args =
      "--binary --group --smart-group --links --inode --modified --created --accessed --time-style relative --flags --blocksize";
  in {
    b = "bat";
    d = "docker";
    g = "git";
    l = "eza --classify --icons --all";
    lg = "${eza_common_args} --level 2 --git-ignore";
    lg3 = "${eza_common_args} --level 3 --git-ignore";
    lgs = "${eza_common_args} --level 2 --git-ignore --total-size --sort size";
    ll = "${eza_common_args} --level 1";
    lll = "${eza_common_args} --level 1 ${eza_long_args}";
    llls =
      "${eza_common_args} --level 1 ${eza_long_args} --total-size --sort size";
    lls = "${eza_common_args} --level 1 --total-size --sort size";
    lt = "${eza_common_args} --level 2";
    lt3 = "${eza_common_args} --level 3";
    lts = "${eza_common_args} --level 2 --total-size --sort size";
  };
  functions = {
    c = {
      wraps = "z";
      body = builtins.readFile ./functions/c.fish;
    };
    fish_greeting = { body = ""; };
    fish_remove_path = {
      body = builtins.readFile ./functions/fish_remove_path.fish;
      description =
        "Shows user added PATH entries and removes the selected one";
    };
    _fzf_search_files = {
      description =
        "Search the current directory with ripgrep. Replace the current token with the selected file paths.";
      body = builtins.readFile ./functions/_fzf_search_files.fish;
    };
  };
  plugins = [
    {
      name = "autopair";
      src = pkgs.fetchFromGitHub {
        owner = "jorgebucaran";
        repo = "autopair.fish";
        rev = "4d1752ff5b39819ab58d7337c69220342e9de0e2";
        sha256 = "sha256-qt3t1iKRRNuiLWiVoiAYOu+9E7jsyECyIqZJ/oRIT1A=";
      };
    }
    {
      name = "puffer";
      src = pkgs.fetchFromGitHub {
        owner = "nickeb96";
        repo = "puffer-fish";
        rev = "fd0a9c95da59512beffddb3df95e64221f894631";
        sha256 = "sha256-aij48yQHeAKCoAD43rGhqW8X/qmEGGkg8B4jSeqjVU0";
      };
    }
    {
      name = "fzf";
      src = pkgs.fetchFromGitHub {
        owner = "patrickf1";
        repo = "fzf.fish";
        rev = "175222b9bd79e589da55972b2cd6686b94c6325b";
        sha256 = "sha256-aou6UYE6gjLK8J0yXNTFA9yc9Lv8F7ytzBDSmP2K6Sg=";
      };
    }

  ];
}
