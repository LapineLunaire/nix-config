{
  config,
  pkgs,
  ...
}: {
  services.ejabberd = {
    enable = true;
    package = pkgs.ejabberd.override {
      withRedis = true;
      withPgsql = true;
    };
    configFile = config.sops.templates."ejabberd.yml".path;
  };

  sops.templates."ejabberd.yml" = {
    owner = "ejabberd";
    content = ''
      new_sql_schema: true
      default_db: sql
      default_ram_db: redis

      sql_type: pgsql
      sql_server: 127.0.0.1
      sql_port: 5432
      sql_database: ejabberd
      sql_username: ejabberd
      sql_password: ${config.sops.placeholder."ejabberd-sql-password"}

      redis_server: 127.0.0.1
      redis_db: 1

      disable_sasl_mechanisms: ["DIGEST-MD5", "PLAIN"]

      c2s_ciphers: ["TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384:TLS_AES_128_GCM_SHA256"]
      c2s_tls_compression: false
      c2s_protocol_options:
        - no_sslv2
        - no_sslv3
        - no_tlsv1
        - no_tlsv1_1
        - no_tlsv1_2
        - cipher_server_preference
        - no_compression

      s2s_use_starttls: required
      s2s_ciphers: ["TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384:TLS_AES_128_GCM_SHA256"]
      s2s_tls_compression: false
      s2s_protocol_options:
        - no_sslv2
        - no_sslv3
        - no_tlsv1
        - no_tlsv1_1
        - no_tlsv1_2
        - cipher_server_preference
        - no_compression

      hosts:
        - bunny.enterprises

      loglevel: info

      certfiles:
        - /var/lib/acme/bunny.enterprises/cert.pem
        - /var/lib/acme/bunny.enterprises/key.pem

      listen:
        -
          port: 5222
          ip: "::"
          module: ejabberd_c2s
          max_stanza_size: 262144
          shaper: c2s_shaper
          access: c2s
          starttls_required: true
        -
          port: 5223
          ip: "::"
          module: ejabberd_c2s
          max_stanza_size: 262144
          shaper: c2s_shaper
          access: c2s
          tls: true
        -
          port: 5269
          ip: "::"
          module: ejabberd_s2s_in
          max_stanza_size: 524288
          shaper: s2s_shaper
        -
          port: 5443
          ip: "::"
          module: ejabberd_http
          tls: true
          request_handlers:
            /admin: ejabberd_web_admin
            /api: mod_http_api
            /bosh: mod_bosh
            /captcha: ejabberd_captcha
            /upload: mod_http_upload
            /ws: ejabberd_http_ws
        -
          port: 3478
          ip: "::"
          transport: udp
          module: ejabberd_stun
          use_turn: true
          turn_ipv4_address: "46.225.108.230"
          turn_ipv6_address: "2a01:4f8:1c19:a249::1"

      acl:
        admin:
          user:
            - "lapine@bunny.enterprises"
        local:
          user_regexp: ""
        loopback:
          ip:
            - 127.0.0.0/8
            - ::1/128

      access_rules:
        local:
          allow: local
        c2s:
          deny: blocked
          allow: all
        announce:
          allow: admin
        configure:
          allow: admin
        muc_create:
          allow: local
        pubsub_createnode:
          allow: local
        trusted_network:
          allow: loopback

      api_permissions:
        "console commands":
          from: ejabberd_ctl
          who: all
          what: "*"
        "webadmin commands":
          from: ejabberd_web_admin
          who: admin
          what: "*"
        "adhoc commands":
          from: mod_adhoc_api
          who: admin
          what: "*"
        "http access":
          from: mod_http_api
          who:
            access:
              allow:
                - acl: loopback
                - acl: admin
            oauth:
              scope: "ejabberd:admin"
              access:
                allow:
                  - acl: loopback
                  - acl: admin
          what:
            - "*"
            - "!stop"
            - "!start"
        "public commands":
          who:
            ip: 127.0.0.1/8
          what:
            - status
            - connected_users_number

      shaper:
        normal:
          rate: 3000
          burst_size: 20000
        fast: 100000

      shaper_rules:
        max_user_sessions: 10
        max_user_offline_messages:
          5000: admin
          100: all
        c2s_shaper:
          none: admin
          normal: all
        s2s_shaper: fast

      modules:
        mod_admin_update_sql: {}
        mod_adhoc: {}
        mod_adhoc_api: {}
        mod_admin_extra: {}
        mod_announce:
          access: announce
        mod_avatar: {}
        mod_blocking: {}
        mod_bosh: {}
        mod_caps: {}
        mod_carboncopy: {}
        mod_client_state: {}
        mod_configure: {}
        mod_disco:
          server_info:
            -
              modules: all
              name: "abuse-addresses"
              urls: ["mailto:postmaster@lunaire.eu"]
        mod_fail2ban: {}
        mod_http_api: {}
        mod_http_upload:
          put_url: https://xmpp.bunny.enterprises:5443/upload
          docroot: /var/lib/ejabberd/upload
          custom_headers:
            "Access-Control-Allow-Origin": "https://xmpp.bunny.enterprises"
            "Access-Control-Allow-Methods": "GET,HEAD,PUT,OPTIONS"
            "Access-Control-Allow-Headers": "Content-Type"
        mod_last: {}
        mod_mam:
          assume_mam_usage: true
          default: always
        mod_muc:
          access:
            - allow
          access_admin:
            - allow: admin
          access_create: muc_create
          access_persistent: muc_create
          access_mam:
            - allow
          default_room_options:
            mam: true
        mod_muc_admin: {}
        mod_muc_occupantid: {}
        mod_offline:
          access_max_user_messages: max_user_offline_messages
        mod_ping: {}
        mod_privacy: {}
        mod_private: {}
        mod_proxy65:
          access: local
          max_connections: 5
        mod_pubsub:
          access_createnode: pubsub_createnode
          plugins:
            - flat
            - pep
          force_node_config:
            storage:bookmarks:
              access_model: whitelist
        mod_push: {}
        mod_push_keepalive: {}
        mod_register:
          ip_access: trusted_network
        mod_roster:
          versioning: true
        mod_s2s_bidi: {}
        mod_s2s_dialback: {}
        mod_shared_roster: {}
        mod_stream_mgmt:
          resume_timeout: 24h
          resend_on_timeout: if_offline
        mod_stun_disco: {}
        mod_vcard: {}
        mod_vcard_xupdate: {}
        mod_version:
          show_os: false
    '';
  };

  systemd.services.ejabberd = {
    after = ["postgresql.service" "redis.service"];
    requires = ["postgresql.service" "redis.service"];
  };

  networking.firewall = {
    allowedTCPPorts = [5222 5223 5269 5443];
    allowedUDPPorts = [3478];
  };
}
