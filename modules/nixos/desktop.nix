{
  flake.modules.nixos.base = { pkgs, ... }: {
    services = {
      displayManager.gdm = {
        enable = true;
      };

      desktopManager.gnome = {
        enable = true;
        extraGSettingsOverridePackages = [ pkgs.mutter ];
        extraGSettingsOverrides = ''
          [org.gnome.mutter]
          experimental-features=['scale-monitor-framebuffer']
        '';
      };

      xserver = {
        enable = true;

        xkb = {
          layout = "qwerty_rnk";
          variant = "";
          extraLayouts = {
            qwerty_rnk = {
              description = "English (qwerty, rnk)";
              languages = [ "eng" ];
              symbolsFile = ./_keyboard/qwerty_rnk;
            };
            jcuken_rnk = {
              description = "Russian (jcuken, rnk)";
              languages = [ "rus" ];
              symbolsFile = ./_keyboard/jcuken_rnk;
            };
          };
        };
      };
    };

    programs = {
      niri.enable = true;
    };
  };
}
