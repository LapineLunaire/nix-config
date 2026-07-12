{...}: {
  services.iperf3 = {
    enable = true;
    openFirewall = false;
  };

  networking.firewall.extraInputRules = ''
    ip saddr { ${(import ../../../modules/nixos/trusted-subnets.nix).nftSet} } tcp dport 5201 accept
  '';
}
