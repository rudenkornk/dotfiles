_: {
  home = {
    shellAliases =
      let
        eza_common_args = "eza --classify --icons --all --group-directories-first --long --header --tree";
        eza_long_args = "--binary --group --smart-group --links --inode --modified --created --accessed --time-style relative --flags --blocksize";
      in
      {
        l = "eza --classify --icons --all --group-directories-first";
        lg = "${eza_common_args} --level 1 --git-ignore";
        lgs = "${eza_common_args} --level 1 --git-ignore --total-size --sort size";
        ll = "${eza_common_args} --level 1";
        lll = "${eza_common_args} --level 1 ${eza_long_args}";
        llls = "${eza_common_args} --level 1 ${eza_long_args} --total-size --sort size";
        lls = "${eza_common_args} --level 1 --total-size --sort size";
        lt = "${eza_common_args} --level 2";
        lt3 = "${eza_common_args} --level 3";
        lts = "${eza_common_args} --level 2 --total-size --sort size";
      };
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    icons = "always";
    extraOptions = [ "--classify" ];
  };
}
