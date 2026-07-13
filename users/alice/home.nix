{ config, pkgs, lib, inputs, unstable-pkgs, ... }:

{
  home.username = "alice";
  home.homeDirectory = "/home/alice";

  nixtop = {
    themes.noctaniri.enable = true;
    terminal.foot.enable = true;
    terminal.zsh.enable = true;
    # terminal.tmux.enable = true;
    terminal.zellij.enable = true;
    apps.fetch.enable = true;
    apps.spacemacs.enable = true;
    # apps.floorp.enable = true;
    # apps.zen.enable = true;
    # apps.librewolf.enable = true;
    apps.firefox-esr.enable = true;
    apps.spicetify.enable = true;
    apps.yazi.enable = true;
    apps.gaming.enable = true;
    services.mako.enable = true;
    services.flatpak.enable = true;
    services.mpd.enable = true;
  };

  home.packages = with pkgs; [
    # Misc
    pkgs.palemoon-bin links2 # Browsers
    unstable-pkgs.tutanota-desktop keepassxc steam # Mail & Gaming
    mousepad nautilus # Acker
    mpvpaper
    foot # Terminal Emulator's
    fastfetch hyfetch # Fetch
    chafa libsixel ripgrep btop # Terminal things
    transmission_4-gtk nicotine-plus # Legal things
    stack # Idk i don rembere
    krita gimp # Photo editing
    cinny-desktop weechat # Non Discord chat
    blockbench tree

    # Media
    rmpc
    unstable-pkgs.tauon
    cava
    ffmpeg
    ffmpegthumbnailer
    feh
    loupe

    # Utilities
    swaybg          # Wallpaper
    libnotify # Notifications handled by Mako module
    grim slurp      # Screenshots
    swaylock        # Lockscreen
    brightnessctl   # Brightness keys
    wl-clipboard    # Clipboard
    playerctl gvfs
    pulseaudio      # For 'pactl' volume commands
    capitaine-cursors # Cursor
    git # Its git
    unzip p7zip     # The zippers
    wget curl # -.-
    polkit_gnome
    age sops # Secrets and encryption

    # Unstable
    unstable-pkgs.ani-cli
    unstable-pkgs.antigravity #AI Tool
    unstable-pkgs.yt-dlp
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
