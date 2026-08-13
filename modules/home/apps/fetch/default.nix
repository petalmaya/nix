{ pkgs, lib, config, ... }:
{
  options.nixtop.apps.fetch.enable = lib.mkEnableOption "Fastfetch/Hyfetch tool";

  config = lib.mkIf config.nixtop.apps.fetch.enable {
    programs.fastfetch = {
      enable = true;
    };
    
    # Skip on a kurukuru host - same read-only-symlink-vs-matugen-writeback
    # conflict as starship.toml (modules/home/terminal/zsh/default.nix),
    # matugen owns this path there instead
    # (programs.matugen.templates.fastfetch).
    xdg.configFile."fastfetch/config.jsonc" = lib.mkIf (!(config.nixtop.themes.kurukuru.enable or false)) {
      source = ./config.jsonc;
    };
  };
}
