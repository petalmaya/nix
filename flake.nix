{
  description = "Alice's Nixtop";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://niri.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
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
      url = "git+https://codeberg.org/sheep/nixmacs";
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
    # Niri Flake
    niri = {
      url = "github:sodiboo/niri-flake";
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
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.noctalia-greeter.nixosModules.default
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
            inputs.niri.homeModules.niri          # niri window manager HM integration
            inputs.zen-browser.homeModules.twilight # Zen browser home module
            inputs.spicetify-nix.homeManagerModules.default # Spicetify Spotify theming
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
