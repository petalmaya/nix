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

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # EWM builds against its own locked unstable, so no nixpkgs follows.
    ewm.url = "https://codeberg.org/ezemtsov/ewm/archive/master.tar.gz";
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
      mkHost =
        sys: hostname: hmUsers:
        let
          unstable-pkgs = import nixpkgs-unstable {
            system = sys;
            config.allowUnfree = true;
          };
          mangoHM =
            if inputs.mango ? homeManagerModules then
              inputs.mango.homeManagerModules.default
            else if inputs.mango ? homeModules then
              inputs.mango.homeModules.default
            else
              null;
          extraHmModules = builtins.filter (x: x != null) [ mangoHM ];
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
              { nixpkgs.overlays = [ inputs.emacs-overlay.overlays.default ]; }
              inputs.nix-flatpak.nixosModules.nix-flatpak
              inputs.disko.nixosModules.disko
              sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
              (
                let
                  m = inputs.mango.nixosModules or { };
                in
                m.mango or m.default or { }
              )
              inputs.silentSDDM.nixosModules.default
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users = hmUsers;
                  extraSpecialArgs = {
                    inherit inputs unstable-pkgs self;
                  };
                  sharedModules =
                    (import ./modules/default.nix).homeModules
                    ++ [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ]
                    ++ extraHmModules;
                  backupFileExtension = "hm-backup";
                };
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

      # Bare `nix fmt` formats the whole tree; the wrapper supplies the file
      # list because bare nixfmt would format stdin instead.
      formatter.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        pkgs.writeShellApplication {
          name = "fmt";
          runtimeInputs = [
            pkgs.nixfmt
            pkgs.findutils
          ];
          text = ''
            if [ "$#" -eq 0 ]; then
              exec find . -name '*.nix' -exec nixfmt {} +
            fi
            exec nixfmt "$@"
          '';
        };
    };
}
