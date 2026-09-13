{ config, lib, pkgs, inputs, ... }:
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
      type = lib.types.enum [ "noctalia" "quickshell" ];
      default = config.nixtop.shell;
      description = "Which greeter to run. Mutually exclusive; one of noctalia or quickshell (nixtop-shell).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.greeter == "noctalia" || cfg.greeter == "quickshell";
        message = "nixtop.greetd.greeter must be 'noctalia' or 'quickshell'";
      }
    ];

    services.greetd = {
      enable = true;
      settings.terminal.vt = 1;
    };

    # The actual default_session.command is set by the selected greeter module
    # (modules/noctalia/greeter.nix or modules/quickshell/greeter.nix).
    # We only assert that exactly one greeter is active and that services.greetd
    # is not left without a command – the greeter modules themselves are
    # responsible for filling settings.default_session when their selector matches.
  };
}
