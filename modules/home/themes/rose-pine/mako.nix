{ config, pkgs, ... }:

{
  services.mako = {
    enable = true;
    settings = {
      border-radius = 10;
      border-size = 2;
      border-color = "#ebbcba";
      background-color = "#191724";
      text-color = "#e0def4";
      font = "Courier Prime 11";
      padding = "15";
      default-timeout = 5000;
    };
  };
}
