{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.nixtop.greetd.greeter == "noctalia") {
    programs.noctalia-greeter = {
      enable = true;
      settings = {
        cursor = {
          theme = "capitaine-cursors";
          size = 24;
          path = "${pkgs.capitaine-cursors}/share/icons";
        };
      };
    };
  };
}
