{ pkgs, ... }:

let
  facterReportPath = ./__facter_report_path__;
  facter = pkgs.locallib.facter facterReportPath;
in
{
  name = "__hostname__";
  smbiosUUIDHash = "__smbios_uuid_hash__";
  disk_device = "__disk_device__";

  hardware-configuration = { ... }:

  {
    imports = [ ];

    hardware = {
      facter = {
        reportPath = facterReportPath;
        detected.dhcp.enable = false;
      };

      logitech.wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  inherit (facter) ramGiB;

  monitors = {
    niri = import ./__host_directory__/niri_monitors.nix;
    noctalia = import ./__host_directory__/noctalia_monitors.nix;
  };

  gpu.cudaSupport = facter.hasNvidiaGpu;
}
