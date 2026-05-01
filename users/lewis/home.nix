{ config, pkgs, lib, inputs, unstable-pkgs, ... }:

{
  imports = [
    "${inputs.self}/modules/home/foot.nix"
    "${inputs.self}/modules/home/floorp.nix"
    "${inputs.self}/modules/home/niri.nix"
    "${inputs.self}/modules/home/noctalia.nix"
    "${inputs.self}/modules/home/flatpak.nix"
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
