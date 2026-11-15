{
  config,
  lib,
  ...
}: {
  environment.persistence."/persist" = {
    hideMounts = true;
    directories =
      lib.optional config.networking.networkmanager.enable "/etc/NetworkManager/system-connections"
      ++ [
        "/var/lib"
        "/var/log"
        # Keeps root's shell history. Impermanence would create the persistent directory world-readable.
        {
          directory = "/root";
          mode = "0700";
        }
      ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };

  sops.age.sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
}
