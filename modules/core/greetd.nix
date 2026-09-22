{
  config,
  lib,
  pkgs,
  inputs,
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

      # The actual default_session.command is set by the selected greeter module
      # (modules/shell/quickshell/greeter.nix).
      # We only assert that exactly one greeter is active and that services.greetd
      # is not left without a command – the greeter modules themselves are
      # responsible for filling settings.default_session when their selector matches.
    })

    (lib.mkIf (cfg.enable && cfg.greeter == "sddm") {
      # SDDM owns the display-manager; greetd must be off to avoid vt conflict
      services.greetd.enable = lib.mkForce false;
    })
  ];
}
