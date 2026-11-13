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
      ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };

  sops.age.sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
}
