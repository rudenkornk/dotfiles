{ pkgs, ... }:

reportPath:

let
  inherit (pkgs) lib;
  nvidiaPciVendorId = 4318;
  report = lib.importJSON reportPath;
  resources = lib.concatMap (memory: memory.resources or [ ]) (report.hardware.memory or [ ]);
  physicalMemory = lib.findFirst (resource: (resource.type or null) == "phys_mem") null resources;
in
{
  ramGiB =
    if physicalMemory == null then
      throw "No physical memory resource found in facter report ${toString reportPath}"
    else
      physicalMemory.range / 1024 / 1024 / 1024;

  hasNvidiaGpu = lib.any (graphicsCard: (graphicsCard.vendor.value or null) == nvidiaPciVendorId) (
    report.hardware.graphics_card or [ ]
  );
}
