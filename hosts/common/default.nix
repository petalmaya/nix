{ config, pkgs, lib, unstable-pkgs, inputs, ... }:

{
  imports = [
    "${inputs.self}/modules/nixos/cachix.nix"       # binary cache auto-discovery
    "${inputs.self}/modules/nixos/podman.nix"       # container runtime
    "${inputs.self}/modules/nixos/nix-ld.nix"      # dynamic linker shim
    "${inputs.self}/modules/nixos/noctalia-greeter.nix" # login greeter
    "${inputs.self}/modules/nixos/plymouth.nix"    # boot splash screen
  ];

  options = {
    nixtop.desktop.enable = lib.mkEnableOption "Desktop environment and graphical applications";
  };

  # lib.mkMerge lets us split configuration into two logical blocks:
  #   1. Unconditional — applies to every host (servers, laptops, etc.)
  #   2. Desktop-only  — guarded by the nixtop.desktop.enable flag
  config = lib.mkMerge [
    # Common system configuration for all hosts
    {
      # sops-nix manages secrets.  The key file is stored outside the Nix
      # store (in /var/lib/nixsecrets/) so it never ends up world-readable.
      sops.defaultSopsFile = ../../secrets/secrets.yaml;
      sops.age.keyFile = "/var/lib/nixsecrets/keys.txt";

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      # binfmt: transparently run aarch64 binaries via QEMU on x86_64 hosts.
      # The filter avoids registering the native arch (it's already supported).
      boot.binfmt.emulatedSystems = lib.filter (sys: sys != pkgs.stdenv.hostPlatform.system) [ "aarch64-linux" ];
      boot.binfmt.preferStaticEmulators = true;  # use static QEMU builds for reliability
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
      # python3.12-ecdsa is needed by some tooling; marked insecure upstream
      # but it's only used locally, not in any network-exposed path.
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

      systemd.oomd.enable = true;  # out-of-memory daemon to kill runaway processes
      system.stateVersion = "25.11";

      # Zram
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 50;  # use up to 50% of RAM for the zram device
      };

      # Disk swap as a slower fallback at lower priority than zram.
      swapDevices = [{
        device = "/var/lib/swapfile";
        size = 8192;      # 8 GiB
        priority = 0;     # lower = used last
      }];

      # Low swappiness = prefer keeping things in RAM; only swap under pressure.
      boot.kernel.sysctl = {
        "vm.swappiness" = 10;
      };
    }

    # Desktop/Graphical configuration (only for GUI-enabled hosts)
    (lib.mkIf config.nixtop.desktop.enable {
      # Enable Noctalia Greeter (DM)
      nixtop.noctalia-greeter.enable = true;

      # Enable Plymouth Boot Splash
      nixtop.plymouth.enable = true;

      # Audio
      # rtkit lets PipeWire request real-time scheduling priority for
      # low-latency audio without running as root.
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = pkgs.stdenv.hostPlatform.isx86_64;  # for 32-bit wine/games
        pulse.enable = true;  # PulseAudio compatibility shim
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

      # Steam
      programs.steam.enable = pkgs.stdenv.hostPlatform.isx86_64;
      hardware.steam-hardware.enable = true;

      # Xbox controller Bluetooth & rumble support
      hardware.xpadneo.enable = true;
      boot.extraModprobeConfig = ''
        options bluetooth disable_ertm=1
      '';

      services.gvfs.enable = true;          # virtual filesystem (MTP, SMB, trash, etc.)
      services.udisks2.enable = true;       # auto-mount removable drives
      services.gnome.gnome-keyring.enable = true;
      # Unlock the keyring automatically on login via PAM.
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
