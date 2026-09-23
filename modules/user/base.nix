{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.nixtop.wallpapers.enable = lib.mkEnableOption "Wallpaper collection symlink";

  config = lib.mkMerge [
    {
      nixtop = {
        terminal = {
          zsh.enable = true;
          tmux.enable = true;
          foot.enable = true;
        };
        apps = {
          chromium.enable = true;
          fetch.enable = true;
          yazi.enable = true;
        };
        sway.enable = true;
      };

      home.packages = [ pkgs.git ];

      home.stateVersion = "26.05";
      programs.home-manager.enable = true;

      xdg.userDirs = {
        enable = true;
        setSessionVariables = true;
        createDirectories = true;
        templates = "${config.home.homeDirectory}/Templates";
      };
    }

    (lib.mkIf config.nixtop.wallpapers.enable {
      home.file."Pictures/Wallpapers".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/assets/wallpaper";
    })
  ];
}
