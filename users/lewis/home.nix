{ config, pkgs, ... }:

{
  home.username = "lewis";
  home.homeDirectory = "/home/lewis";

  nixtop = {
    themes.teakettler.enable = true;
    terminal.foot.enable = true;
    apps.launchers.enable = true;

    # A category can be enabled while individual packages are left out.
    apps.gaming = {
      enable = true;
      exclude = [
        "wine"
        "openttd"
      ];
    };

    apps.firefox-esr.enable = true;
    services.flatpak.enable = true;
  };

  # Git is a one-off for this small profile; it does not justify enabling the
  # full command-line tools group.
  home.packages = [ pkgs.git ];

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;

  xdg.userDirs = {
    enable = true;
    setSessionVariables = true;
  };
}
