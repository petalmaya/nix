# greetd session running kurukurubar's greeter.qml
{ lib, pkgs, config, inputs, ... }:
let
  cfg = config.programs.kurukurubar.greeter;
  system = pkgs.stdenv.hostPlatform.system;
  kurukurubar = import ../home/themes/kurukuru/package.nix {
    inherit pkgs;
    quickshellInput = inputs.quickshell;
  };
  greeterBin = "${kurukurubar}/bin/kurukurubar-greeter";

  # qml wallpaper never renders inside the real greetd session, so swaybg
  # draws the background instead. sits underneath harmlessly if that ever works
  greeterWallpaper = "${inputs.self}/assets/wallpaper/serial_experiments_lain_server_room.jpg";

  niriGreeterConf = pkgs.writeText "niri-greeter.kdl" ''
    spawn-at-startup "${lib.getExe pkgs.swaybg}" "-i" "${greeterWallpaper}" "-m" "fill"
    spawn-at-startup "${greeterBin}"
    input {
    }
  '';

  labwcGreeterConf = pkgs.runCommand "labwc-greeter-dir" {} ''
    mkdir -p $out
    cat > $out/autostart <<EOF
    ${greeterBin} &
    EOF
  '';
in
{
  options.programs.kurukurubar.greeter = {
    enable = lib.mkEnableOption "greetd session running kurukurubar's greeter.qml";
    compositor = lib.mkOption {
      type = lib.types.enum [ "niri" "labwc" ];
      default = "niri";
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
          else "${lib.getExe' pkgs.labwc "labwc"} -C ${labwcGreeterConf}";
      };
    };
  };
}
