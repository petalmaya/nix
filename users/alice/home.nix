{ config, pkgs, lib, inputs, unstable-pkgs, ... }:

{
  home.username = "alice";
  home.homeDirectory = "/home/alice";

  nixtop = {
    themes.manguru.enable = true;
    terminal.foot.enable = true;
    terminal.zsh.enable = true;
    # terminal.tmux.enable = true;
    terminal.zellij.enable = true;
    apps.fetch.enable = true;
    # apps.floorp.enable = true;
    # apps.zen.enable = true;
    # apps.librewolf.enable = true;
    apps.firefox-esr.enable = true;
    apps.spicetify.enable = true;
    apps.yazi.enable = true;
    apps.emacs.enable = true;
    apps.gaming.enable = true;
    services.mako.enable = true;
    services.flatpak.enable = true;
    services.mpd.enable = true;
  };

  home.packages = with pkgs; [
    links2 # side browser
    unstable-pkgs.tutanota-desktop keepassxc steam # mail & gaming
    mousepad nautilus # acker
    mpvpaper hyprpicker
    foot # terminal emulator's
    fastfetch hyfetch # fetch
    chafa libsixel ripgrep btop # terminal things
    transmission_4-gtk nicotine-plus # legal things
    stack # idk i don rembere
    krita gimp # photo editing
    cinny-desktop weechat # non discord chat
    blockbench tree bitwarden-cli
    adw-gtk3

    # Media
    rmpc
    unstable-pkgs.tauon
    cava
    ffmpeg
    ffmpegthumbnailer
    feh
    loupe

    # Utilities
    swaybg
    libnotify
    grim slurp # screenshots
    swaylock
    brightnessctl
    wl-clipboard
    playerctl gvfs
    pulseaudio # for pactl
    capitaine-cursors
    git # its git
    unzip p7zip # the zippers
    wget curl # -.-
    polkit_gnome
    age sops

    unstable-pkgs.ani-cli
    unstable-pkgs.antigravity-ide # ai tool
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
