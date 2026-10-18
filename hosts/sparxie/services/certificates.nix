{
  imports = [../../../modules/nixos/services/acme.nix];

  security.acme.certs."bunny.enterprises" = {
    extraDomainNames = [
      "xmpp.bunny.enterprises"
      "conference.bunny.enterprises"
      "proxy.bunny.enterprises"
      "pubsub.bunny.enterprises"
      "upload.bunny.enterprises"
    ];
    group = "bunny-cert";
  };

  users.groups.bunny-cert = {};
}
