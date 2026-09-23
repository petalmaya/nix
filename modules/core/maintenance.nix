{
  config,
  lib,
  self,
  ...
}:
let
  cfg = config.nixtop.maintenance;
  # Null flake URI derives from self + hostname; override for a mutable checkout.
  defaultFlake = "${self}#${config.networking.hostName}";
in
{
  options.nixtop.maintenance = {
    autoUpgrade = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable nixos auto-upgrade every 4 days (system.autoUpgrade).";
      };
      dates = lib.mkOption {
        type = lib.types.str;
        default = "*-*-01/4 04:00:00";
        description = "Systemd calendar for autoUpgrade (see systemd.time(7)). Default is every 4 days at 04:00.";
      };
      flake = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Flake URI for autoUpgrade. null = auto-derive from inputs.self + hostname.";
      };
      allowReboot = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Allow reboot after kernel/initrd upgrade.";
      };
    };
    gc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable daily nix store GC.";
      };
      dates = lib.mkOption {
        type = lib.types.str;
        default = "daily";
        description = "Systemd calendar for GC (systemd.time).";
      };
      options = lib.mkOption {
        type = lib.types.str;
        default = "--delete-older-than 7d";
        description = "Extra flags for nix-collect-garbage.";
      };
    };
    optimise.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable daily nix store optimise (hardlink dedup).";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.autoUpgrade.enable {
      system.autoUpgrade = {
        enable = true;
        dates = cfg.autoUpgrade.dates;
        flake = lib.mkDefault (
          if cfg.autoUpgrade.flake != null then cfg.autoUpgrade.flake else defaultFlake
        );
        flags = lib.mkDefault [ ];
        allowReboot = cfg.autoUpgrade.allowReboot;
        persistent = lib.mkDefault true;
        randomizedDelaySec = lib.mkDefault "30min";
        operation = lib.mkDefault "switch";
      };
      # True 4-day interval needs the monotonic timer alongside the calendar.
      systemd.timers.nixos-upgrade.timerConfig.OnUnitActiveSec = lib.mkDefault "4d";
      systemd.timers.nixos-upgrade.timerConfig.OnBootSec = lib.mkDefault "15min";
    })

    (lib.mkIf cfg.gc.enable {
      nix = {
        gc = {
          automatic = true;
          dates = cfg.gc.dates;
          options = cfg.gc.options;
          persistent = lib.mkDefault true;
          randomizedDelaySec = lib.mkDefault "30min";
        };
        optimise = {
          automatic = cfg.optimise.enable;
          dates = lib.mkDefault [ "daily" ];
          persistent = lib.mkDefault true;
          randomizedDelaySec = lib.mkDefault "30min";
        };
        settings.auto-optimise-store = lib.mkDefault true;
      };
    })
  ];
}
