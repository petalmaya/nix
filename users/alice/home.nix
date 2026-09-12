{ config, pkgs, ... }:

{
  home.username = "alice";
  home.homeDirectory = "/home/alice";

  nixtop = {
    # Choose one theme. The theme supplies the compositor and shell files.
    themes.teakettler.enable = true;

    terminal.foot.enable = true;
    terminal.zsh.enable = true;
    terminal.zellij.enable = true;

    # Reusable application groups.
    apps.communication.enable = true;
    apps.creative.enable = true;
    apps.desktop.enable = true;
    apps.fetch.enable = true;
    apps.gaming.enable = true;
    apps.media.enable = true;
    apps.tools.enable = true;

    # Individual apps with their own configuration.
    apps.firefox-esr.enable = true;
    apps.spicetify.enable = true;
    apps.yazi.enable = true;
    apps.emacs.enable = true;

    services.mako.enable = true;
    services.flatpak.enable = true;
    services.mpd.enable = true;
  };

  # Keep a package here when it is a one-off rather than a useful category.
  home.packages = [
    pkgs.keepassxc
  ];

  gtk.gtk4.theme = null;
  programs.yazi.shellWrapperName = "y";
  programs.zsh.dotDir = "${config.xdg.configHome}/zsh";

  programs.mpv = {
    enable = true;
    package = pkgs.mpv.override {
      scripts = with pkgs.mpvScripts; [ mpris modernz ];
    };
    config = {
      osc = "no";
      border = "no";
    };
  };

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    templates = "${config.home.homeDirectory}/Templates";
    setSessionVariables = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
    };
  };
}
