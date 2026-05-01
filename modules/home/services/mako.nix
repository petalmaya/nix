{ config, pkgs, ... }:

{
  services.mako = {
    enable = true;
    settings = {
      border-radius = 10;
      border-size = 2;
      border-color = "#a7c080";
      background-color = "#2b3339";
      text-color = "#d3c6aa";
      font = "Courier Prime 11";
      padding = "15";
      default-timeout = 5000;
    };
  };
}
