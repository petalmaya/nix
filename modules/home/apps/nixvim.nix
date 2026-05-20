{ pkgs, lib, config, inputs, ... }:

{
  options.nixtop.apps.nixvim.enable = lib.mkEnableOption "Nixvim (avim) configuration";

  config = lib.mkIf config.nixtop.apps.nixvim.enable {
    home.packages = [
      inputs.avim.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}