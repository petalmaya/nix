{ config, pkgs, lib, inputs, unstable-pkgs, ... }:

{
  imports = [
    "${inputs.self}/modules/home/sway-catppuccin.nix"
    "${inputs.self}/modules/home/foot-catppuccin.nix"
    "${inputs.self}/modules/home/fetch.nix"
    "${inputs.self}/modules/home/nixvim.nix"
    "${inputs.self}/modules/home/spacemacs.nix"
    "${inputs.self}/modules/home/floorp.nix"
    "${inputs.self}/modules/home/rofi-catppuccin.nix"
    "${inputs.self}/modules/home/mako-catppuccin.nix"
    "${inputs.self}/modules/home/flatpak.nix"
  ];

  home.username = "stacy";
  home.homeDirectory = "/home/stacy";

  home.packages = with pkgs; [
    foot
    yazi
    ripgrep
    btop
    git
    # Wayland / UI extras
    libnotify grim slurp wl-clipboard
    capitaine-cursors
  ];

  # GTK & Cursor theme setup
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-blue-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        size = "standard";
        variant = "mocha";
      };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "blue";
      };
    };
  };

  home.pointerCursor = {
    name = "catppuccin-mocha-blue-cursors";
    package = pkgs.catppuccin-cursors.mochaBlue;
    size = 24;
    gtk.enable = true;
  };

  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
        '';
      }
    ];
  };

  programs.yazi = {
    enable = true;
    theme = {
      flavor = {
        use = "catppuccin-mocha";
      };
    };
  };

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
