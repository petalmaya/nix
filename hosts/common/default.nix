{ config, pkgs, lib, unstable-pkgs, inputs, ... }:

{
  imports = [
    "${inputs.self}/modules/nixos/cachix.nix"
    "${inputs.self}/modules/nixos/podman.nix"
    "${inputs.self}/modules/nixos/nix-ld.nix"
    "${inputs.self}/modules/nixos/noctalia-greeter.nix"
    "${inputs.self}/modules/nixos/plymouth.nix"
  ];

  options = {
    nixtop.desktop.enable = lib.mkEnableOption "Desktop environment and graphical applications";
  };

  config = lib.mkMerge [
    {
      sops.defaultSopsFile = ../../secrets/secrets.yaml;
      sops.age.keyFile = "/var/lib/sops-nix/keys.txt";

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      # don't register the native arch, qemu can't help with that anyway
      boot.binfmt.emulatedSystems = lib.filter (sys: sys != pkgs.stdenv.hostPlatform.system) [ "aarch64-linux" ];
      boot.binfmt.preferStaticEmulators = true;

      networking.networkmanager.enable = true;
      networking.enableIPv6 = true;
      time.timeZone = "America/Edmonton";

      programs.zsh.enable = true;

      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };

      nixpkgs.config.allowUnfree = true;
      nix.settings.experimental-features = [ "nix-command" "flakes" ];
      nixpkgs.config.permittedInsecurePackages = [
        "python3.12-ecdsa-0.19.1"
      ];

      users.mutableUsers = false;

      sops.secrets.alice_password.neededForUsers = true;
      users.users.alice = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.alice_password.path;
        extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIaO01Z2u6T2zPwR/XOoR6Zv0EvgAsTCvCd1M4bm7Yph alice@wonderland"
        ];
      };

      sops.secrets.lewis_password.neededForUsers = true;
      users.users.lewis = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.lewis_password.path;
        extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
        shell = pkgs.zsh;
      };

      systemd.oomd.enable = true;
      system.stateVersion = "25.11";

      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 50;
      };

      # slower fallback, zram wins on priority
      swapDevices = [{
        device = "/var/lib/swapfile";
        size = 8192;
        priority = 0;
      }];

      boot.kernel.sysctl = {
        "vm.swappiness" = 10;
      };
    }

    (lib.mkIf config.nixtop.desktop.enable {
      nixtop.noctalia-greeter.enable = false;
      programs.kurukurubar.greeter = {
        enable = true;
        compositor = "niri";
      };

      # nothing else registers a wayland session for the greeter to find
      services.displayManager.sessionPackages = [
        inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable
      ];

      # /var/empty isn't writable, greeter needs a real home for its config
      users.users.greeter = {
        home = "/var/lib/greeter";
        createHome = true;
      };

      # seed the greeter wallpaper. must be a copy ("C"), a store symlink
      # would be read-only when quickshell writes the merged config back,
      # and r! clears any stale copy from before this was correct
      systemd.tmpfiles.rules = [
        "d /var/lib/greeter/.config 0755 greeter greeter -"
        "r! /var/lib/greeter/.config/kurukurubar/config.json"
        "d /var/lib/greeter/.config/kurukurubar 0755 greeter greeter -"
        "C /var/lib/greeter/.config/kurukurubar/config.json 0644 greeter greeter - ${
          pkgs.writeText "kurukuru-greeter-config.json" (builtins.toJSON {
            wallSrc = "file://${inputs.self}/assets/wallpaper/serial_experiments_lain_server_room.jpg";
          })
        }"
      ];

      nixtop.plymouth.enable = true;

      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = pkgs.stdenv.hostPlatform.isx86_64; # 32-bit wine/games
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
        (runCommand "cartograph-cf" {} ''
          install -m444 -D ${./../../assets/font/cartograph}/*.otf -t $out/share/fonts/opentype
        '')
      ];

      xdg = {
        menus.enable = true;
        mime.enable = true;
        icons.enable = true;
      };

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
        remotes = lib.mkOptionDefault [{
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }];
      };
    })
  ];
}
