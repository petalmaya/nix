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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
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
      url = "github:nix-community/home-manager/release-25.11";
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
    # Local Tor Config
    tor-config.url = "git+file:///home/alice/nix/.tor-config";
    # Sops
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Niri Flake
    niri.url = "github:sodiboo/niri-flake";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, noctalia-shell, sops-nix, ... } @ inputs:
  let
    mkHost = sys: hostname: hmUsers:
      let
        unstable-pkgs = import nixpkgs-unstable {
          system = sys;
          config.allowUnfree = true;
        };
      in nixpkgs.lib.nixosSystem {
        system = sys;
        specialArgs = {
          inherit inputs unstable-pkgs;
        };
        modules = [
          ./hosts/${hostname}/hardware-configuration.nix
        ./hosts/${hostname}/configuration.nix
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.tor-config.nixosModules.default
        inputs.disko.nixosModules.disko
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users = hmUsers;
          home-manager.extraSpecialArgs = { inherit inputs unstable-pkgs; };
          home-manager.sharedModules = [ inputs.niri.homeModules.niri ];
        }
      ];
    };
  in {
    nixosConfigurations = {
      wonderland = mkHost "x86_64-linux" "wonderland" {
        alice = import ./users/alice/home.nix;
        lewis = import ./users/lewis/home.nix;
      };
      rabbit = mkHost "x86_64-linux" "rabbit" {
        alice = import ./users/alice/home.nix;
        lewis = import ./users/lewis/home.nix;
      };
      teaparty = mkHost "x86_64-linux" "teaparty" {
        alice  = import ./users/alice/home.nix;
        lewis  = import ./users/lewis/home.nix;
        hatter = import ./users/hatter/home.nix;
      };
      lookingglass = mkHost "aarch64-linux" "lookingglass" {
        cheshire = import ./users/cheshire/home.nix;
      };
    };

  };
}
