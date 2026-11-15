{
  config,
  lib,
  ...
}: {
  options.host.tmpfs = {
    rootSize = lib.mkOption {
      type = lib.types.str;
      description = "Size of the tmpfs root, as a tmpfs size= value such as 2G or 50%.";
    };

    tmpSize = lib.mkOption {
      type = lib.types.str;
      description = "Size of each of the /tmp and /var/tmp tmpfs mounts, as a tmpfs size= value.";
    };
  };

  config.fileSystems = let
    temporary = {
      device = "none";
      fsType = "tmpfs";
      options = ["defaults" "size=${config.host.tmpfs.tmpSize}" "mode=1777" "nosuid" "nodev" "noexec"];
    };
  in {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["defaults" "size=${config.host.tmpfs.rootSize}" "mode=755" "nosuid" "nodev"];
    };
    "/tmp" = temporary;
    "/var/tmp" = temporary;
  };
}
