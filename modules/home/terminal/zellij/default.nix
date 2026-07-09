{ pkgs, lib, config, ... }:

{
  options.nixtop.terminal.zellij.enable = lib.mkEnableOption "Zellij terminal multiplexer";

  config = lib.mkIf config.nixtop.terminal.zellij.enable {
    programs.zellij = {
      enable = true;
      settings = {
        theme = "gruvbox-dark";
        default_shell = "zsh";
        pane_frames = true;
        ui = {
          pane_frames = {
            hide_session_name = false;
            rounded_corners = true;
          };
        };
      };
    };
  };
}
