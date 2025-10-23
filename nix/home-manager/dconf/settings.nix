# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/Snapshot" = {
      play-shutter-sound = false;
    };

    "org/gnome/Totem" = {
      subtitle-encoding = "UTF-8";
    };

    "org/gnome/calculator" = {
      button-mode = "advanced";
      show-thousands = true;
      source-currency = "DZD";
      source-units = "radian";
      target-currency = "DZD";
      target-units = "degree";
    };

    "org/gnome/desktop/calendar" = {
      show-weekdate = true;
    };

    "org/gnome/desktop/input-sources" = {
      mru-sources = [
        (mkTuple [
          "xkb"
          "en_rnk"
        ])
        (mkTuple [
          "xkb"
          "ru_rnk"
        ])
      ];
      per-window = true;
      sources = [
        (mkTuple [
          "xkb"
          "qwerty_rnk"
        ])
        (mkTuple [
          "xkb"
          "jcuken_rnk"
        ])
      ];
      xkb-options = [ "lv3:ralt_switch" ];
    };

    "org/gnome/desktop/interface" = {
      clock-show-weekday = true;
    };

    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = true;
    };

    "org/gnome/desktop/peripherals/mouse" = {
      speed = 0.407407;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      speed = 0.210526;
    };

    "org/gnome/desktop/privacy" = {
      report-technical-problems = true;
    };

    "org/gnome/desktop/search-providers" = {
      disabled = [ "org.mozilla.firefox.desktop" ];
      sort-order = [
        "org.gnome.Contacts.desktop"
        "org.gnome.Documents.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };

    "org/gnome/desktop/session" = {
      idle-delay = mkUint32 900;
    };

    "org/gnome/desktop/sound" = {
      theme-name = "__custom";
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = [
        "<Control><Alt>x"
        "<Alt>F4"
      ];
      cycle-windows = [ "<Alt>Tab" ];
      cycle-windows-backward = [ "<Shift><Alt>Tab" ];
      maximize = [ "<Control><Alt>f" ];
      minimize = [ "<Control><Alt>c" ];
      move-to-monitor-down = [ "<Control><Alt>s" ];
      move-to-monitor-left = [ "<Control><Alt>a" ];
      move-to-monitor-right = [ "<Control><Alt>d" ];
      move-to-monitor-up = [ "<Control><Alt>w" ];
      move-to-workspace-left = [ "<Shift><Alt>q" ];
      move-to-workspace-right = [ "<Shift><Alt>e" ];
      switch-applications = [ ];
      switch-applications-backward = [ ];
      switch-input-source = [ "<Control>space" ];
      switch-input-source-backward = [ "<Shift><Control>space" ];
      switch-to-workspace-1 = [ "<Shift><Alt>s" ];
      switch-to-workspace-last = [ "<Shift><Alt>w" ];
      switch-to-workspace-left = [ "<Shift><Alt>a" ];
      switch-to-workspace-right = [ "<Shift><Alt>d" ];
      unmaximize = [ "<Control><Alt>r" ];
    };

    "org/gnome/gnome-system-monitor/disktreenew" = {
      col-6-visible = true;
      col-6-width = 0;
    };

    "org/gnome/gnome-system-monitor/proctree" = {
      col-26-width = 0;
      columns-order = [
        0
        1
        2
        3
        4
        6
        7
        8
        9
        10
        11
        12
        13
        14
        15
        16
        17
        18
        19
        20
        21
        22
        23
        24
        25
        26
      ];
    };

    "org/gnome/gnome-system-monitor" = {
      window-height = 840;
      window-width = 1186;
    };

    "org/gnome/mutter/keybindings" = {
      toggle-tiled-left = [ "<Control><Alt>q" ];
      toggle-tiled-right = [ "<Control><Alt>e" ];
    };

    "org/gnome/mutter" = {
      workspaces-only-on-primary = false;
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-schedule-automatic = false;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      calculator = [ "<Alt>6" ];
      control-center = [ "<Alt>5" ];
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "";
      command = "bash -c 'flameshot gui &> /tmp/flameshot_log_$USER'";
      name = "Flameshot";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Alt>3";
      command = "bash -c 'flameshot gui &> /tmp/flameshot_log_$USER'";
      name = "Flameshot";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      binding = "<Alt>1";
      command = "kitty";
      name = "Terminal";
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      home = [ "<Alt>4" ];
      screensaver = [ "<Control><Alt>l" ];
      www = [ "<Alt>2" ];
    };

    "org/gnome/settings-daemon/plugins/power" = {
      ambient-enabled = false;
      idle-dim = false;
      sleep-inactive-ac-timeout = 259200;
      sleep-inactive-battery-timeout = 1800;
    };

    "org/gnome/shell" = {
      favorite-apps = [
        "google-chrome.desktop"
        "kitty.desktop"
        "org.telegram.desktop._7399481fa1d082f7017ffa71affc89b7.desktop"
        "org.gnome.Settings.desktop"
        "org.gnome.Nautilus.desktop"
        "org.gnome.Software.desktop"
        "org.gnome.SystemMonitor.desktop"
        "hiddify.desktop"
      ];
    };

    "org/gnome/shell/keybindings" = {
      screenshot-window = [ ];
      toggle-application-view = [ "<Alt>Escape" ];
      toggle-message-tray = [ "<Control><Alt>n" ];
    };

    "org/gnome/shell" = {
      remember-mount-password = true;
    };

    "org/gnome/system/locale" = {
      region = "en_GB.UTF-8";
    };

    "org/gtk/gtk4/Settings/FileChooser" = {
      sort-directories-first = false;
      view-type = "grid";
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      sort-column = "name";
      sort-directories-first = false;
      sort-order = "ascending";
      type-format = "category";
      view-type = "grid";
    };

    "org/gtk/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      show-size-column = true;
      show-type-column = true;
      sort-column = "name";
      sort-directories-first = false;
      sort-order = "ascending";
      type-format = "category";
    };

    "system/locale" = {
      region = "en_GB.UTF-8";
    };

  };
}
