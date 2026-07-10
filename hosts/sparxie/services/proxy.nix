{
  config,
  pkgs,
  ...
}: let
  element-web = pkgs.element-web.override {
    conf.default_server_config."m.homeserver" = {
      base_url = "https://matrix.bunny.enterprises";
      server_name = "bunny.enterprises";
    };
  };

  securityHeaders = import ../../../modules/nixos/caddy-security-headers.nix;
  wg = import ../../../modules/nixos/sparkle-sparxie-wireguard.nix;
in {
  # 8448: Matrix federation port for server-to-server traffic.
  networking.firewall.allowedTCPPorts = [8448];

  security.acme = {
    certs."bunny.enterprises" = {
      # Single SAN cert covering all ejabberd component subdomains: conference (MUC), proxy (SOCKS5 file transfer), pubsub, upload (HTTP upload).
      extraDomainNames = [
        "xmpp.bunny.enterprises"
        "conference.bunny.enterprises"
        "proxy.bunny.enterprises"
        "pubsub.bunny.enterprises"
        "upload.bunny.enterprises"
      ];
      # Dedicated group for this cert's files: ejabberd reads only this cert through it, without acme membership exposing the other certs' keys.
      group = "bunny-cert";
      # ejabberd loads these cert files at startup and only re-reads them on restart, so reload it (alongside caddy) when this cert renews.
      reloadServices = config.security.acme.defaults.reloadServices ++ ["ejabberd.service"];
    };
    certs."chat.bunny.enterprises" = {};
    certs."matrix.bunny.enterprises" = {};
    certs."pub.bunny.enterprises" = {};
  };

  users.groups.bunny-cert = {};
  users.users.ejabberd.extraGroups = ["bunny-cert"];
  # caddy stays in acme (see modules/nixos/caddy.nix) for the remaining certs; the bunny.enterprises vhost below reads this cert too.
  users.users.caddy.extraGroups = ["bunny-cert"];

  services.caddy = {
    virtualHosts."bunny.enterprises".extraConfig = ''
      tls /var/lib/acme/bunny.enterprises/cert.pem /var/lib/acme/bunny.enterprises/key.pem
      ${securityHeaders}
      root * ${pkgs.bunny-web}

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
      ${securityHeaders}
      root * ${element-web}
      file_server
    '';
    virtualHosts."matrix.bunny.enterprises".extraConfig = ''
      tls /var/lib/acme/matrix.bunny.enterprises/cert.pem /var/lib/acme/matrix.bunny.enterprises/key.pem
      ${securityHeaders}
      reverse_proxy [::1]:6167
    '';
    # Federation listener on the default Matrix port.
    virtualHosts."matrix.bunny.enterprises:8448".extraConfig = ''
      tls /var/lib/acme/matrix.bunny.enterprises/cert.pem /var/lib/acme/matrix.bunny.enterprises/key.pem
      ${securityHeaders}
      reverse_proxy [::1]:6167
    '';
    virtualHosts."pub.bunny.enterprises".extraConfig = ''
      tls /var/lib/acme/pub.bunny.enterprises/cert.pem /var/lib/acme/pub.bunny.enterprises/key.pem
      ${securityHeaders}
      import ${config.sops.templates."caddy-pub-bnnuy-basicauth".path}
      reverse_proxy ${wg.sparkle.ip}:9000 {
        header_up Host {upstream_hostport}
      }
    '';
  };
}
