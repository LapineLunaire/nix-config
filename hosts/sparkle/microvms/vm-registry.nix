# Central VM registry. index becomes the vsock CID, the last MAC octet (behind the random prefix in vm-identity.nix), and the last IP octet (10.28.34.<index>); deps order microvm@<name> after other VMs.
{
  postgres = {index = 10;};
  authelia = {
    index = 11;
    deps = ["postgres"];
  };
  forgejo = {
    index = 12;
    deps = ["postgres"];
  };
  ci-runner = {index = 13;};
  homeassistant = {index = 14;};
  qbittorrent = {index = 15;};
  vaultwarden = {
    index = 16;
    deps = ["postgres"];
  };
  kavita = {index = 17;};
  uptime-kuma = {index = 18;};
  monitoring = {index = 19;};
  pgadmin = {index = 20;};
  unifi = {index = 21;};
}
