{
  config,
  lib,
  ...
}: {
  options.host.wirelessRegulatoryDomain = lib.mkOption {
    type = lib.types.nullOr (lib.types.strMatching "[A-Z][A-Z]");
    default = null;
    description = "Country code for the kernel's wireless regulatory domain.";
  };

  config = lib.mkIf (config.host.wirelessRegulatoryDomain != null) {
    boot.extraModprobeConfig = ''
      options cfg80211 ieee80211_regdom=${config.host.wirelessRegulatoryDomain}
    '';
  };
}
