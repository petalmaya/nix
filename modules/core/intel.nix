{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixtop.intel;
in
{
  options.nixtop.intel.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Intel i915 + media/VAAPI/compute packages. Set to false on non-Intel hosts (e.g. garden if AMD).";
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.kernelModules = [ "i915" ];

    hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
      intel-compute-runtime
    ];
  };
}
