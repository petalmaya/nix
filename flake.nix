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

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-shell.url = "github:noctalia-dev/noctalia-shell";
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      sops-nix,
      ...
    }@inputs:
    let
      # Helper to build a host.  hmUsers is an attrset of user -> home.nix import
      mkHost =
        sys: hostname: hmUsers:
        let
          unstable-pkgs = import nixpkgs-unstable {
            system = sys;
            config.allowUnfree = true;
          };
          # defensively resolve noctalia home module (upstream has changed the attr path once)
          noctaliaHM =
            if inputs.noctalia-shell ? homeModules then inputs.noctalia-shell.homeModules.default
            else if inputs.noctalia-shell ? homeManagerModules then inputs.noctalia-shell.homeManagerModules.default
            else null;
          # mango HM module if the flake exposes one, otherwise null
          mangoHM =
            if inputs.mango ? homeManagerModules then inputs.mango.homeManagerModules.default
            else if inputs.mango ? homeModules then inputs.mango.homeModules.default
            else null;
          extraHmModules = builtins.filter (x: x != null) [ noctaliaHM mangoHM ];
          # hardware file may not exist for garden until install time
          hwPath = ./hosts/${hostname}/hardware-configuration.nix;
          hwImports = if builtins.pathExists hwPath then [ hwPath ] else [ ];
        in
        nixpkgs.lib.nixosSystem {
          system = sys;
          specialArgs = {
            inherit inputs unstable-pkgs self;
          };
          modules =
            hwImports
            ++ [
              ./hosts/${hostname}/default.nix
              ./hosts/${hostname}/disko.nix
            ]
            ++ (import ./modules/default.nix).nixosModules
            ++ [
              # third-party NixOS modules
              { nixpkgs.overlays = [ inputs.emacs-overlay.overlays.default ]; }
              inputs.nix-flatpak.nixosModules.nix-flatpak
              inputs.disko.nixosModules.disko
              sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
              # Mango flake module (upstream) – provides programs.mango with addLoginEntry
              (if inputs.mango ? nixosModules then
                (if inputs.mango.nixosModules ? mango then inputs.mango.nixosModules.mango
                 else if inputs.mango.nixosModules ? default then inputs.mango.nixosModules.default
                 else { })
               else { })
              inputs.noctalia-greeter.nixosModules.default
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users = hmUsers;
                home-manager.extraSpecialArgs = {
                  inherit inputs unstable-pkgs self;
                };
                home-manager.sharedModules =
                  (import ./modules/default.nix).homeModules
                  ++ [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ]
                  ++ extraHmModules;
                home-manager.backupFileExtension = "hm-backup";
              }
            ];
        };
    in
    {
      nixosConfigurations = {
        wonderland = mkHost "x86_64-linux" "wonderland" {
          alice = import ./modules/user/alice/home.nix;
          lewis = import ./modules/user/lewis/home.nix;
        };
        rabbit = mkHost "x86_64-linux" "rabbit" {
          lewis = import ./modules/user/lewis/home.nix;
        };
        garden = mkHost "x86_64-linux" "garden" {
          rose = import ./modules/user/rose/home.nix;
        };
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
    };
}
