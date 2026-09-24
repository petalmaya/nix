{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  # Placeholder session until the nixtop-shell greeter lands.
  config = lib.mkIf (config.nixtop.greetd.greeter == "quickshell") {
    services.greetd.settings.default_session = lib.mkForce {
      user = "greeter";
      command = "${lib.getExe pkgs.swaybg} -i ${inputs.self}/assets/greeter/misty_forest_stairs.png -m fill & ${lib.getExe pkgs.hello}; wait";
    };
  };
}
