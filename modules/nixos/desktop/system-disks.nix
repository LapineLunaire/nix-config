{
  config,
  lib,
  ...
}: let
  devices = lib.catAttrs "device" (
    lib.attrValues config.fileSystems ++ lib.attrValues config.boot.initrd.luks.devices
  );
in {
  # UDisks exposes backing volumes separately from Impermanence's hidden mounts.
  services.udev.extraRules = lib.concatMapStrings (device:
    lib.optionalString (lib.hasPrefix "/dev/" device) ''
      SUBSYSTEM=="block", SYMLINK=="${lib.removePrefix "/dev/" device}", ENV{UDISKS_IGNORE}="1"
    '') (lib.unique devices);
}
