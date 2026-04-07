{
  description = "Carmilla's nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";

    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
      inputs.flake-compat.follows = "flake-compat";
    };

    flake-compat.url = "github:NixOS/flake-compat";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
      inputs.pre-commit.inputs.flake-compat.follows = "flake-compat";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
  };

  outputs = {
    self,
    nixpkgs,
    aagl,
    home-manager,
    impermanence,
    lanzaboote,
    nix-darwin,
    sops-nix,
    stylix,
    vpn-confinement,
    ...
  } @ inputs: let
    inherit (self) outputs;
    commonArgs = {inherit inputs outputs;};
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    overlays = import ./overlays {inherit inputs;};
    pkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays = [overlays.additions overlays.modifications];
        config.allowUnfree = true;
      };

    nixosBaseModules = [
      impermanence.nixosModules.impermanence
      lanzaboote.nixosModules.lanzaboote
      sops-nix.nixosModules.sops
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = commonArgs;
        };
      }
    ];

    nixosDesktopModules = [
      aagl.nixosModules.default
      stylix.nixosModules.stylix
    ];

    darwinBaseModules = [
      home-manager.darwinModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = commonArgs;
        };
      }
    ];
  in {
    inherit overlays;

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    packages = forAllSystems (system: import ./pkgs (pkgsFor system));

    nixosConfigurations = {
      camellya = nixpkgs.lib.nixosSystem {
        specialArgs = commonArgs;
        modules =
          [
            {nixpkgs.pkgs = pkgsFor "x86_64-linux";}
            ./hosts/camellya
            ./users/carmilla
          ]
          ++ nixosBaseModules
          ++ nixosDesktopModules;
      };

      sparkle = nixpkgs.lib.nixosSystem {
        specialArgs = commonArgs;
        modules =
          [
            {nixpkgs.pkgs = pkgsFor "x86_64-linux";}
            vpn-confinement.nixosModules.default
            ./hosts/sparkle
            ./users/carmilla
          ]
          ++ nixosBaseModules;
      };

      sparxie = nixpkgs.lib.nixosSystem {
        specialArgs = commonArgs;
        modules =
          [
            {nixpkgs.pkgs = pkgsFor "aarch64-linux";}
            ./hosts/sparxie
            ./users/carmilla
          ]
          ++ nixosBaseModules;
      };
    };

    darwinConfigurations = {
      silverwolf = nix-darwin.lib.darwinSystem {
        specialArgs = commonArgs;
        modules =
          [
            {nixpkgs.pkgs = pkgsFor "aarch64-darwin";}
            ./hosts/silverwolf
            ./users/carmilla
          ]
          ++ darwinBaseModules;
      };
    };
  };
}
