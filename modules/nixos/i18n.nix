{
  flake.modules.nixos.base = {
    time.timeZone = "Europe/Moscow";

    i18n = {
      defaultLocale = "en_GB.UTF-8";
      extraLocales = "all";
      extraLocaleSettings = {
        LC_ADDRESS = "en_GB.UTF-8";
        LC_IDENTIFICATION = "en_GB.UTF-8";
        LC_MEASUREMENT = "en_GB.UTF-8"; # Metric system.
        LC_MONETARY = "en_GB.UTF-8";
        LC_NAME = "en_GB.UTF-8";
        LC_NUMERIC = "en_GB.UTF-8";
        LC_PAPER = "en_GB.UTF-8"; # A4 paper size.
        LC_TELEPHONE = "en_GB.UTF-8";
        LC_TIME = "en_GB.UTF-8"; # 24-hour, DD/MM/YYYY format.
      };
    };
  };
}
