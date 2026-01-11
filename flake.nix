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
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    impermanence,
    nixd,
  } @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    pkgsFor = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
  in {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    nixosConfigurations = {
      sampo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          {nixpkgs.pkgs = pkgsFor "x86_64-linux";}
          impermanence.nixosModules.impermanence
          home-manager.nixosModules.home-manager
          ./hosts/sampo
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {inherit inputs;};
            };
          }
          ./users/lapine
        ];
      };
    };

    homeConfigurations = {
      "lapine@aquafang" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor "aarch64-darwin";
        extraSpecialArgs = {inherit inputs;};
        modules = [./home-manager/aquafang];
      };
    };
  };
}
