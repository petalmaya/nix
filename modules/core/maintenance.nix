{ config, lib, inputs, self ? inputs.self or null, ... }:
let
  cfg = config.nixtop.maintenance;
  # derive flake URI from the current flake if user didn't override
  # `self` is the flake itself; string interpolation yields its outPath (store copy)
  # For a mutable checkout (e.g. /home/alice/nix) override via nixtop.maintenance.autoUpgrade.flake
  defaultFlake = if self != null then "${self}#${config.networking.hostName}" else null;
in
{
  options.nixtop.maintenance = {
    autoUpgrade.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable daily nixos auto-upgrade (system.autoUpgrade).";
    };
    autoUpgrade.dates = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "Systemd calendar for autoUpgrade (see systemd.time(7)).";
    };
    autoUpgrade.flake = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Flake URI for autoUpgrade. null = auto-derive from inputs.self + hostname.";
    };
    autoUpgrade.allowReboot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow reboot after kernel/initrd upgrade.";
    };
    gc.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable daily nix store GC.";
    };
    gc.dates = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "Systemd calendar for GC (systemd.time).";
    };
    gc.options = lib.mkOption {
      type = lib.types.str;
      default = "--delete-older-than 7d";
      description = "Extra flags for nix-collect-garbage.";
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
        # Flake URI: if user sets cfg.autoUpgrade.flake use it, else derive from self + hostname
        # override with e.g. "/home/alice/nix#wonderland" if your checkout lives elsewhere
        flake = lib.mkDefault (
          if cfg.autoUpgrade.flake != null then cfg.autoUpgrade.flake
          else defaultFlake
        );
        # When using flakes, --update-input nixpkgs is often wanted; keep flags minimal by default
        flags = lib.mkDefault [ ];
        allowReboot = cfg.autoUpgrade.allowReboot;
        # daily upgrades should persist across power-offs
        persistent = lib.mkDefault true;
        randomizedDelaySec = lib.mkDefault "30min";
        operation = lib.mkDefault "switch";
      };
    })

    (lib.mkIf cfg.gc.enable {
      nix.gc = {
        automatic = true;
        dates = cfg.gc.dates;
        options = cfg.gc.options;
        persistent = lib.mkDefault true;
        randomizedDelaySec = lib.mkDefault "30min";
      };
      nix.optimise = {
        automatic = cfg.optimise.enable;
        dates = lib.mkDefault [ "daily" ];
        persistent = lib.mkDefault true;
        randomizedDelaySec = lib.mkDefault "30min";
      };
      # also enable auto-optimise on every build (cheap)
      nix.settings.auto-optimise-store = lib.mkDefault true;
    })
  ];
}
