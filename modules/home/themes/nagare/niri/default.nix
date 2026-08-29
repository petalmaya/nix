{ pkgs, lib, config, inputs, ... }:

lib.mkIf config.nixtop.themes.nagare.enable {
  # the stub below only keeps what genuinely needs nix-computed store paths;
  # everything else lives in config.kdl, `include`d here and out-of-store
  # symlinked so editing it is edit-and-reload, never edit-rebuild-see
  programs.niri = {
    enable = true;
    package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
    config = ''
      spawn-at-startup "dbus-update-activation-environment" "--systemd" "--all"
      spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"

      xwayland-satellite {
          path "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
      }

      include optional=true "nagare.kdl"
    '';
  };

  home.file.".config/niri/animations.kdl".source =
    config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.nagare.repoPath}/modules/home/themes/nagare/niri/animations.kdl";

  home.file.".config/niri/nagare.kdl".source =
    config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.nagare.repoPath}/modules/home/themes/nagare/niri/config.kdl";

  # matugen's output, seed a writable copy (store symlinks block its writes)
  home.activation.ensureNiriFlutterice = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/.config/niri
    $DRY_RUN_CMD [ -e "$HOME/.config/niri/flutterice.kdl" ] || $DRY_RUN_CMD cp "${./flutterice.kdl}" "$HOME/.config/niri/flutterice.kdl"
  '';

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config.niri = {
      default = [
        "gtk"
        "gnome"
      ];
      "org.freedesktop.impl.portal.Access" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "xdg-desktop-portal-gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "xdg-desktop-portal-gnome" ];
    };
    extraPortals = [
      pkgs.gnome-keyring
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
  };

  home.packages = with pkgs; [
    swaybg
    swaylock
    grim
    slurp
    xwayland-satellite
  ];
}
