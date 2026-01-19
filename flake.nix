{
  description = "Lapine's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    nixd.url = "github:nix-community/nixd";

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
  } @ inputs: let
    inherit (self) outputs;
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    pkgsFor = system: overlays:
      import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
  in {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

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
