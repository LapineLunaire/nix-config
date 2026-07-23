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
      url = "github:microvm-nix/microvm.nix";
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
    microvm,
    vpn-confinement,
    unifi-os-server,
    ...
  } @ inputs: let
    inherit (self) outputs;
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    overlays = import ./overlays.nix {inherit inputs;};

    builders = import ./mk-systems.nix {
      inherit inputs outputs;
      pkgsOverlays = [overlays.additions overlays.modifications];
    };
    inherit (builders) mkServerSystem mkDesktopSystem mkDarwinSystem pkgsFor;

    # A microvm guest: the shared guest base, the VM's identity, and its own config, on top of the generic microvm system.
    mkMicrovm = name: extraModules:
      builders.mkMicrovmSystem {
        modules =
          [
            ./hosts/sparkle/microvms/guest.nix
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
  in {
    inherit overlays;

    # Shared modules addressable as outputs.nixosModules.<name> from any nesting depth; also the module export surface for a future template flake.
    nixosModules = {
      site = ./modules/site.nix;
      nix-settings = ./modules/nix-settings.nix;
      generic = ./modules/nixos/generic;
      packages = ./modules/nixos/packages.nix;
      desktop = ./modules/nixos/desktop;
      security = ./modules/nixos/security.nix;
      trusted-ssh-ingress = ./modules/nixos/trusted-ssh-ingress.nix;
      auto-update = ./modules/nixos/auto-update.nix;
      ip-whitelist = ./modules/nixos/ip-whitelist.nix;
      caddy = ./modules/nixos/caddy.nix;
      zfs-maintenance = ./modules/nixos/zfs-maintenance.nix;
      # A module factory: import it with { pool, startAt } rather than listing it in imports directly.
      borg-backup = ./modules/nixos/borg-backup.nix;
      postgres-passwords = ./modules/nixos/postgres-passwords.nix;
    };

    darwinModules.darwin = ./modules/darwin.nix;

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
