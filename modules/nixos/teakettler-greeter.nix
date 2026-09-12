{ lib, pkgs, config, inputs, unstable-pkgs, ... }:
let
  cfg = config.programs.teakettler.greeter;
  teakettlerShell = import ../home/themes/teakettler/package.nix {
    inherit pkgs;
    quickshellInput = inputs.quickshell;
  };
  greeterBin = "${teakettlerShell}/bin/teakettler-greeter";
  greeterWallpaper = "${inputs.self}/assets/wallpaper/serial_experiments_lain_server_room.jpg";

  niriGreeterConf = pkgs.writeText "teakettler-niri-greeter.kdl" ''
    spawn-at-startup "${lib.getExe pkgs.swaybg}" "-i" "${greeterWallpaper}" "-m" "fill"
    spawn-at-startup "${greeterBin}"
    input {
    }
  '';

  labwcGreeterConf = pkgs.runCommand "teakettler-labwc-greeter-dir" {} ''
    mkdir -p $out
    cat > $out/autostart <<EOF
    ${greeterBin} &
    EOF
  '';

  mangoGreeterConf = pkgs.writeText "teakettler-mango-greeter.conf" ''
    exec-once=${lib.getExe pkgs.swaybg} -i ${greeterWallpaper} -m fill
    exec-once=${greeterBin}
  '';
in
{
  options.programs.teakettler.greeter = {
    enable = lib.mkEnableOption "greetd session running teakettler-shell's greeter.qml";
    compositor = lib.mkOption {
      type = lib.types.enum [ "niri" "labwc" "mango" ];
      default = "mango";
      description = "Which compositor runs the greeter session itself.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings.terminal.vt = 1;
      settings.default_session = {
        user = "greeter";
        command =
          if cfg.compositor == "niri"
          then "${lib.getExe pkgs.niri} --config ${niriGreeterConf}"
          else if cfg.compositor == "mango"
          then "${lib.getExe unstable-pkgs.mango} -c ${mangoGreeterConf}"
          else "${lib.getExe' pkgs.labwc "labwc"} -C ${labwcGreeterConf}";
      };
    };
  };
}
