{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./cachix.nix
    ./plymouth.nix
    ./nix-ld.nix
    ./podman.nix
    ./greetd.nix
  ];

  options = {
    nixtop.desktop.enable = lib.mkEnableOption "Desktop environment and graphical applications";

    nixtop.shell = lib.mkOption {
      type = lib.types.enum [
        "noctalia"
        "quickshell"
        "jes"
        "none"
      ];
      default = "none";
      description = "Host default for which shell owns the session. Users override via the HM-side nixtop.shell (modules/shell); NixOS-side consumers (greeter default) always follow this host value. 'none' = waybar-only (swayfx bar, no shell).";
    };
    nixtop.sway.bar = lib.mkOption {
      type = lib.types.enum [
        "waybar"
        "swaybar"
        "none"
      ];
      default = "waybar";
      description = "Which bar to run under swayfx. waybar is primary; swaybar is archived status.sh; none disables bar entirely.";
    };

    # dev live-edit flags (one symlink per flag, all default off except liveEmacs;
    # see AGENTS.md for the symlink budget)
    nixtop.dev.liveEmacs = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Symlink emacs config dir live into the repo.";
    };
    nixtop.dev.liveMango = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Symlink ~/.config/mango live into the repo.";
    };
    nixtop.dev.liveMatugen = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Symlink matugen templates live into the repo.";
    };
    nixtop.dev.liveQuickshell = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Symlink quickshell config live into the repo.";
    };
    nixtop.dev.liveSway = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Symlink sway config live into the repo (mirrors liveMango).";
    };
    nixtop.dev.liveMako = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Symlink mako config dir live into the repo (generated colors live in ~/.local/state, so this is safe).";
    };
    nixtop.dev.liveWaybar = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Symlink waybar config live into the repo (config only; style.css stays matugen-owned).";
    };
  };

  config = lib.mkMerge [
    {
      sops.defaultSopsFile = ../../secrets/secrets.yaml;
      sops.age.keyFile = "/var/lib/sops-nix/keys.txt";

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.binfmt.emulatedSystems = lib.filter (sys: sys != pkgs.stdenv.hostPlatform.system) [
        "aarch64-linux"
      ];
      boot.binfmt.preferStaticEmulators = true;

      networking.networkmanager.enable = true;
      networking.enableIPv6 = true;
      time.timeZone = "America/Edmonton";

      # Caps Lock is Ctrl: console + X11 here, each compositor carries
      # its own (sway, mango, EWM).
      services.xserver.xkb.options = "ctrl:nocaps";
      console.useXkbConfig = true;

      programs.zsh.enable = true;

      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };

      nixpkgs.config.allowUnfree = true;
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      nixpkgs.config.permittedInsecurePackages = [
        "python3.12-ecdsa-0.19.1"
      ];

      users.mutableUsers = false;

      sops.secrets.alice_password.neededForUsers = true;
      users.users.alice = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.alice_password.path;
        extraGroups = [
          "networkmanager"
          "wheel"
          "video"
          "audio"
          "input"
        ];
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIaO01Z2u6T2zPwR/XOoR6Zv0EvgAsTCvCd1M4bm7Yph alice@wonderland"
        ];
      };

      sops.secrets.lewis_password.neededForUsers = true;
      users.users.lewis = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.lewis_password.path;
        extraGroups = [
          "networkmanager"
          "wheel"
          "video"
          "audio"
          "input"
        ];
        shell = pkgs.zsh;
      };

      # rose is defined on garden with a placeholder password, so no
      # rose secret is required here.

      systemd.oomd.enable = true;
      system.stateVersion = "26.05";

      # swap defaults – host overrides for garden (zswap) vs wonderland/rabbit (zram)
      zramSwap = {
        enable = lib.mkDefault true;
        algorithm = "zstd";
        memoryPercent = 50;
      };

      swapDevices = lib.mkDefault [
        {
          device = "/var/lib/swapfile";
          size = 8192;
          priority = 0;
        }
      ];

      boot.kernel.sysctl = {
        "vm.swappiness" = 10;
      };
    }

    (lib.mkIf config.nixtop.desktop.enable {
      # Mango session via the upstream flake; addLoginEntry registers the .desktop.
      programs.mango = {
        enable = lib.mkDefault true;
        addLoginEntry = lib.mkDefault true;
      };

      # The greetd greeter user needs a writable home plus an explicit group.
      users.users.greeter = {
        isSystemUser = true;
        group = "greeter";
        home = "/var/lib/greeter";
        createHome = true;
      };
      users.groups.greeter = { };

      # SilentSDDM is the default greeter; override per-host if needed.
      nixtop.greetd.greeter = lib.mkDefault "sddm";

      nixtop.security.apparmor.enable = lib.mkDefault true;

      # Sway is the default session for the SDDM chooser (alongside Mango)
      services.displayManager.defaultSession = lib.mkDefault "sway";

      nixtop.plymouth.enable = lib.mkDefault true;

      security.polkit.enable = true;

      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = pkgs.stdenv.hostPlatform.isx86_64;
        pulse.enable = true;
      };

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          vulkan-loader
          vulkan-validation-layers
        ];
      };

      fonts.packages = with pkgs; [
        poppins
        courier-prime
        font-awesome
        nerd-fonts.symbols-only
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts
        nerd-fonts.jetbrains-mono
        source-code-pro
        (runCommand "cartograph-cf" { } ''
          install -m444 -D ${./../../assets/font/cartograph}/*.otf -t $out/share/fonts/opentype
        '')
      ];

      xdg = {
        menus.enable = true;
        mime.enable = true;
        icons.enable = true;
      };

      # Greeter/SDDM choosers scan these dirs, but sessionPackages alone
      # doesn't link them into the system path.
      environment.pathsToLink = [
        "/share/wayland-sessions"
        "/share/xsessions"
      ];

      programs.sway = {
        enable = true;
        package = pkgs.swayfx;
      };

      programs.steam.enable = pkgs.stdenv.hostPlatform.isx86_64;
      hardware.steam-hardware.enable = true;

      hardware.xpadneo.enable = true;
      boot.extraModprobeConfig = ''
        options bluetooth disable_ertm=1
      '';

      services.gvfs.enable = true;
      services.udisks2.enable = true;
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.login.enableGnomeKeyring = true;

      services.flatpak = {
        enable = true;
        remotes = lib.mkOptionDefault [
          {
            name = "flathub";
            location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
          }
        ];
      };
    })
  ];
}
