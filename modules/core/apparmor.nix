{ config, lib, ... }:
{
  options.nixtop.security.apparmor.enable = lib.mkEnableOption "AppArmor Mandatory Access Control";

  config = lib.mkIf config.nixtop.security.apparmor.enable {
    security.apparmor = {
      enable = true;
      # kill unconfined confinables – let admin decide, default false (safe)
      killUnconfinedConfinables = lib.mkDefault false;
      # enable cache can fill /var/cache/apparmor with store-path variants;
      # upstream default is false, keep false unless needed
      enableCache = lib.mkDefault false;
    };

    # AppArmor needs kernel support – ensure lockdown not breaking
    # and that dbus mediation is enabled when kernel supports it
    services.dbus.apparmor = lib.mkDefault "enabled";
  };
}
