{
  description = "Alice's Nixtop";

  nixConfig = {
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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    nixmacs = {
      url = "github:petalmaya/nixmacs";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-shell.url = "github:noctalia-dev/noctalia-shell";
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hm's own niri module wants master, i want release-26.05
    niri = {
      url = "github:epireyn/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    matugen = {
      url = "github:InioX/matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, noctalia-shell, sops-nix, spicetify-nix, ... } @ inputs:
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
          { nixpkgs.overlays = [ inputs.emacs-overlay.overlays.default ]; }
          inputs.nix-flatpak.nixosModules.nix-flatpak
          inputs.noctalia-greeter.nixosModules.default
          ./modules/nixos/nagare-greeter.nix
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
              inputs.spicetify-nix.homeManagerModules.default
              inputs.matugen.nixosModules.default
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
