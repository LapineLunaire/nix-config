{
  config,
  lib,
  ...
}: {
  imports = [../../shared/host.nix];

  # SSH is closed outside these rules, and only the nftables firewall reads extraInputRules.
  assertions = [
    {
      assertion = config.networking.firewall.enable && config.networking.firewall.backend == "nftables" && config.networking.nftables.enable;
      message = "Trusted SSH ingress needs the nftables firewall.";
    }
  ];

  services.openssh.openFirewall = false;
  networking.firewall.extraInputRules = let
    ports = lib.concatMapStringsSep ", " toString (config.services.openssh.ports ++ config.host.trustedTCPPorts);
  in ''
    ip saddr { ${config.host.trustedSubnetsNft} } tcp dport { ${ports} } accept
  '';
}
