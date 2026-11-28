{
  description = "Carmilla's Nix configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.11";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
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
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
      inputs.pre-commit.inputs.flake-compat.follows = "flake-compat";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:microvm-nix/microvm.nix";
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
    nix-darwin,
    nixvim,
    plasma-manager,
    impermanence,
    lanzaboote,
    sops-nix,
    microvm,
    aagl,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
    sharedData = {
      trustedSubnets = import ./hosts/trusted-subnets.nix;
      dmz = import ./hosts/sparkle/dmz-net.nix;
      net = import ./hosts/sparkle/guest-net.nix;
      web = import ./hosts/sparkle/guest-web.nix;
      guestRegistry = import ./hosts/sparkle/guest-registry.nix;
      tunnelWeb = import ./hosts/sparkle/tunnel-web.nix;
      consoleKey = import ./hosts/sparkle/console-key.nix;
      sparxieWan = import ./hosts/sparxie/wan-net.nix;
    };
    # Every NixOS host and guest here gets the shared data and trusts the same client subnets.
    mkSystem = modules:
      nixpkgs.lib.nixosSystem {
        specialArgs = sharedData;
        modules =
          [
            impermanence.nixosModules.impermanence
            sops-nix.nixosModules.sops
            {host.trustedSubnets = sharedData.trustedSubnets.all;}
          ]
          ++ modules;
      };
    # Desktops and servers use Home Manager with nixvim and keep their checkout in /persist/nix-config.
    mkHost = modules:
      mkSystem (
        [
          home-manager.nixosModules.home-manager
          {home-manager.sharedModules = [nixvim.homeModules.nixvim];}
          {host.flakePath = "/persist/nix-config";}
        ]
        ++ modules
      );
    mkDesktop = modules:
      mkHost (
        [
          lanzaboote.nixosModules.lanzaboote
          {home-manager.sharedModules = [plasma-manager.homeModules.plasma-manager];}
          ./profiles/desktop
        ]
        ++ modules
        ++ [
          ./users/carmilla/desktop.nix
          ./users/t3
        ]
      );
    mkServer = modules:
      mkHost (
        [./profiles/server]
        ++ modules
        ++ [./users/carmilla/server.nix]
      );
    guestConfigurations = nixpkgs.lib.mapAttrs (name: _:
      mkSystem [
        microvm.nixosModules.microvm
        ./modules/nixos/microvm/guest.nix
        ./modules/nixos/microvm/identity.nix
        {networking.hostName = name;}
        (./hosts/sparkle/guests + "/${name}")
      ])
    sharedData.guestRegistry;
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
      attic-client = {
        imports = [
          sops-nix.nixosModules.sops
          ./modules/nixos/nix/attic-client.nix
        ];
        # This flake's systems get web as a special argument; other users get it here.
        _module.args = {inherit (sharedData) web;};
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
        camellya = mkDesktop [aagl.nixosModules.default ./hosts/camellya];
        kafka = mkDesktop [./hosts/kafka];
        sparkle = mkServer [
          microvm.nixosModules.host
          lanzaboote.nixosModules.lanzaboote
          {_module.args = {inherit guestConfigurations;};}
          ./hosts/sparkle
        ];
        sparxie = mkServer [./hosts/sparxie];
      };

    # nix flake check evaluates each system under its own platform, including Silverwolf.
    checks = nixpkgs.lib.foldlAttrs (checks: name: system:
      nixpkgs.lib.recursiveUpdate checks {
        ${system.config.nixpkgs.hostPlatform.system}.${name} = system.config.system.build.toplevel;
      }) {} (self.nixosConfigurations // self.darwinConfigurations);

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
