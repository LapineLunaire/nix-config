{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."smtp-password".sopsFile = ../../smtp.yaml;
    # Also keep this passphrase available for recovery outside the guest.
    secrets."vault-zfs-key" = {};
  };
}
