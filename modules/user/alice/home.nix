{
  config,
  pkgs,
  unstable-pkgs,
  ...
}:
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

    file."Pictures/Wallpapers".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/assets/wallpaper";

    # Flat package list, grouped by use.
    packages =
      (with pkgs; [
        # communication
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
        yt-dlp
        pokemmo-installer
        # launchers / extras
        fuzzel
        keepassxc
      ])
      ++ (with unstable; [
        tutanota-desktop
        antigravity-ide
        tauon
        ani-cli
      ]);
  };

  nixtop = {
    apps.chromium.enable = true;
    apps.emacs.enable = true;
    # EWM overlay + tools.
    ewm.enable = true;
  };

  # Shells
  nixtop.shell = "noctalia"; # or jes or quickshell or none
  nixtop.noctalia.compositor = "mango"; # Or sway

  gtk.gtk4.theme = null;
  programs = {
    yazi.shellWrapperName = "y";
    zsh.dotDir = "${config.xdg.configHome}/zsh";
 
    mpv = {
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
  };

  xdg.userDirs = {
    createDirectories = true;
    templates = "${config.home.homeDirectory}/Templates";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
    };
  };
}
