{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AuthenticationMethods = "publickey";
    };
    # Take login keys only from the configuration. Anything running as a user can add keys to their home, which persists.
    authorizedKeysInHomedir = false;
    # Also used as the SOPS decryption identity.
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
}
