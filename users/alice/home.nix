{ config, pkgs, lib, inputs,  unstable-pkgs, ... }:

{
  imports = [
    "${inputs.self}/modules/home/sway.nix"
    "${inputs.self}/modules/home/foot.nix"
    "${inputs.self}/modules/home/fetch.nix"
    "${inputs.self}/modules/home/spacemacs.nix"
    "${inputs.self}/modules/home/floorp.nix"
    "${inputs.self}/modules/home/rofi.nix"
    "${inputs.self}/modules/home/mako.nix"
    "${inputs.self}/modules/home/flatpak.nix"
    "${inputs.self}/modules/home/noctalia.nix"
    "${inputs.self}/modules/home/zsh.nix"
  ];

  services.flatpak = {
    packages = [
      "app.twintaillauncher.ttl"
    ];
  };

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


    # Pgm
    jdk25
    ghc
    cabal-install
    haskell-language-server
    python3

    # Media
    mpv
    rmpc
    audacious
    cava
    ffmpeg
    ffmpegthumbnailer
    feh

    # Gaming/Emu
    bottles
    wine
    renpy
    obs-studio
    prismlauncher
    openttd
    openrct2
    pkgs.bolt-launcher

    # Slightly More anoyoing
    balatro

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


  # GTK & Cursor theme setup
  gtk = {
    enable = true;
    theme = {
      name = "Everforest-Dark-B";
      package = pkgs.everforest-gtk-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  home.pointerCursor = {
    name = "capitaine-cursors";
    package = pkgs.capitaine-cursors;
    size = 24;
    gtk.enable = true;
  };
  # MPD
  services.mpd = {
    enable = true;
    musicDirectory = "/home/alice/Music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "My PipeWire Output"
        mixer_type "software"
      }
    '';
  };

  # Add HM managed programs
  programs.tmux = {
    enable = true;
    plugins = [
      (pkgs.tmuxPlugins.mkTmuxPlugin {
        pluginName = "tmux-everforest";
        version = "unstable";
        src = pkgs.fetchFromGitHub {
          owner = "TanglingTreats";
          repo = "tmux-everforest";
          rev = "master";
          sha256 = "081iqmcgskfzb4qnlcnya9wppxsrzp7p3z0pxq72sx1y6lh2y2id";
        };
      })
    ];
    extraConfig = ''
      set -g @tmux-everforest 'dark-medium'
    '';
  };

  programs.yazi = {
    enable = true;
  };

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
