{...}: {
  services.iperf3 = {
    enable = true;
    openFirewall = false;
  };

  networking.firewall.extraInputRules = ''
    ip saddr { ${(import ../trusted-subnets.nix).nftSet} } tcp dport 5201 accept
  '';
}
