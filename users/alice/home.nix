{ config, pkgs, lib, inputs,  unstable-pkgs, ... }:

{
  imports = [
    # WM — enable ONE theme at a time
    #"${inputs.self}/modules/home/themes/everforest"
    "${inputs.self}/modules/home/themes/rosepine-dark"
    # Terminal
    "${inputs.self}/modules/home/terminal/foot"
    "${inputs.self}/modules/home/terminal/zsh"
    "${inputs.self}/modules/home/terminal/tmux"
    # Apps
    "${inputs.self}/modules/home/apps/fetch"
    "${inputs.self}/modules/home/apps/spacemacs.nix"
    "${inputs.self}/modules/home/apps/floorp.nix"

    "${inputs.self}/modules/home/apps/yazi.nix"
    "${inputs.self}/modules/home/apps/gaming.nix"
    # Services
    "${inputs.self}/modules/home/services/mako"
    "${inputs.self}/modules/home/services/flatpak.nix"
    "${inputs.self}/modules/home/services/mpd.nix"
    # Themes
    "${inputs.self}/modules/home/themes/theme.nix"
  ];

  home.username = "alice";
  home.homeDirectory = "/home/alice";

  # nixtop.themes.everforest.enable = true;
  nixtop.themes.rosepine-dark.enable = true;


  home.packages = with pkgs; [
    # Misc
    pkgs.palemoon-bin links2 tor-browser # Browsers
    unstable-pkgs.tutanota-desktop keepassxc # Mail
    xfce.mousepad nemo # Acker
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
    audacious
    cava
    ffmpeg
    ffmpegthumbnailer
    feh

    # Utilities
    swaybg          # Wallpaper
    libnotify # Notifications handled by Mako module
    #rofi # App launcher handled by HM Programs
    grim slurp      # Screenshots
    swaylock        # Lockscreen
    brightnessctl   # Brightness keys
    wl-clipboard    # Clipboard
    playerctl gvfs
    pulseaudio      # For 'pactl' volume commands
    capitaine-cursors # Curosor
    git # Its git
    unzip p7zip     # The zippers
    wget curl nnn # -.-
    polkit_gnome
    age sops # Secrets and encryption

    # Unstable
    unstable-pkgs.ani-cli
    unstable-pkgs.antigravity #AI Tool
  ];


  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
