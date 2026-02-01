_: {

  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    settings = {
      update_check = false; # Disable automatic update checks.
      storage = "auto"; # Possible values: auto, full, compact.
      invert = true; # Invert the UI - put the search bar at the top.

      ## Defaults to true.
      ## If enabled, upon hitting enter Atuin will immediately execute the command.
      ## Press tab to return to the shell and edit.
      enter_accept = false;

      ## Set this to true and Atuin will minimize motion in the UI - timers will not update live, etc.
      ## Alternatively, set env NO_MOTION=true
      prefers_reduced_motion = true;

      # Enable sync v2 by default
      # This ensures that sync v2 is enabled for new installs only
      # In a later release it will become the default across the board
      sync.records = true;

      theme.name = "marine";
    };
    flags = [
      "--disable-up-arrow" # Annoying behaviour, especially with invert=true.
    ];
  };
}
