{ config, pkgs, lib, inputs, unstable-pkgs, ... }:

{
  home.username = "alice";
  home.homeDirectory = "/home/alice";

  # Enable desired modules via options
  nixtop = {
    themes.rosepine-dark.enable = true;
    terminal.foot.enable = true;
    terminal.zsh.enable = true;
    # terminal.tmux.enable = true;
    terminal.zellij.enable = true;
    apps.fetch.enable = true;
    apps.spacemacs.enable = true;
    apps.floorp.enable = true;
    apps.yazi.enable = true;
    apps.gaming.enable = true;
    services.mako.enable = true;
    services.flatpak.enable = true;
    services.mpd.enable = true;
  };

  home.packages = with pkgs; [
    # Misc
    pkgs.palemoon-bin links2 tor-browser # Browsers
    unstable-pkgs.tutanota-desktop keepassxc # Mail
    mousepad nemo # Acker
    foot # Terminal Emulator's
    fastfetch hyfetch # Fetch
    chafa libsixel ripgrep btop # Terminal things
    transmission_4-gtk nicotine-plus # Legal things
    stack # Idk i don rembere
    krita gimp # Photo editing
    cinny-desktop weechat # Non Discord chat
    blockbench tree

    # Media
    mpv
    rmpc
    strawberry
    cava
    ffmpeg
    ffmpegthumbnailer
    feh

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
    wget curl nnn # -.-
    polkit_gnome
    age sops # Secrets and encryption

    # Unstable
    unstable-pkgs.ani-cli
    unstable-pkgs.antigravity #AI Tool
  ];

  gtk.gtk4.theme = config.gtk.theme;
  programs.yazi.shellWrapperName = "y";

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
