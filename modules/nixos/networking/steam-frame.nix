{
  config,
  lib,
  ...
}: let
  cfg = config.hardware.steamFrame;
  lanRules =
    lib.concatMapStringsSep "\n" (subnet: ''
      ip saddr ${subnet} tcp dport { 27036, 27037 } accept
      ip saddr ${subnet} udp dport { 10400, 10401, 27031-27036 } accept
    '')
    cfg.lanSubnets;
in {
  options.hardware.steamFrame = {
    lanSubnets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "LAN subnets allowed to discover and stream to Steam Frame.";
    };
  };

  config = {
    systemd.network.links."10-steam-frame" = {
      matchConfig.Property = ["ID_VENDOR_ID=28de" "ID_MODEL_ID=2432"];
      linkConfig.Name = "wlframe";
    };

    # Steam's remotePlay.openFirewall opens these ports on every interface.
    networking.firewall.extraInputRules = ''
      ${lanRules}
      iifname "wlframe" tcp dport { 27036, 27037 } accept
      iifname "wlframe" udp dport { 10400, 10401, 27031-27036 } accept
    '';
  };
}
