{ config, lib, pkgs, ... }:

{
  options.nixtop.plymouth.enable = lib.mkEnableOption "Plymouth boot splash screen with Blahaj theme";

  config = lib.mkIf config.nixtop.plymouth.enable {
    boot = {
      plymouth = {
        enable = true;
        theme = "blahaj";
        themePackages = [ pkgs.plymouth-blahaj-theme ];
      };

      # Suppress boot logs for a cleaner Plymouth transition
      consoleLogLevel = 0;
      initrd.verbose = false;

      kernelParams = [
        "quiet"
        "splash"
        "rd.udev.log_level=3"
        "rd.systemd.show_status=auto"
        "udev.log_level=3"
        "vt.global_cursor_default=0"
      ];
    };
  };
}
