# System builders parameterized over the flake's inputs and outputs; flake.nix instantiates this once and each system supplies only its module list. mkMicrovmSystem takes the full guest module list from the caller so this file stays free of host paths.
{
  inputs,
  outputs,
  # Overlays applied to every nixpkgs instance the builders create.
  pkgsOverlays,
}: let
  inherit (inputs) nixpkgs nixpkgs-unstable home-manager home-manager-unstable nix-darwin impermanence lanzaboote sops-nix microvm;
  commonArgs = {inherit inputs outputs;};
  mkPkgs = np: system:
    import np {
      inherit system;
      overlays = pkgsOverlays;
      config.allowUnfree = true;
    };
  pkgsFor = mkPkgs nixpkgs;
  pkgsUnstableFor = mkPkgs nixpkgs-unstable;

  # hmModule is the platform's home-manager module: nixosModules.home-manager or darwinModules.home-manager.
  mkHmModules = hmModule: [
    hmModule
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = commonArgs;
      };
    }
  ];
in {
  inherit pkgsFor pkgsUnstableFor;

  mkServerSystem = {
    system,
    modules,
  }:
    nixpkgs.lib.nixosSystem {
      specialArgs = commonArgs;
      modules =
        [
          {nixpkgs.pkgs = pkgsFor system;}
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
          sops-nix.nixosModules.sops
        ]
        ++ (mkHmModules home-manager.nixosModules.home-manager) ++ modules;
    };

  mkDesktopSystem = {
    system,
    modules,
  }:
    nixpkgs-unstable.lib.nixosSystem {
      specialArgs = commonArgs;
      modules =
        [
          {nixpkgs.pkgs = pkgsUnstableFor system;}
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
          sops-nix.nixosModules.sops
        ]
        ++ (mkHmModules home-manager-unstable.nixosModules.home-manager) ++ modules;
    };

  mkMicrovmSystem = {
    system ? "x86_64-linux",
    modules,
  }:
    nixpkgs.lib.nixosSystem {
      specialArgs = commonArgs;
      modules =
        [
          {nixpkgs.pkgs = pkgsFor system;}
          sops-nix.nixosModules.sops
          microvm.nixosModules.microvm
          impermanence.nixosModules.impermanence
        ]
        ++ modules;
    };

  mkDarwinSystem = {
    system,
    modules,
  }:
    nix-darwin.lib.darwinSystem {
      specialArgs = commonArgs;
      modules =
        [{nixpkgs.pkgs = pkgsUnstableFor system;}]
        ++ (mkHmModules home-manager-unstable.darwinModules.home-manager)
        ++ modules;
    };
}
