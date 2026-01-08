# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "desktop/ibus/general" = {
      preload-engines = [ "xkb:us::eng" ];
      version = "1.5.33";
    };

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

    "org/gnome/desktop/app-folders" = {
      folder-children = [
        "System"
        "Utilities"
        "YaST"
        "Pardus"
      ];
    };

    "org/gnome/desktop/app-folders/folders/Pardus" = {
      categories = [ "X-Pardus-Apps" ];
      name = "X-Pardus-Apps.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/System" = {
      apps = [
        "org.gnome.baobab.desktop"
        "org.gnome.DiskUtility.desktop"
        "org.gnome.Logs.desktop"
        "org.gnome.SystemMonitor.desktop"
      ];
      name = "X-GNOME-Shell-System.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/Utilities" = {
      apps = [
        "org.gnome.Decibels.desktop"
        "org.gnome.Connections.desktop"
        "org.gnome.Papers.desktop"
        "org.gnome.font-viewer.desktop"
        "org.gnome.Loupe.desktop"
      ];
      name = "X-GNOME-Shell-Utilities.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/YaST" = {
      categories = [ "X-SuSE-YaST" ];
      name = "suse-yast.directory";
      translate = true;
    };

    "org/gnome/desktop/calendar" = {
      show-weekdate = true;
    };

    "org/gnome/desktop/input-sources" = {
      mru-sources = [
        (mkTuple [
          "xkb"
          "jcuken_rnk"
        ])
        (mkTuple [
          "xkb"
          "qwerty_rnk"
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

    "org/gnome/desktop/notifications/application/gnome-about-panel" = {
      application-id = "gnome-about-panel.desktop";
    };

    "org/gnome/desktop/notifications/application/gnome-printers-panel" = {
      application-id = "gnome-printers-panel.desktop";
    };

    "org/gnome/desktop/notifications/application/google-chrome" = {
      application-id = "google-chrome.desktop";
    };

    "org/gnome/desktop/notifications/application/kitty" = {
      application-id = "kitty.desktop";
    };

    "org/gnome/desktop/notifications/application/org-telegram-desktop" = {
      application-id = "org.telegram.desktop.desktop";
    };

    "org/gnome/desktop/notifications/application/throne" = {
      application-id = "throne.desktop";
    };

    "org/gnome/desktop/notifications" = {
      application-children = [
        "gnome-about-panel"
        "google-chrome"
        "org-telegram-desktop"
        "throne"
        "gnome-printers-panel"
      ];
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
      event-sounds = false;
      theme-name = "__custom";
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = [
        "<Control><Alt>x"
        "<Alt>F4"
      ];
      cycle-windows = [ ];
      cycle-windows-backward = [ ];
      minimize = [ "<Control><Alt>c" ];
      move-to-workspace-down = [ ];
      move-to-workspace-left = [ "<Control><Alt>q" ];
      move-to-workspace-right = [ "<Control><Alt>e" ];
      move-to-workspace-up = [ ];
      switch-applications = [ ];
      switch-applications-backward = [ ];
      switch-group = [ ];
      switch-group-backward = [ ];
      switch-input-source = [ "<Control>space" ];
      switch-input-source-backward = [ "<Shift><Control>space" ];
      switch-panels = [ ];
      switch-panels-backward = [ ];
      switch-to-workspace-left = [ "<Control><Alt>1" ];
      switch-to-workspace-right = [ "<Control><Alt>2" ];
      switch-windows = [ "<Alt>Tab" ];
      switch-windows-backward = [ "<Shift><Alt>Tab" ];
    };

    "org/gnome/gnome-system-monitor/disktreenew" = {
      col-6-visible = true;
      col-6-width = 0;
    };

    "org/gnome/gnome-system-monitor" = {
      maximized = false;
    };

    "org/gnome/gnome-system-monitor/proctree" = {
      col-26-visible = false;
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
      show-dependencies = false;
      show-whose-processes = "user";
      window-height = 840;
      window-width = 1186;
    };

    "org/gnome/mutter" = {
      attach-modal-dialogs = false;
      edge-tiling = false;
    };

    "org/gnome/mutter/keybindings" = {
      cancel-input-capture = [ ];
    };

    "org/gnome/mutter/wayland/keybindings" = {
      restore-shortcuts = [ ];
    };

    "org/gnome/mutter" = {
      workspaces-only-on-primary = false;
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-schedule-automatic = false;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      calculator = [ "<Alt>6" ];
      control-center = [ "<Alt>4" ];
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Alt>3";
      command = "sh -c \"QT_QPA_PLATFORM=xcb flameshot gui --raw --path ~/Downloads/ | wl-copy\"";
      name = "Flameshot";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      binding = "<Alt>1";
      command = "kitty";
      name = "Terminal";
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      home = [ "<Alt>5" ];
      rotate-video-lock-static = [ ];
      screensaver = [ "<Control><Alt>o" ];
      www = [ "<Alt>2" ];
    };

    "org/gnome/settings-daemon/plugins/power" = {
      ambient-enabled = false;
      idle-dim = false;
      sleep-inactive-ac-timeout = 259200;
      sleep-inactive-battery-timeout = 1800;
    };

    "org/gnome/shell" = {
      enabled-extensions = [ "pop-shell@system76.com" ];
    };

    "org/gnome/shell/extensions/pop-shell" = {
      activate-launcher = [ "" ];
      active-hint = false;
      active-hint-border-radius = mkUint32 0;
      column-size = 0;
      focus-down = [ "<Control><Alt>j" ];
      focus-left = [ "<Control><Alt>h" ];
      focus-right = [ "<Control><Alt>l" ];
      focus-up = [ "<Control><Alt>k" ];
      fullscreen-launcher = true;
      gap-inner = mkUint32 0;
      gap-outer = mkUint32 0;
      hint-color-rgba = "rgba(196, 147, 61)";
      log-level = 1;
      management-orientation = [ "" ];
      max-window-width = 1;
      mouse-cursor-focus-location = mkUint32 1;
      mouse-cursor-follows-active-window = true;
      pop-monitor-down = [ ];
      pop-monitor-left = [ ];
      pop-monitor-right = [ ];
      pop-monitor-up = [ ];
      pop-workspace-down = [ ];
      pop-workspace-up = [ ];
      row-size = 1;
      show-skip-taskbar = true;
      show-title = false;
      smart-gaps = true;
      snap-to-grid = false;
      stacking-with-mouse = true;
      tile-accept = [
        "<Control><Alt>f"
        "f"
      ];
      tile-by-default = true;
      tile-enter = [ "<Control><Alt>g" ];
      tile-move-down = [ ];
      tile-move-down-global = [ "<Control><Alt>s" ];
      tile-move-left = [ ];
      tile-move-left-global = [ "<Control><Alt>a" ];
      tile-move-right = [ ];
      tile-move-right-global = [ "<Control><Alt>d" ];
      tile-move-up = [ ];
      tile-move-up-global = [ "<Control><Alt>w" ];
      tile-orientation = [ "<Control><Alt>r" ];
      tile-reject = [ "Escape" ];
      tile-resize-down = [ "<Control><Alt>j" ];
      tile-resize-left = [ "<Control><Alt>h" ];
      tile-resize-right = [ "<Control><Alt>l" ];
      tile-resize-up = [ "<Control><Alt>k" ];
      tile-swap-down = [ "<Control><Alt>s" ];
      tile-swap-left = [ "<Control><Alt>a" ];
      tile-swap-right = [ "<Control><Alt>d" ];
      tile-swap-up = [ "<Control><Alt>w" ];
      toggle-floating = [ "<Control><Alt>f" ];
      toggle-stacking = [ ];
      toggle-stacking-global = [ "<Control><Alt>v" ];
      toggle-tiling = [ "<Super>y" ];
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
      focus-active-notification = [ ];
      screenshot-window = [ ];
      shift-overview-down = [ ];
      shift-overview-up = [ ];
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
