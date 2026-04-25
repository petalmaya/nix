{ config, pkgs, ... }:

{
  services.mako = {
    enable = true;
    settings = {
      border-radius = 15;
      border-size = 2;
      border-color = "#89b4fa";
      background-color = "#1e1e2e";
      text-color = "#cdd6f4";
      font = "Courier Prime 11";
      padding = "15";
      default-timeout = 5000;
    };
  };
}
