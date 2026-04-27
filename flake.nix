{
  description = "Alice's Nixtop";

  inputs = {
    # Stable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # Unstable
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Nixpak
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    #AliceVim
    avim = {
          url = "git+https://codeberg.org/sheep/avim";
          inputs.nixpkgs.follows = "nixpkgs";
    };
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
    # Noctalia Shell
    noctalia-shell.url = "github:noctalia-dev/noctalia-shell";
    # Local Tor Config
    tor-config.url = "git+file:///home/alice/nix/.tor-config";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, avim, noctalia-shell, ... } @ inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    unstable-pkgs = import nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
    };
    mkHost = hostname: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
      inherit inputs unstable-pkgs;
      };
      modules = [
        ./hosts/${hostname}/hardware-configuration.nix
        ./hosts/${hostname}/configuration.nix
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.tor-config.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.alice = import ./users/alice/home.nix;
          home-manager.users.lewis = import ./users/lewis/home.nix;
          home-manager.extraSpecialArgs = { inherit inputs unstable-pkgs; };
        }
      ];
    };
  in {
    nixosConfigurations = {
      wonderland = mkHost "wonderland";
      rabbit = mkHost "rabbit";
    };

  };
}
