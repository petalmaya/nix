{ config, pkgs, lib, unstable-pkgs, inputs, ... }:

{
  imports = [
    "${inputs.self}/modules/nixos/cachix.nix"
    "${inputs.self}/modules/nixos/podman.nix"
    "${inputs.self}/modules/nixos/nix-ld.nix"
  ];

  options = {
    nixtop.desktop.enable = lib.mkEnableOption "Desktop environment and graphical applications";
  };

  config = lib.mkMerge [
    # Common system configuration for all hosts
    {
      sops.defaultSopsFile = ../../secrets/secrets.yaml;
      sops.age.keyFile = "/var/lib/nixsecrets/keys.txt";

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.binfmt.emulatedSystems = lib.filter (sys: sys != pkgs.stdenv.hostPlatform.system) [ "aarch64-linux" ];
      boot.binfmt.preferStaticEmulators = true;
      networking.networkmanager.enable = true;
      networking.enableIPv6 = true;
      time.timeZone = "America/Edmonton";

      # Basic shell/terminal tools
      programs.zsh.enable = true;

      # OpenSSH
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

      # User account (base)
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

      # Zram
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 50;
      };

      swapDevices = [{
        device = "/var/lib/swapfile";
        size = 8192;
        priority = 0;
      }];

      boot.kernel.sysctl = {
        "vm.swappiness" = 10;
      };
    }

    # Desktop/Graphical configuration (only for GUI-enabled hosts)
    (lib.mkIf config.nixtop.desktop.enable {
      # Audio
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

      # Fonts 
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

      # Desktop / Wayland stuff
      xdg = {
        menus.enable = true;
        mime.enable = true;
        icons.enable = true;
      };

      # SwayFX
      programs.sway = {
        enable = true;
        package = pkgs.swayfx;
      };

      # Steam managed via Flatpak now
      # programs.steam.enable = pkgs.stdenv.hostPlatform.isx86_64;
      hardware.steam-hardware.enable = true;

      # Xbox controller Bluetooth & rumble support
      hardware.xpadneo.enable = true;
      boot.extraModprobeConfig = ''
        options bluetooth disable_ertm=1
      '';

      services.gvfs.enable = true;
      services.udisks2.enable = true;
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.login.enableGnomeKeyring = true;

      # Flatpak - system service (packages managed per-user in Home Manager)
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
