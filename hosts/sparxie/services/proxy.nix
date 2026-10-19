{
  config,
  lib,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [8448];
  networking.firewall.allowedUDPPorts = [8448];

  sops.templates."caddy-pub-bnnuy-basicauth" = {
    owner = "caddy";
    reloadUnits = ["caddy.service"];
    content = ''
      basic_auth {
        bnnuy ${config.sops.placeholder."pub-bnnuy-password-hash"}
      }
    '';
  };

  services.caddy.virtualHosts = let
    inherit (config.caddy) securityHeaders tlsDns;
    wg = config.host.wireguardTunnel;
    sparkleTunnelWeb = import ../../sparkle/tunnel-web.nix;
    bunny-web = pkgs.callPackage ../../../pkgs/bunny-web {};
    mkVhost = body: {
      extraConfig =
        ''
          ${tlsDns}
          ${securityHeaders}
        ''
        + body;
    };
    tuwunelPort = lib.head config.services.matrix-tuwunel.settings.global.port;
    matrixVhost = mkVhost ''
      reverse_proxy [::1]:${toString tuwunelPort}
    '';
  in {
    "bunny.enterprises" = mkVhost ''
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
    "chat.bunny.enterprises" = let
      element-web = pkgs.element-web.override {
        conf.default_server_config."m.homeserver" = {
          base_url = "https://matrix.bunny.enterprises";
          server_name = "bunny.enterprises";
        };
      };
    in
      mkVhost ''
        root * ${element-web}
        file_server
      '';
    "matrix.bunny.enterprises" = matrixVhost;
    "matrix.bunny.enterprises:8448" = matrixVhost;
    "pub.bunny.enterprises" = mkVhost ''
      import ${config.sops.templates."caddy-pub-bnnuy-basicauth".path}
      reverse_proxy ${wg.peer.ip}:${toString sparkleTunnelWeb.port} {
        header_up Host {upstream_hostport}
      }
    '';
  };
}
