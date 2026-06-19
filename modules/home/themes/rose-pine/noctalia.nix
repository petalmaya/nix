{ config, pkgs, inputs, ... }:

{
  # Imports the noctalia-shell home-manager module if valid
  imports = if inputs.noctalia-shell ? homeModules
            then builtins.attrValues inputs.noctalia-shell.homeModules
            else if inputs.noctalia-shell ? homeManagerModules
            then builtins.attrValues inputs.noctalia-shell.homeManagerModules
            else [];

  programs.noctalia = {
    enable = true;
    # Note: Legacy v4 plugins are incompatible with v5.
  };
}
