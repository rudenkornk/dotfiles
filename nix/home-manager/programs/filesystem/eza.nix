_: {
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    icons = "always";
    extraOptions = [ "--classify" ];
  };
}
