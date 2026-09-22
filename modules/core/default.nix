{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./cachix.nix
    ./plymouth.nix
    ./nix-ld.nix
    ./podman.nix
    ./greetd.nix
    ./wifi.nix
    ./intel.nix
  ];

  options.nixtop = {
    desktop.enable = lib.mkEnableOption "Desktop environment and graphical applications";

    shell = lib.mkOption {
      type = lib.types.enum [
        "noctalia"
        "quickshell"
        "jes"
        "none"
      ];
      default = "none";
      description = "Host default for which shell owns the session. Users override via the HM-side nixtop.shell (modules/shell); NixOS-side consumers (greeter default) always follow this host value. 'none' = waybar-only (swayfx bar, no shell).";
    };
    sway.bar = lib.mkOption {
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
    dev = {
      liveEmacs = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Symlink emacs config dir live into the repo.";
      };
      liveMango = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Symlink ~/.config/mango live into the repo.";
      };
      liveMatugen = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Symlink matugen templates live into the repo.";
      };
      liveQuickshell = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Symlink quickshell config live into the repo.";
      };
      liveSway = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Symlink sway config live into the repo (mirrors liveMango).";
      };
      liveMako = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Symlink mako config dir live into the repo (generated colors live in ~/.local/state, so this is safe).";
      };
      liveWaybar = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Symlink waybar config live into the repo (config only; style.css stays matugen-owned).";
      };
    };
  };

  config = lib.mkMerge [
    {
      sops = {
        defaultSopsFile = ../../secrets/secrets.yaml;
        age.keyFile = "/var/lib/sops-nix/keys.txt";
        secrets.alice_password.neededForUsers = true;
        secrets.lewis_password.neededForUsers = true;
      };

      boot = {
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;
        binfmt.emulatedSystems = lib.filter (sys: sys != pkgs.stdenv.hostPlatform.system) [
          "aarch64-linux"
        ];
        binfmt.preferStaticEmulators = true;
        kernel.sysctl = {
          "vm.swappiness" = 10;
        };
      };

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

      users = {
        mutableUsers = false;

        users.alice = {
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

        users.lewis = {
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
      };

      # rose is defined on garden with a sops secret (see
      # hosts/garden/default.nix), so no rose secret is required here.

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
    }

    (lib.mkIf config.nixtop.desktop.enable {
      programs = {
        # Mango session via the upstream flake; addLoginEntry registers the .desktop.
        mango = {
          enable = lib.mkDefault true;
          addLoginEntry = lib.mkDefault true;
        };
        sway = {
          enable = true;
          package = pkgs.swayfx;
        };
        steam.enable = pkgs.stdenv.hostPlatform.isx86_64;
      };

      # The greetd greeter user needs a writable home plus an explicit group.
      users.users.greeter = {
        isSystemUser = true;
        group = "greeter";
        home = "/var/lib/greeter";
        createHome = true;
      };
      users.groups.greeter = { };

      nixtop = {
        # SilentSDDM is the default greeter; override per-host if needed.
        greetd.greeter = lib.mkDefault "sddm";
        security.apparmor.enable = lib.mkDefault true;
        plymouth.enable = lib.mkDefault true;
      };

      services = {
        # Sway is the default session for the SDDM chooser (alongside Mango)
        displayManager.defaultSession = lib.mkDefault "sway";
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = pkgs.stdenv.hostPlatform.isx86_64;
          pulse.enable = true;
        };
        gvfs.enable = true;
        udisks2.enable = true;
        gnome.gnome-keyring.enable = true;
        flatpak = {
          enable = true;
          remotes = lib.mkOptionDefault [
            {
              name = "flathub";
              location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
            }
          ];
        };
      };

      security = {
        polkit.enable = true;
        rtkit.enable = true;
        pam.services.login.enableGnomeKeyring = true;
      };

      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
          extraPackages = with pkgs; [
            vulkan-loader
            vulkan-validation-layers
          ];
        };
        steam-hardware.enable = true;
        xpadneo.enable = true;
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

      boot.extraModprobeConfig = ''
        options bluetooth disable_ertm=1
      '';
    })
  ];
}
