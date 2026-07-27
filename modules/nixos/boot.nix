{
  flake.modules.nixos.base = { pkgs, ... }: {
    boot = {
      initrd.systemd.enable = true;

      loader = {
        limine = {
          enable = true;
          secureBoot.enable = true;
          style = {
            wallpapers = [ ];
          };
        };
        efi.canTouchEfiVariables = true;
      };

      kernelPackages = pkgs.linuxPackages_latest;
    };
  };
}
