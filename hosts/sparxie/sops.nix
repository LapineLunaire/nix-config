{config, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    secrets = {
      "cloudflare-dns-api-token" = {};
      "tuwunel-registration-token" = {};
      "ejabberd-sql-password" = {};
    };

    templates."cloudflare-dns-api-token.env" = {
      content = ''
        CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare-dns-api-token"}
      '';
      owner = "acme";
    };
  };
}
