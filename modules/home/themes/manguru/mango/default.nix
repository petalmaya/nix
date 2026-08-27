{ pkgs, lib, config, inputs, unstable-pkgs, ... }:

lib.mkIf config.nixtop.themes.manguru.enable {
  # small store-templated stub for the one line that actually needs a
  # nix store path (polkit's libexec binary isn't on PATH) - everything
  # she'll actually tweak lives in manguru.conf, out-of-store symlinked
  # below so layout/bind edits are edit-and-reload, no rebuild
  xdg.configFile."mango/config.conf".text = ''
    env=XDG_CURRENT_DESKTOP,mango
    exec-once=dbus-update-activation-environment --systemd --all
    exec-once=${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
    source=~/.config/mango/manguru.conf
  '';

  home.file.".config/mango/manguru.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.manguru.repoPath}/modules/home/themes/manguru/mango/manguru.conf";

  # matugen's output, seed a writable copy (store symlinks block its writes)
  home.activation.ensureMangoFlutterice = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/.config/mango
    $DRY_RUN_CMD [ -e "$HOME/.config/mango/flutterice.conf" ] || $DRY_RUN_CMD cp "${./flutterice.conf}" "$HOME/.config/mango/flutterice.conf"
  '';

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
    swaybg
    swaylock
    grim
    slurp
    unstable-pkgs.mango
  ];
}
