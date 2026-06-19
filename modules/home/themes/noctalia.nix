{ config, pkgs, lib, inputs, ... }:

{
  imports = if inputs.noctalia-shell ? homeModules
            then builtins.attrValues inputs.noctalia-shell.homeModules
            else if inputs.noctalia-shell ? homeManagerModules
            then builtins.attrValues inputs.noctalia-shell.homeManagerModules
            else [];

  options.nixtop.themes.noctalia.enable = lib.mkEnableOption "Noctalia Theme";

  config = lib.mkIf config.nixtop.themes.noctalia.enable {
    programs.noctalia = {
      enable = true;
      # Note: Legacy v4 plugins are incompatible with v5.
    };
  };
}
