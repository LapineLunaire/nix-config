# Impermanence baseline shared by all hosts: machine identity, the SSH host key (which also derives the sops age key), systemd state, and logs. Hosts append their service directories in their own persistence.nix.
{...}: {
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
}
