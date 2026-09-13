{ config, pkgs, lib, unstable-pkgs, inputs, ... }:
{
  imports = [ ./nixpak.nix ];

  home.username = "alice";
  home.homeDirectory = "/home/alice";

  nixtop = {
    terminal.zsh.enable = true;
    terminal.tmux.enable = true;
    terminal.foot.enable = true;

    apps.fetch.enable = true;
    apps.yazi.enable = true;
    apps.firefox-esr.enable = true;
    # floorp optional – disabled by default, enable if wanted
    # apps.floorp.enable = true;
    apps.emacs.enable = true;
  };

  # wallpaper directory shared into the home (D24) – alice and rose only
  home.file."Pictures/Wallpapers".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/assets/wallpaper";

  # Inline packages from the old group modules (communication/creative/desktop/gaming/media/tools/launchers)
  # – brought over flat, not as extra .nixs, per user request.
  home.packages = lib.filter (p: p != null) (
    (with pkgs; [
      # communication (old nixtop.apps.communication)
      links2
      transmission_4-gtk
      nicotine-plus
      cinny-desktop
      weechat
      # creative
      krita
      gimp
      blockbench
      # desktop
      mousepad
      nautilus
      mpvpaper
      libnotify
      brightnessctl
      wl-clipboard
      playerctl
      adw-gtk3
      capitaine-cursors
      polkit_gnome
      # gaming
      wine
      renpy
      obs-studio
      prismlauncher
      openttd
      openrct2
      steam-run
      # media
      rmpc
      cava
      ffmpeg
      ffmpegthumbnailer
      feh
      loupe
      # tools
      chafa
      libsixel
      ripgrep
      btop
      tree
      bitwarden-cli
      git
      unzip
      p7zip
      wget
      curl
      age
      sops
      stack
      # launchers / extras
      fuzzel
      keepassxc
    ])
    ++ [
      (if unstable-pkgs ? tutanota-desktop then unstable-pkgs.tutanota-desktop else null)
      (if unstable-pkgs ? antigravity-ide then unstable-pkgs.antigravity-ide else null)
      (if unstable-pkgs ? tauon then unstable-pkgs.tauon else null)
      (if unstable-pkgs ? ani-cli then unstable-pkgs.ani-cli else null)
      (if unstable-pkgs ? yt-dlp then unstable-pkgs.yt-dlp else pkgs.yt-dlp or null)
      (if unstable-pkgs ? pokemmo-installer then unstable-pkgs.pokemmo-installer else (if pkgs ? pokemmo-installer then pkgs.pokemmo-installer else null))
    ]
  );

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
