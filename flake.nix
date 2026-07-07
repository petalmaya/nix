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
        inputs.noctalia-greeter.nixosModules.default
        ./modules/nixos/tor.nix
        inputs.disko.nixosModules.disko
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users = hmUsers;
          home-manager.extraSpecialArgs = { inherit inputs unstable-pkgs; };
          home-manager.sharedModules = [
            inputs.niri.homeModules.niri
            inputs.zen-browser.homeModules.twilight
            (import ./modules/home)
          ];
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
    };

  };
}
