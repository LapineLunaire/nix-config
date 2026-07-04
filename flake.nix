{
  description = "Carmilla's nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    flake-compat.url = "github:NixOS/flake-compat/master";

    rust-overlay = {
      url = "github:oxalica/rust-overlay/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    impermanence = {
      url = "github:nix-community/impermanence/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager-unstable";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.rust-overlay.follows = "rust-overlay";
      inputs.pre-commit.inputs.flake-compat.follows = "flake-compat";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:microvm-nix/microvm.nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement/master";

    unifi-os-server = {
      url = "github:rcambrj/unifi-os-server";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix/main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.rust-overlay.follows = "rust-overlay";
      inputs.flake-compat.follows = "flake-compat";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager/trunk";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager-unstable";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    home-manager-unstable,
    nix-darwin,
    impermanence,
    lanzaboote,
    sops-nix,
    microvm,
    vpn-confinement,
    unifi-os-server,
    aagl,
    ...
  } @ inputs: let
    inherit (self) outputs;
    commonArgs = {inherit inputs outputs;};
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    overlays = import ./overlays.nix {inherit inputs;};
    mkPkgs = np: system:
      import np {
        inherit system;
        overlays = [overlays.additions overlays.modifications];
        config.allowUnfree = true;
      };
    pkgsFor = mkPkgs nixpkgs;
    pkgsUnstableFor = mkPkgs nixpkgs-unstable;

    mkHmModules = hm: [
      hm.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = commonArgs;
        };
      }
    ];

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
          ++ (mkHmModules home-manager) ++ modules;
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
            aagl.nixosModules.default
          ]
          ++ (mkHmModules home-manager-unstable) ++ modules;
      };

    mkMicrovm = name: extraModules:
      nixpkgs.lib.nixosSystem {
        specialArgs = commonArgs;
        modules =
          [
            {nixpkgs.pkgs = pkgsFor "x86_64-linux";}
            sops-nix.nixosModules.sops
            microvm.nixosModules.microvm
            impermanence.nixosModules.impermanence
            ./modules/nixos/microvm-guest.nix
            (import ./hosts/sparkle/microvms/vm-identity.nix name)
            ./hosts/sparkle/microvms/vms/${name}/config.nix
          ]
          ++ extraModules;
      };

    # One nixosConfiguration per registry entry; VMs needing extra flake-input modules list them here.
    microvmConfigurations = let
      extraModules = {
        qbittorrent = [vpn-confinement.nixosModules.default];
        unifi = [unifi-os-server.nixosModules.unifi-os-server];
      };
    in
      nixpkgs.lib.mapAttrs (name: _: mkMicrovm name (extraModules.${name} or []))
      (import ./hosts/sparkle/microvms/vm-registry.nix);

    mkDarwinSystem = {
      system,
      modules,
    }:
      nix-darwin.lib.darwinSystem {
        specialArgs = commonArgs;
        modules =
          [
            {nixpkgs.pkgs = pkgsUnstableFor system;}
            home-manager-unstable.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = commonArgs;
              };
            }
          ]
          ++ modules;
      };
  in {
    inherit overlays;

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    # Only expose packages whose meta.platforms includes the target system, so cross-system eval (and nix flake check) doesn't hit "unsupported system".
    packages = forAllSystems (system: nixpkgs.lib.filterAttrs (_: p: nixpkgs.lib.meta.availableOn (nixpkgs.lib.systems.elaborate system) p) (import ./pkgs (pkgsFor system)));

    nixosConfigurations =
      {
        camellya = mkDesktopSystem {
          system = "x86_64-linux";
          modules = [./hosts/camellya ./users/carmilla];
        };

        sparkle = mkServerSystem {
          system = "x86_64-linux";
          modules = [microvm.nixosModules.host ./hosts/sparkle ./users/carmilla];
        };

        sparxie = mkServerSystem {
          system = "aarch64-linux";
          modules = [./hosts/sparxie ./users/carmilla];
        };
      }
      // microvmConfigurations;

    darwinConfigurations = {
      silverwolf = mkDarwinSystem {
        system = "aarch64-darwin";
        modules = [./hosts/silverwolf.nix ./users/carmilla];
      };
    };
  };
}
