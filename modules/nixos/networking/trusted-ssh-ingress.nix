{
  config,
  lib,
  ...
}: {
  imports = [../../shared/host.nix];

  services.openssh.openFirewall = false;
  networking.firewall.extraInputRules = let
    ports = lib.concatMapStringsSep ", " toString (config.services.openssh.ports ++ config.host.trustedTCPPorts);
  in ''
    ip saddr { ${config.host.trustedSubnetsNft} } tcp dport { ${ports} } accept
  '';
}
