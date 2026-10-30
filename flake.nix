{
  description = "Carmilla's Nix configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim-stable = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager/trunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
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
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.rust-overlay.url = "github:oxalica/rust-overlay/master";
      inputs.rust-overlay.inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.pre-commit.inputs.flake-compat.follows = "flake-compat";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    unifi-os-server = {
      url = "github:rcambrj/unifi-os-server";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
    nixpkgs-stable,
    home-manager,
    home-manager-stable,
    nix-darwin,
    nixvim,
    nixvim-stable,
    plasma-manager,
    impermanence,
    lanzaboote,
    sops-nix,
    microvm,
    unifi-os-server,
    aagl,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
    desktopModules = [
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
      ./profiles/desktop
    ];
    guestRegistry = import ./hosts/sparkle/guest-registry.nix;
    dmz = import ./hosts/sparkle/dmz-net.nix;
    net = import ./hosts/sparkle/guest-net.nix;
    web = import ./hosts/sparkle/guest-web.nix;
    guestModules = {
      unifi = [unifi-os-server.nixosModules.unifi-os-server];
    };
    guestConfigurations = nixpkgs-stable.lib.mapAttrs (name: _:
      nixpkgs-stable.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit dmz net web guestRegistry;
          trustedSubnets = import ./hosts/sparkle/trusted-subnets.nix;
          tunnelWeb = import ./hosts/sparkle/tunnel-web.nix;
          zoneSerial = self.lastModified;
          consoleKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJ+Zb08V2BIx3TnFgha04A55Vo9d0ftNpNvnRgfO3Gk";
        };
        modules =
          [
            impermanence.nixosModules.impermanence
            microvm.nixosModules.microvm
            sops-nix.nixosModules.sops
          ]
          ++ (guestModules.${name} or [])
          ++ [
            ./modules/nixos/microvm/guest.nix
            ./modules/nixos/microvm/identity.nix
            {
              networking.hostName = name;
              nixpkgs.config.allowUnfree = true;
            }
            (./hosts/sparkle/guests + "/${name}")
          ];
      })
    guestRegistry;
  in {
    overlays = import ./overlays;

    nixosModules = {
      desktop = ./profiles/desktop;
      server = ./profiles/server;
      boot = ./modules/nixos/system/boot.nix;
      tuned-kernel = ./modules/nixos/system/tuned-kernel.nix;
      firewall = ./modules/nixos/networking/firewall.nix;
      gaming = ./modules/nixos/programs/gaming.nix;
      secure-boot = {
        imports = [
          lanzaboote.nixosModules.lanzaboote
          ./modules/nixos/system/secure-boot.nix
        ];
      };
      ssh-ip-whitelist = {
        imports = [
          sops-nix.nixosModules.sops
          ./modules/nixos/networking/ssh-ip-whitelist.nix
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
      zfs = ./modules/nixos/services/zfs.nix;
    };

    darwinModules.base = ./profiles/darwin.nix;

    darwinConfigurations.silverwolf = nix-darwin.lib.darwinSystem {
      modules = [
        home-manager.darwinModules.home-manager
        {home-manager.sharedModules = [nixvim.homeModules.nixvim];}
        ./profiles/darwin.nix
        ./hosts/silverwolf
        ./users/carmilla/darwin.nix
      ];
    };

    nixosConfigurations =
      guestConfigurations
      // {
        camellya = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules =
            desktopModules
            ++ [
              aagl.nixosModules.default
              ./hosts/camellya
              ./users/carmilla/hosts/camellya.nix
            ];
        };

        kafka = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules =
            desktopModules
            ++ [
              ./hosts/kafka
              ./users/carmilla/hosts/kafka.nix
            ];
        };

        sparkle = nixpkgs-stable.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit dmz guestRegistry guestConfigurations;};
          modules = [
            microvm.nixosModules.host
            impermanence.nixosModules.impermanence
            lanzaboote.nixosModules.lanzaboote
            sops-nix.nixosModules.sops
            home-manager-stable.nixosModules.home-manager
            {home-manager.sharedModules = [nixvim-stable.homeModules.nixvim];}
            ./profiles/server
            ./hosts/sparkle
            ./users/carmilla/server.nix
          ];
        };

        sparxie = nixpkgs-stable.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            impermanence.nixosModules.impermanence
            sops-nix.nixosModules.sops
            home-manager-stable.nixosModules.home-manager
            {home-manager.sharedModules = [nixvim-stable.homeModules.nixvim];}
            ./profiles/server
            ./hosts/sparxie
            ./users/carmilla/server.nix
          ];
        };
      };

    checks = {
      x86_64-linux =
        (nixpkgs-stable.lib.mapAttrs (_: guest: guest.config.system.build.toplevel) guestConfigurations)
        // {
          camellya = self.nixosConfigurations.camellya.config.system.build.toplevel;
          kafka = self.nixosConfigurations.kafka.config.system.build.toplevel;
          sparkle = self.nixosConfigurations.sparkle.config.system.build.toplevel;
        };
      aarch64-linux.sparxie = self.nixosConfigurations.sparxie.config.system.build.toplevel;
      aarch64-darwin.silverwolf = self.darwinConfigurations.silverwolf.config.system.build.toplevel;
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
