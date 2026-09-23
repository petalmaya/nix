{
  config,
  lib,
  ...
}:
let
  cfg = config.nixtop.greetd;
in
{
  options.nixtop.greetd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.nixtop.desktop.enable;
      description = "Enable greetd login manager. Defaults to desktop.enable.";
    };
    greeter = lib.mkOption {
      type = lib.types.enum [
        "quickshell"
        "sddm"
      ];
      default = config.nixtop.shell;
      description = "Which greeter to run. Mutually exclusive; one of quickshell (nixtop-shell) or sddm (SilentSDDM).";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.greeter != "sddm") {
      assertions = [
        {
          assertion = cfg.greeter == "quickshell";
          message = "nixtop.greetd.greeter must be 'quickshell' or 'sddm' (sddm is handled by SilentSDDM)";
        }
      ];

      services.greetd = {
        enable = true;
        settings.terminal.vt = 1;
      };
    })

    (lib.mkIf (cfg.enable && cfg.greeter == "sddm") {
      services.greetd.enable = lib.mkForce false;
    })
  ];
}
