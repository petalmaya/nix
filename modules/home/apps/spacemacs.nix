{ pkgs, lib, config, inputs, ... }:

{
  options.nixtop.apps.spacemacs.enable = lib.mkEnableOption "Spacemacs (nixmacs) configuration";

  config = lib.mkIf config.nixtop.apps.spacemacs.enable {
    home.packages = [
      inputs.nixmacs.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
