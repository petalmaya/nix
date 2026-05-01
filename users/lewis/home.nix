{ config, pkgs, lib, inputs, unstable-pkgs, ... }:

{
  imports = [
    # WM
    "${inputs.self}/modules/home/wm/niri.nix"
    # Terminal
    "${inputs.self}/modules/home/terminal/foot.nix"
    # Apps
    "${inputs.self}/modules/home/apps/floorp.nix"
    # Services
    "${inputs.self}/modules/home/services/flatpak.nix"
    # Themes
    "${inputs.self}/modules/home/themes/noctalia.nix"
  ];

  services.flatpak.packages = [
    "app.twintaillauncher.ttl"
  ];

  home.username = "lewis";
  home.homeDirectory = lib.mkForce "/home/lewis";

  home.packages = with pkgs; [
    foot
    nemo
    btop
    ripgrep
    wget curl
    git
    # Wayland / UI extras
    libnotify
    grim slurp
    wl-clipboard
    capitaine-cursors
    fuzzel
  ];

  # Cursor theme setup
  home.pointerCursor = {
    name = "capitaine-cursors";
    package = pkgs.capitaine-cursors;
    size = 24;
    gtk.enable = true;
  };

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
