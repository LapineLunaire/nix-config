{config, ...}: {
  services.iperf3 = {
    enable = true;
    openFirewall = false;
  };

  networking.firewall.extraInputRules = ''
    ip saddr { ${config.site.trustedSubnetsNft} } tcp dport 5201 accept
  '';
}
