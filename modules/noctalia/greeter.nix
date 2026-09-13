{ config, lib, pkgs, inputs, ... }:
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

    # Noctalia greeter handles its own background/compositor – just enable the module.
    # The upstream flake's NixOS module sets services.greetd appropriately.
    # No manual swaybg/Mango command needed here (per user feedback that the greeter owns its background).
  };
}
