{lib, ...}: {
  services.iperf3 = {
    enable = true;
    openFirewall = false;
  };

  networking.firewall.extraInputRules = ''
    ip saddr { ${lib.concatStringsSep ", " (import ../trusted-subnets.nix)} } tcp dport 5201 accept
  '';
}
