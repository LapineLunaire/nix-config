{
  description = "Lapine's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nixd = {
      url = "github:nix-community/nixd";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    impermanence,
    nixd,
    aagl,
    stylix,
    nixpkgs-wayland,
    vpn-confinement,
    lanzaboote,
  } @ inputs: let
    inherit (self) outputs;
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    overlays = import ./overlays {inherit inputs;};
    pkgsFor = system: extraOverlays:
      import nixpkgs {
        inherit system;
        overlays = [overlays.additions overlays.modifications] ++ extraOverlays;
        config.allowUnfree = true;
      };
  in {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    packages = forAllSystems (system: import ./pkgs (pkgsFor system []));

    nixosConfigurations = let
      baseModules = [
        impermanence.nixosModules.impermanence
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {inherit inputs outputs;};
          };
        }
      ];

      desktopModules = [
        aagl.nixosModules.default
        stylix.nixosModules.stylix
      ];
    in {
      camellya = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules =
          [
            {nixpkgs.pkgs = pkgsFor "x86_64-linux" [nixpkgs-wayland.overlays.default];}
            lanzaboote.nixosModules.lanzaboote
            ./hosts/camellya
            ./users/lapine
          ]
          ++ baseModules
          ++ desktopModules;
      };

      sparkle = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules =
          [
            {nixpkgs.pkgs = pkgsFor "x86_64-linux" [];}
            lanzaboote.nixosModules.lanzaboote
            vpn-confinement.nixosModules.default
            ./hosts/sparkle
            ./users/lapine
          ]
          ++ baseModules;
      };
    };

    homeConfigurations = {
      "lapine@aquafang" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor "aarch64-darwin" [];
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [./home-manager/aquafang];
      };
    };
  };
}
