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
      sops.age.keyFile = "/var/lib/sops-nix/keys.txt";

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
      # Both hosts' primary user (alice) now runs the kurukuru theme
      # (Kuru Kuru Bar / Quickshell, see modules/home/themes/kurukuru)
      # instead of Noctalia Shell, so the greeter that matches it -
      # flutterquick's own greeter.qml, wired up via its
      # nixosModules.greeter - replaces Noctalia Greeter here too.
      # noctalia-greeter.nix is left in the tree (imported, just unused)
      # for rollback, same as the noctaniri theme module.
      nixtop.noctalia-greeter.enable = false;
      programs.kurukurubar.greeter = {
        enable = true;
        compositor = "niri"; # matches kurukuru's own niri-based session
      };

      # Give `greeter` a real, writable $HOME instead of NixOS's default
      # /var/empty (read-only) - needed so the greeter can find a
      # wallpaper at all. Without this, ~greeter/.config/... writes
      # (including the manual `sudo -u greeter quickshell ipc call
      # config setWallpaper ...` step flutterquick's own
      # greetd-examples/README.md documents) just fail, since /var/empty
      # is a root-owned placeholder, not a real home.
      users.users.greeter = {
        home = "/var/lib/greeter";
        createHome = true;
      };

      # Seed that home's config.json declaratively instead - Data/Config.qml
      # (flutterquick) reads `wallSrc` from ~/.config/kurukurubar/config.json,
      # same key your own session's config uses, so this is genuinely the
      # same mechanism, just pointed at the greeter user's (now real) home
      # via a build-time symlink rather than an imperative `ipc call` that
      # wouldn't survive a rebuild anyway.
      #
      # Change the filename below to whichever of assets/wallpaper/ you
      # actually want at the login screen - nix_bg.png was picked as a
      # reasonable "this is the NixOS box" default, not because it's
      # definitely the one you want.
      systemd.tmpfiles.rules = [
        "d /var/lib/greeter/.config/kurukurubar 0755 greeter greeter -"
        "L+ /var/lib/greeter/.config/kurukurubar/config.json - - - - ${
          pkgs.writeText "kurukuru-greeter-config.json" (builtins.toJSON {
            wallSrc = "${inputs.self}/assets/wallpaper/serial_experiments_lain_server_room.jpg";
          })
        }"
      ];

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
