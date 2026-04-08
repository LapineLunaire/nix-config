{
  config,
  pkgs,
  ...
}: let
  bunny-web = pkgs.callPackage ../../../pkgs/bunny-web {};

  element-web = pkgs.element-web.override {
    conf.default_server_config."m.homeserver" = {
      base_url = "https://matrix.bunny.enterprises";
      server_name = "bunny.enterprises";
    };
  };
in {
  # 8448: Matrix federation port for server-to-server traffic.
  networking.firewall.allowedTCPPorts = [80 443 8448];

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "certs@lunaire.eu";
      keyType = "ec384";
      dnsProvider = "cloudflare";
      environmentFile = config.sops.templates."cloudflare-dns-api-token.env".path;
      extraLegoFlags = [
        "--dns.resolvers"
        "1.1.1.1:53"
      ];
    };
    # Single SAN cert covering all ejabberd component subdomains:
    # conference (MUC), proxy (SOCKS5 file transfer), pubsub, upload (HTTP upload).
    certs."bunny.enterprises".extraDomainNames = [
      "xmpp.bunny.enterprises"
      "conference.bunny.enterprises"
      "proxy.bunny.enterprises"
      "pubsub.bunny.enterprises"
      "upload.bunny.enterprises"
    ];
    certs."chat.bunny.enterprises" = {};
    certs."matrix.bunny.enterprises" = {};
    certs."pub.bunny.enterprises" = {};
  };

  users.users.caddy.extraGroups = ["acme"];
  users.users.ejabberd.extraGroups = ["acme"];

  services.caddy = {
    enable = true;
    virtualHosts."bunny.enterprises".extraConfig = ''
      tls /var/lib/acme/bunny.enterprises/cert.pem /var/lib/acme/bunny.enterprises/key.pem
      root * ${bunny-web}

      @hostMeta path /.well-known/host-meta
      header @hostMeta Content-Type "application/xrd+xml"
      header @hostMeta Access-Control-Allow-Origin "*"

      @hostMetaJson path /.well-known/host-meta.json
      header @hostMetaJson Content-Type "application/jrd+json"
      header @hostMetaJson Access-Control-Allow-Origin "*"

      @matrix path /.well-known/matrix/*
      header @matrix Content-Type "application/json"
      header @matrix Access-Control-Allow-Origin "*"

      file_server
    '';
    virtualHosts."chat.bunny.enterprises".extraConfig = ''
      tls /var/lib/acme/chat.bunny.enterprises/cert.pem /var/lib/acme/chat.bunny.enterprises/key.pem
      root * ${element-web}
      file_server
    '';
    virtualHosts."matrix.bunny.enterprises".extraConfig = ''
      tls /var/lib/acme/matrix.bunny.enterprises/cert.pem /var/lib/acme/matrix.bunny.enterprises/key.pem
      reverse_proxy [::1]:6167
    '';
    # Federation listener on the default Matrix port.
    virtualHosts."matrix.bunny.enterprises:8448".extraConfig = ''
      tls /var/lib/acme/matrix.bunny.enterprises/cert.pem /var/lib/acme/matrix.bunny.enterprises/key.pem
      reverse_proxy [::1]:6167
    '';
    virtualHosts."pub.bunny.enterprises".extraConfig = ''
      tls /var/lib/acme/pub.bunny.enterprises/cert.pem /var/lib/acme/pub.bunny.enterprises/key.pem
      import ${config.sops.templates."caddy-pub-bnnuy-basicauth".path}
      reverse_proxy 10.73.212.2:9000 {
        header_up Host {upstream_hostport}
      }
    '';
  };
}
