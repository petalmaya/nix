{ pkgs, inputs, ... }:

{
  home.packages = [
    inputs.avim.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}