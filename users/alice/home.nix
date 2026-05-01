{ config, pkgs, lib, inputs,  unstable-pkgs, ... }:

{
  imports = [
    # WM
    "${inputs.self}/modules/home/wm/sway.nix"
    # Terminal
    "${inputs.self}/modules/home/terminal/foot.nix"
    "${inputs.self}/modules/home/terminal/zsh.nix"
    "${inputs.self}/modules/home/terminal/tmux.nix"
    # Apps
    "${inputs.self}/modules/home/apps/fetch.nix"
    "${inputs.self}/modules/home/apps/spacemacs.nix"
    "${inputs.self}/modules/home/apps/floorp.nix"
    "${inputs.self}/modules/home/apps/rofi.nix"
    "${inputs.self}/modules/home/apps/yazi.nix"
    "${inputs.self}/modules/home/apps/gaming.nix"
    "${inputs.self}/modules/home/apps/pgm.nix"
    # Services
    "${inputs.self}/modules/home/services/mako.nix"
    "${inputs.self}/modules/home/services/flatpak.nix"
    "${inputs.self}/modules/home/services/mpd.nix"
    # Themes
    "${inputs.self}/modules/home/themes/noctalia.nix"
    "${inputs.self}/modules/home/themes/theme.nix"
  ];

  home.username = "alice";
  home.homeDirectory = "/home/alice";

  home.packages = with pkgs; [
    # Misc
    pkgs.palemoon-bin w3m tor-browser # Browsers
    unstable-pkgs.tutanota-desktop keepassxc # Mail
    xfce.mousepad nemo # Acker
    foot # Terminal Emulator's
    fastfetch hyfetch # Fetch
    chafa libsixel ripgrep btop # Terminal things
    transmission_4-gtk nicotine-plus # Legal things
    stack # Idk i don rembere
    krita gimp # Photo editing
    cinny-desktop weechat # Non Discord chat
    blockbench


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
    # App launcher handled by HM Programs
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

    # Unstable
    unstable-pkgs.ani-cli
    antigravity #AI Tool
  ];


  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
