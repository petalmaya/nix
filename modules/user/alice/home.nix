{ pkgs, unstable-pkgs, ... }:
let
  unstable = unstable-pkgs;
in
{
  imports = [
    ./flatnix.nix
    ../base.nix
  ];

  home = {
    username = "alice";
    homeDirectory = "/home/alice";

    packages = with pkgs; [
      links2
      transmission_4-gtk
      nicotine-plus
      cinny-desktop
      weechat
      krita
      gimp
      blockbench
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
      wine
      renpy
      obs-studio
      prismlauncher
      openttd
      steam-run
      rmpc
      cava
      ffmpeg
      ffmpegthumbnailer
      feh
      loupe
      chafa
      libsixel
      ripgrep
      btop
      tree
      bitwarden-cli
      unzip
      p7zip
      wget
      curl
      age
      sops
      stack
      yt-dlp
      pokemmo-installer
      fuzzel
      keepassxc
      unstable.tutanota-desktop
      unstable.antigravity-ide
      unstable.tauon
      unstable.ani-cli
    ];
  };

  nixtop = {
    apps.emacs.enable = true;
    ewm.enable = true;
    shell = "noctalia";
    noctalia.compositor = "mango";
  };

  programs.mpv = {
    enable = true;
    package = pkgs.mpv.override {
      scripts = with pkgs.mpvScripts; [
        mpris
        modernz
      ];
    };
    config = {
      osc = "no";
      border = "no";
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
    };
  };
}
