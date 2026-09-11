{ pkgs, lib, config, inputs, unstable-pkgs, ... }:

lib.mkIf config.nixtop.themes.teakettler.enable {
  # config.conf is the live entry point too: out-of-store symlinked like
  # the split *.conf files below, so every line here is edit-and-reload.
  #
  # polkit's libexec binary isn't on PATH, so that one line needs a nix
  # store path. It's generated into its own file and sourced from
  # config.conf, which keeps the editable file store-path-free.
  xdg.configFile."mango/polkit.conf".text = ''
    exec-once=${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
  '';

  home.file = {
    ".config/mango/config.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.teakettler.repoPath}/modules/home/themes/teakettler/mango/config.conf";
    ".config/mango/settings.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.teakettler.repoPath}/modules/home/themes/teakettler/mango/settings.conf";
    ".config/mango/autostart.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.teakettler.repoPath}/modules/home/themes/teakettler/mango/autostart.conf";
    ".config/mango/keybinds.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.teakettler.repoPath}/modules/home/themes/teakettler/mango/keybinds.conf";
    ".config/mango/layout.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.teakettler.repoPath}/modules/home/themes/teakettler/mango/layout.conf";
    ".config/mango/appearance.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.teakettler.repoPath}/modules/home/themes/teakettler/mango/appearance.conf";
    ".config/mango/rules.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.teakettler.repoPath}/modules/home/themes/teakettler/mango/rules.conf";
    ".config/mango/animations.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.teakettler.repoPath}/modules/home/themes/teakettler/mango/animations.conf";
    # static pinaceae palette (NOT matugen output - matugen still writes
    # ~/.config/mango/pinaceae.conf on every run, teakettler just
    # doesn't source it)
    ".config/mango/pinaceae.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.teakettler.repoPath}/modules/home/themes/teakettler/mango/pinaceae.conf";
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config.mango = {
      default = [ "gtk" "gnome" ];
      "org.freedesktop.impl.portal.Access" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
    };
    extraPortals = [
      pkgs.gnome-keyring
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];
  };

  home.packages = with pkgs; [
    swaybg # desktop wallpapers (quickshell/scripts/wallpaper.sh drives it)
    jq # wallpaper.sh reads ~/.config/teakettler/config.json with it
    swaylock
    grim
    slurp
    unstable-pkgs.mango
  ];
}
