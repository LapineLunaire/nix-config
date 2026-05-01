{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.ghostty.terminfo];
  # /var/lib and /var/log bind-mounted from /persist (virtiofs share at /persist).
  fileSystems."/persist".neededForBoot = true;
  environment.persistence."/persist" = {
    directories = [
      "/var/lib"
      "/var/log"
    ];
    files = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };

  microvm = {
    hypervisor = "cloud-hypervisor";
    vcpu = lib.mkDefault 4;
    mem = lib.mkDefault 2048;
    # Shared host nix store (read-only). Do NOT set fileSystems."/nix/store" manually — microvm.nix manages the overlay when writableStoreOverlay is set.
    shares = [
      {
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        proto = "virtiofs";
      }
    ];
    writableStoreOverlay = "/nix/.rw-store";
    # balloon is bool; initialBalloonMem (MB) sets starting size per VM.
    balloon = lib.mkDefault true;
    deflateOnOOM = true;
  };

  # sops-nix derives age key from the persisted SSH host key.
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  # node_exporter on every VM, scraped by monitoring (10.28.34.19) only.
  services.prometheus.exporters.node.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEes6fnuE4zIKuneekCyPzMYItOOgfnDo0Eiakvwf62mAAAACnNzaDpsYXBpbmU="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMqXDPM9z04YBOp2fVDox7sgPFNpad+9p8UA+od8V8nxAAAACnNzaDpsYXBpbmU="
  ];
  networking.firewall.extraInputRules = lib.mkBefore ''
    ip saddr 10.28.34.19 tcp dport 9100 accept
    ip saddr { 10.28.64.0/24, 10.28.96.0/24, 10.100.0.0/24, 10.1.0.0/24 } tcp dport 22 accept
  '';
  networking.nftables.enable = true;
  networking.firewall.enable = true;
  networking.useDHCP = false;
  # Force eth0 naming — all VM configs reference eth0.
  networking.usePredictableInterfaceNames = false;
  networking.nameservers = ["10.28.34.1"];
  networking.defaultGateway = {
    address = "10.28.34.1";
    interface = "eth0";
  };

  time.timeZone = "UTC";
  system.stateVersion = "26.05";
}
