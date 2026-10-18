{
  description = "Carmilla's Nix configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager/trunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    impermanence = {
      url = "github:nix-community/impermanence/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat.url = "github:NixOS/flake-compat/master";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
      inputs.pre-commit.inputs.flake-compat.follows = "flake-compat";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
      inputs.flake-compat.follows = "flake-compat";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixvim,
    plasma-manager,
    impermanence,
    lanzaboote,
    sops-nix,
    aagl,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
  in {
    overlays = import ./overlays.nix;

    nixosModules = {
      desktop = ./profiles/desktop.nix;
      boot = ./modules/nixos/system/boot.nix;
      firewall = ./modules/nixos/networking/firewall.nix;
      gaming = ./modules/nixos/programs/gaming.nix;
      secure-boot = {
        imports = [
          lanzaboote.nixosModules.lanzaboote
          ./modules/nixos/system/secure-boot.nix
        ];
      };
      steam-frame = ./modules/nixos/networking/steam-frame.nix;
      desktop-cache = {
        imports = [
          sops-nix.nixosModules.sops
          ./modules/nixos/nix/desktop-cache.nix
        ];
      };
      trusted-ssh-ingress = ./modules/nixos/networking/trusted-ssh-ingress.nix;
      wireless-regulatory-domain = ./modules/nixos/networking/wireless-regulatory-domain.nix;
    };

    nixosConfigurations = {
      camellya = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.sharedModules = [
              nixvim.homeModules.nixvim
              plasma-manager.homeModules.plasma-manager
            ];
          }
          aagl.nixosModules.default
          ./profiles/desktop.nix
          ./hosts/camellya
          ./users/carmilla/hosts/camellya.nix
        ];
      };

      kafka = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.sharedModules = [
              nixvim.homeModules.nixvim
              plasma-manager.homeModules.plasma-manager
            ];
          }
          ./profiles/desktop.nix
          ./hosts/kafka
          ./users/carmilla/hosts/kafka.nix
        ];
      };
    };

    checks = {
      x86_64-linux = {
        camellya = self.nixosConfigurations.camellya.config.system.build.toplevel;
        kafka = self.nixosConfigurations.kafka.config.system.build.toplevel;
      };
    };

    formatter = forEachSystem (system: nixpkgs.legacyPackages.${system}.alejandra);

    devShells = forEachSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          uutils-coreutils-noprefix
          uutils-findutils
          uutils-diffutils
          alejandra
          nixd
          sops
          ssh-to-age
        ];

        shellHook = ''
          git config core.hooksPath .githooks
        '';
      };
    });
  };
}
