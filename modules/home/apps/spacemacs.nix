{ pkgs, inputs, ... }:

{
  home.packages = [
    inputs.nixmacs.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
