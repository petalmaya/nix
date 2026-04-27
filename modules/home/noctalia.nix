{ config, pkgs, inputs, ... }:

{
  # Imports the noctalia-shell home-manager module if valid
  imports = if inputs.noctalia-shell ? homeModules
            then builtins.attrValues inputs.noctalia-shell.homeModules
            else if inputs.noctalia-shell ? homeManagerModules
            then builtins.attrValues inputs.noctalia-shell.homeManagerModules
            else [];

  programs.noctalia-shell = {
    enable = true;
    plugins = [
      "screentoolkit"
      "clipper"
      "assistant-panel"
      "mpd-mpris"
    ];
  };
}
