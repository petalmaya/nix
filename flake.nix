{
  description = "Alice's Nixtop";

  nixConfig = {
    # NOTE: no niri-epireyn.cachix.org entry here (unlike nix-community/
    # noctalia below) - don't have a verified public key for it to hand
    # you, and typing in a signing key I can't verify is worse than not
    # having the cache. Run `cachix use niri-epireyn` yourself once
    # (fetches and pins the real key interactively, same prompt-and-write
    # pattern you saw for the two below) if you want it; otherwise niri
    # just builds from the nixpkgs cache via pkgs.niri as a fallback,
    # slower to update but no less trustworthy.
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://noctalia.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  inputs = {
    # Stable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    # Unstable
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Nixpak
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    # Emacs
    nixmacs = {
      url = "github:petalmaya/nixmacs";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # emacs-pgtk (Wayland-native, real alpha-background) isn't in nixpkgs
    # under that name by default on every channel - this overlay is what
    # actually provides it. Used by modules/home/apps/emacs, not nixmacs
    # above (that input's unused right now - flutterice-emacs is vendored
    # straight into modules/home/apps/emacs/emacs instead).
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Home Manger
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Firefox Addons
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Disko
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Noctalia Shell
    noctalia-shell.url = "github:noctalia-dev/noctalia-shell";
    # Noctalia Greeter
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Sops
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Niri Flake (epireyn's actively-maintained fork of sodiboo/niri-flake -
    # see modules/home/themes/{kurukuru,noctaniri}/niri/default.nix.
    # Home Manager's own built-in wayland.windowManager.niri module (see
    # git history around this line) would've meant tracking HM's `master`
    # branch instead of `release-26.05`, which reports itself as a newer
    # HM version than the pinned nixpkgs and throws a mismatch warning on
    # every rebuild - plus master's picked up other new defaults
    # (home.shell.enableNushellIntegration) that don't yet reconcile
    # cleanly with a stable-branch nixpkgs. Back on a flake input + the
    # release branch instead, until 26.11 lands and HM's release branch
    # catches up to master's niri module. The built-in-module version of
    # these two files is kept as `default.nix.bak` alongside the current
    # ones - unimported, not deleted - so switching back later is a
    # rename, not a rewrite.
    niri = {
      url = "github:epireyn/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Zen Browser
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Spicetify
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Kuru Kuru Bar (Quickshell config) - vendored directly into
    # modules/home/themes/kurukuru/quickshell rather than pulled in as a
    # separate `flutterquick` flake. Used to be its own repo/input; folded
    # in so it's easier to hack on and debug alongside the rest of the
    # theme instead of round-tripping through another repo. Still needs
    # its own `quickshell` input (not in nixpkgs proper yet) - see
    # modules/home/themes/kurukuru/package.nix for the build.
    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Matugen's own upstream flake - provides the declarative
    # `programs.matugen` Home Manager module (module.nix), used instead of
    # hand-rolling matugen's config.toml as raw Nix. See
    # modules/home/services/matugen, which builds its `templates` option
    # straight from modules/home/services/matugen/config.toml via
    # builtins.fromTOML.
    matugen = {
      url = "github:InioX/matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # All flake inputs are collected as `inputs` so they can be forwarded into
  # NixOS/Home Manager modules via `specialArgs` / `extraSpecialArgs`.
  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, noctalia-shell, sops-nix, spicetify-nix, ... } @ inputs:
  let
    # mkHost builds a full NixOS system configuration.
    # Arguments:
    #   sys      – the Nix system string, e.g. "x86_64-linux"
    #   hostname – matches a directory under ./hosts/
    #   hmUsers  – attrset of { username = homeConfig; } passed to Home Manager
    mkHost = sys: hostname: hmUsers:
      let
        # Instantiate nixpkgs-unstable separately so individual packages from
        # the rolling channel can be cherry-picked with `unstable-pkgs.<name>`.
        unstable-pkgs = import nixpkgs-unstable {
          system = sys;
          config.allowUnfree = true;
        };
      in nixpkgs.lib.nixosSystem {
        system = sys;
        # Make `inputs` and `unstable-pkgs` available to every NixOS module
        # without having to wire them through manually each time.
        specialArgs = {
          inherit inputs unstable-pkgs;
        };
        modules = [
          ./hosts/${hostname}/hardware-configuration.nix
        ./hosts/${hostname}/configuration.nix
        { nixpkgs.overlays = [ inputs.emacs-overlay.overlays.default ]; }
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.noctalia-greeter.nixosModules.default
        ./modules/nixos/kurukuru-greeter.nix
        ./modules/nixos/tor.nix
        inputs.disko.nixosModules.disko
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          # useGlobalPkgs – share the NixOS pkgs instance so HM doesn't
          # compile its own separate copy of nixpkgs.
          home-manager.useGlobalPkgs = true;
          # useUserPackages – install HM packages into /etc/profiles/per-user
          # instead of ~/.nix-profile, which plays nicer with some tooling.
          home-manager.useUserPackages = true;
          home-manager.users = hmUsers;
          # Forward the same extra args into every Home Manager module.
          home-manager.extraSpecialArgs = { inherit inputs unstable-pkgs; };
          # sharedModules are available to all users' home configs.
          # Third-party HM modules are loaded here so user files stay lean.
          home-manager.sharedModules = [
            inputs.niri.homeModules.niri          # niri window manager HM integration (epireyn's fork)
            inputs.zen-browser.homeModules.twilight # Zen browser home module
            inputs.spicetify-nix.homeManagerModules.default # Spicetify Spotify theming
            inputs.matugen.nixosModules.default    # `programs.matugen` (upstream module, used from HM)
            (import ./modules/home)               # our local modules/home registry
          ];
        }
      ];
    };
  in {
    nixosConfigurations = {
      # "wonderland" – the primary desktop/laptop machine
      wonderland = mkHost "x86_64-linux" "wonderland" {
        alice = import ./users/alice/home.nix;
        lewis = import ./users/lewis/home.nix;
      };
      # "rabbit" – secondary machine (same user configs, different hardware)
      rabbit = mkHost "x86_64-linux" "rabbit" {
        alice = import ./users/alice/home.nix;
        lewis = import ./users/lewis/home.nix;
      };
    };

  };
}
